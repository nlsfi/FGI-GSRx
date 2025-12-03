import sys
import copy
import hashlib
from enum import Enum
from bitstring import BitArray
from dataclasses import dataclass
from collections import defaultdict

from util.gst import GalileoSystemTime
from osnma.navdata import InavSubframe, NavDataManager
from osnma.decoder import OsnmaDecoder
from osnma.authentication import OsnmaAuthenticationException, OsnmaException, OsnmaAuthenticator, AuthenticationUnit
from osnma.dsm import NmaHeader, DsmMessageType, DsmKrootMessage
from osnma.mack import Mack, TeslaKey

from datasink.events import EventHandler, EventType, Events, Event, SatelliteEvent, AuthEvent

@dataclass
class OsnmaProtocolConfig:
    """ See ICD for more information.

    PKID: ID of the Galileo public key in place
    CIDKR: Chain ID to which the KROOT belongs to
    HF: Hash function
    MF: MAC function
    KS: Key size
    TS: Tag size
    MACLT: MAC lookup table value (specifies the TAG order, see the documentation)
    WNK: Week Number associated with the KROOT
    TOWHK: Time of Week number associated with the KROOT
    """
    PKID: int = None
    CIDKR: int = None
    HF: str = None
    MF: str = None
    KS: int = None
    TS: int = None
    MACLT: int = None
    WNK: int  = None
    TOWHK: int = None

class ReceiverState(Enum):
    """OSNMA related receiver state.

    INITIALIZING: in the process of collecting and validating the KROOT message
    READY_TO_AUTHENTICATE: initialization is done and we can start
    authenticating navigation messages
    """
    INITIALIZING = 0
    READY_TO_AUTHENTICATE = 1

@dataclass
class TagWithMetadata:
    """Tag with some metadata related to it
    """
    tag: BitArray
    tag_index: int
    gst: GalileoSystemTime
    PRND: int
    PRNA: int
    ADKD: int

class OsnmaEngine(EventHandler):
    """The main class for the OSNMA processing. Most notably it contains the
    process_subframe method, which uses the functionality of other classes to
    perform all of the required operations for the received subframe.
    """

    def __init__(self, public_key_pem, save_kroot=False):
        super().__init__()
        # Accumulated tags: dictionary with (gst, svid, adkd) -> list of tags
        self.collected_tags = defaultdict(list)
        # List of AuthenticationUnits waiting for the key
        self.pending_subframes = []
        self.pending_authentications = []

        # Save the received KROOT so it can be used to hot start the next runs
        self.save_kroot = save_kroot

        # Last received NMA header, verified NMA header, and Chain ID currently
        # in place, and whether End Of Chain event is coming
        self.current_nma_header = None
        self.verified_nma_header = None
        self.current_cid = None
        self.eoc_coming = False

        # Stashed KROOT/PKR for chain/pubk change events
        self._stashed_kroot = None
        self._stashed_pkr = None

        self.config = OsnmaProtocolConfig()
        self.state = ReceiverState.INITIALIZING
        self.navdata_manager = NavDataManager()
        self.authenticator = OsnmaAuthenticator(public_key_pem)
        self.decoder = OsnmaDecoder()

    def process_subframe(self, subframe: InavSubframe):
        """The core function of the OsnmaEngine. Does all of the steps needed
        to process the incoming subframe: decode the OSNMA information, update
        receiver state and authenticate messages from previous subframes. The
        important events will be handled and reported by the superclass
        EventHandler.

        :subframe: a InavSubframe object
        :return: nothing, but calls the EventHandler callbacks
        """
        try:
            self.handle_event(SatelliteEvent(subframe.wn, subframe.tow, Events.SUBFRAME_RECEIVED, subframe.svid))

            # Raise exception if OSNMA field is all zeros
            hkroot_bits, mack_bits = self.decoder.extract_and_concatenate_OSNMA_bits(subframe)

            self.pending_subframes.append(subframe)
            self.navdata_manager.extract_and_insert_authdata(subframe)
            self.handle_hkroot(hkroot_bits, subframe.get_gst())

            if self.state == ReceiverState.READY_TO_AUTHENTICATE:
                key = self.decoder.parse_mack_message(mack_bits, subframe.get_gst()).tesla_key

                # Try to verify the key. If the key verification can be
                # attempted, but the verification fails, report the event.
                key_ok = self.authenticator.verify_and_input_tesla_key(key)

                if key_ok:
                    self.handle_event(Event(subframe.wn, subframe.tow, Events.TESLA_KEY_VERIFIED))
                can_verify = key.time != self.authenticator.tesla_newest_key.time
                if can_verify and not key_ok:
                    self.handle_event(SatelliteEvent(subframe.wn, subframe.tow, Events.TESLA_KEY_VERIFICATION_FAILED, subframe.svid))

                self.extract_tags_from_pending()

                # Use the new key to authenticate everything that is possible now
                results, successful_auths = self.authenticate_pending()

                if len(results) > 0:
                    self.handle_events(results)

                    # When the NMA header has been part of successful
                    # authentications, it has been verified as a by product
                    if successful_auths > 0:
                        self.verified_nma_header = self.current_nma_header
                        self._handle_nma_header(self.verified_nma_header)

        # When no OSNMA bits
        except OsnmaException as e:
            # Even if we don't have OSNMA bits, add the auth data to support
            # cross authentication. Note: no need to add ADKD=4 auth data
            self.navdata_manager.extract_and_insert_authdata(subframe, False, True)

            self.handle_event(SatelliteEvent(subframe.wn, subframe.tow, Events.NO_OSNMA_BITS, subframe.svid))

    def authenticate_pending(self):
        """Go through the accumulated pending units, and checks what can be
        authenticated, and produce an authentication report if any
        authentications were attempted.
        """
        # Information needed for the authentication. If this is not available,
        # exit the authentication early.
        tesla_key = self.authenticator.tesla_newest_key
        alpha = self.authenticator.alpha
        nma_header = self.current_nma_header

        result = []
        successful_auths = 0

        if tesla_key == None:
            return result, successful_auths
        if alpha == None:
            return result, successful_auths
        if nma_header == None:
            return result, successful_auths

        # Iterate over units pending authenthication
        attempted_authentications = []
        for i, authunit in enumerate(self.pending_authentications):

            # Iterate to the correct key, and continue if this is not possible
            past_key = self.authenticator.iterate_to_correct_key(tesla_key, authunit.tag_gst, alpha, authunit.adkd)
            if past_key == None:
                continue

            # Navigation data was not received
            if authunit.navdata == None:
                attempt = AuthEvent(authunit.tag_gst.wn, authunit.tag_gst.tow, Events.NAVDATA_MISSING, authunit.prnd, authunit.prna, authunit.adkd)
            else:
                attempt = self.authenticator.verify_tag(authunit, past_key, nma_header)
            result.append(attempt)

            if attempt.is_successful():
                successful_auths += 1
            elif authunit.navdata != None:
                # Print the key information from tag failures, but not when the
                # failure is about unreceived navigation data
                print("Failed to authenticate tag:", authunit, file=sys.stderr)
            attempted_authentications.append(i)

        # Remove the attempted authentications. Reverse sort needed to not mess
        # up the list while iterating over it.
        for idx in sorted(attempted_authentications, reverse=True):
            del self.pending_authentications[idx]

        return result, successful_auths

    def handle_hkroot(self, hkroot_bits, gst: GalileoSystemTime):
        """Perform the necessary processing for the HKROOT data section.

        Perform receiver initialization by accumulate the DSM blocks to
        complete the DSM-KROOT message.

        DSM-PKR blocks will be collected and handled during public key renewal
        process.

        Otherwise parse the NMA header and react accoding to its value.

        :hkroot_bits: the BitArray corresponding to the KROOT message
        :gst: GST corresponding to the HKROOT data
        :returns: nothin

        """
        have_kroot = (self.state == ReceiverState.READY_TO_AUTHENTICATE) and not self.eoc_coming
        have_pkr = self._stashed_pkr != None

        res = self.decoder.handle_dsm_block(hkroot_bits, have_kroot, have_pkr)

        # Update the NMA header to what the decoder read during the block
        # handling. Note that this header is not verified yet.
        self.current_nma_header = self.decoder.current_nma_header

        # When the DSM message is fully received
        if res != None:
            self.current_nma_header = self.decoder.current_nma_header
            dsm_msg, dsm_type = res

            if dsm_type == DsmMessageType.kroot:
                # Stash the KROOT if waiting for EOC, otherwise input it
                # immediately
                if self.eoc_coming:
                    self._stashed_kroot = dsm_msg
                else:
                    kroot_ok = self.validate_and_input_dsm_kroot(dsm_msg, self.current_nma_header)
                    if kroot_ok:
                        self.handle_event(Event(gst.wn, gst.tow, Events.KROOT_VERIFIED))
                        self.handle_event(Event(gst.wn, gst.tow, Events.INITIALIZATION_COMPLETE))
                        if self.save_kroot:
                            self.write_kroot(dsm_msg)
                    else:
                        self.handle_event(Event(gst.wn, gst.tow, Events.KROOT_VERIFICATION_FAILED))
                        
            if dsm_type == DsmMessageType.pkr:
                self._stash_pkr(dsm_msg)

    def extract_tags_from_pending(self):
        """Extract tags from all of the pending subframes. Assumes that the
        information necessary for extraction is available in self.config. This
        is the case when a DSM-KROOT message has been received.

        :returns: nothing, but will create pending AuthenticationUnits

        """
        processed_idx = []
        for i, subframe in enumerate(self.pending_subframes):
            # MACSEQ verification requires the key after the target subframe
            can_extract = self.authenticator.tesla_newest_key.time.total_seconds() - subframe.get_gst().total_seconds() >= 30
            if can_extract:
                self.extract_tags(subframe)
                processed_idx.append(i)

        # Delete the subframes once the tags have been extracted. The
        # navigation data has been extracted already earlier.
        for i in sorted(processed_idx, reverse=True):
            del self.pending_subframes[i]

    def extract_tags(self, subframe: InavSubframe):
        """Extract the tags from the subframe and organize them into units
        easily used by the OsnmaAuthenticator.

        :subframe: InavSubframe to extract the tags from
        :gst: GST of the current subframe

        :returns: nothing

        """
        mack = self.decoder.parse_mack_from_subframe(subframe)
        gst = subframe.get_gst()
        svid = subframe.svid

        is_valid = self.authenticator.verify_tag_sequence(self.config.MACLT, mack, gst, svid)
        if is_valid:
            self.organize_authentication_data(mack, svid)
        else:
            self.handle_event(SatelliteEvent(gst.wn, gst.tow, Events.TAG_SEQUENCE_VERIFICATION_FAILED, svid))

    def organize_authentication_data(self, mack: Mack, svid: int):
        """Take a MACK section, match the tags from it with the appropriate
        navigation data. Organize the result into AuthenticationUnit objects,
        that can be easily used be the OsnmaAuthenticator.

        :mack: Mack object corresponding to the MACK data section
        :svid: the SVID from which the MACK section is from
        :returns: nothing

        """
        gst = mack.get_gst()
        cop = mack.mack_header.cop

        # Note that the navdata can be None

        # Handle TAG0
        navdata = self.navdata_manager.get_with_cop(((gst, svid, 0)), cop)
        au = AuthenticationUnit(mack.mack_header.tag0, 0, gst, cop, navdata, svid, svid, 0)
        self.pending_authentications.append(au)

        # Handle the rest of the tags
        for i, tag in enumerate(mack.tags_and_info.tag_list):
            prnd = mack.tags_and_info.info_list[i].prnd
            adkd = mack.tags_and_info.info_list[i].adkd
            if adkd == 4:
                prnd = 255
            navdata = self.navdata_manager.get_with_cop(((gst, prnd, adkd)) , cop)
            au = AuthenticationUnit(tag, i+1, gst, cop, navdata, prnd, svid, adkd)
            self.pending_authentications.append(au)

    def input_dsm_kroot(self, dsm_kroot):
        """Input the given DSM-KROOT message to the receiver. Can be used in
        hot start scenarios. Does not validate that the message is correct or
        from a trusted source. This is done by a separate function.

        :dsm_kroot: DsmKrootMessage object
        :returns: nothing, but parses the message and inputs the results to the
        receiver
        """
        msg = dsm_kroot
        self.config.HF = msg.hash_function
        self.config.MF = msg.mac_funciton
        self.config.KS = msg.key_size
        self.config.TS = msg.tag_size
        self.config.MACLT = msg.mac_lt
        self.config.WNK = msg.wn_kroot
        self.config.TOWHK = msg.tow_kroot

        self._update_hash_and_mac_functions()

        self.decoder.key_size = msg.key_size
        self.decoder.tag_size = msg.tag_size

        # TOWHK is given in hours but we need seconds.
        root_key_gst = GalileoSystemTime(msg.wn_kroot, msg.tow_kroot * 60 * 60)
        # The time of the root key is 30 seconds before the start of applicability of the chain
        root_key_gst.subtract_seconds(30)

        self.authenticator.tesla_root_key = TeslaKey(msg.root_key, root_key_gst)
        self.authenticator.tesla_newest_key = TeslaKey(msg.root_key, root_key_gst)
        self.authenticator.alpha = msg.alpha

        self.state = ReceiverState.READY_TO_AUTHENTICATE

    def _update_hash_and_mac_functions(self):
        """Take the hash and mac from the self.config, and update it to
        self.authenticator.
        """
        if self.config.HF == 'SHA-256':
            self.authenticator.hash_function = hashlib.sha256
        elif self.config.HF == 'SHA3-256':
            self.authenticator.hash_function = hashlib.sha3_256

        # TODO: different MAC functions not implemented
        if self.config.MF == 'HMAC-SHA256':
            self.authenticator.mac_function = None
        elif self.config.MF == 'CMAC-AES':
            self.authenticator.mac_function = None

    def validate_and_input_dsm_kroot(self, dsm_kroot, nma_header):
        """Validate the DSM-KROOT message against the public key and input the
        DSM-KROOT to the receiver if the validation was successful.

        :dsm_kroot: DSM-KROOT as DsmKrootMessage
        :nma_header: NmaHeader object
        :returns: True, if DSM-KROOT was validated and inputted, False otherwise

        """
        if self.authenticator.validate_dsm_kroot(dsm_kroot, nma_header):
            self.input_dsm_kroot(dsm_kroot)
            self.verified_nma_header = nma_header
            self._handle_nma_header(nma_header)
            return True
        return False

    def _handle_nma_header(self, nma_header: NmaHeader):
        """React according to the status of the NMA header. See the ICD and
        Receiver guidelines for the CPKS or Chain and Public Key status for the
        full details on how to react to different values in the NMA header.
        This function should be called after the NMA header is verified, i.e.
        it has been used in a successful authentication.

        :nma_header: NmaHeader object to handle
        :returns: nothing, but performs necessary operations

        """
        if not self.decoder.pre_check_nma_header(nma_header):
            return

        self.current_nma_header = nma_header

        # Nothing to do
        if nma_header.cpks == 'nominal':
            return

        # Collect new DSM-KROOT on EOC event
        if nma_header.cpks == 'end of chain':
            self.eoc_coming = True

        if nma_header.cpks == 'chain revoked':
            # Previous chain revoked: jump to the next chain
            if nma_header.nmas == 'operational':
                self._jump_to_next_chain(int(nma_header.cid))
            # Current chain revoked: dump the chain, set status to initializing
            elif nma_header.nmas == "don't use":
                self.state = ReceiverState.INITIALIZING

        # If new public key will be transmitted, and will be handled when it is
        # fully received
        if nma_header.cpks == 'new public key':
            if self._stashed_pkr != None:
                self._handle_pkr()

        # Old public key revoked, jump to next key
        if nma_header.cpks == 'public key revoked':
            # Previous public key revoked: use a stashed one
            if nma_header.nmas == 'operational':
                self._handle_pkr()
            # Current public key revoked: dump the chain, set status to initializing
            elif nma_header.nmas == "don't use":
                self.state = ReceiverState.INITIALIZING

    def _handle_pkr(self):
        """Handle a public key renewal event. Begin using existing stashed
        public or start collecting PKR messages to get new public key.

        :returns: nothing

        """
        if self._stashed_pkr != None:
            if self.authenticator.verify_public_key(self._stashed_pkr):
                self.authenticator.public_key = self._stashed_pkr.new_public_key
            self._stashed_pkr = None

    def _jump_to_next_chain(self, chain_id, kroot=None):
        """Jump to the next chain if possible, if not, set status to
        initializing.

        :chain_id: Key chain ID of the next chain
        :kroot: DSM-KROOT object of the next chain, can be given here or taken
        from the member variables
        :returns: success status of the jump

        """
        if kroot == None:
            kroot = self._stashed_kroot
            if kroot == None:
                self.state = ReceiverState.INITIALIZING
                return False

        if self.validate_and_input_dsm_kroot(kroot, self.current_nma_header):
            self.current_cid = chain_id
            self.eoc_coming = False
            return True
        else:
            # Something wrong, try to initialize again
            self.state = ReceiverState.INITIALIZING
        return False

    def _stash_pkr(self, pkr):
        """Stash the entire PKR message to be used in public key renewal event,
        when appropriate NMA status is seen.

        :pkr: PKR message as DsmPkrMessage
        :returns: nothing

        """
        self._stashed_pkr = pkr

    def _stash_dsm_kroot(self, kroot):
        """Stash a DSM-KROOT object for later use. Used to store future KROOTs
        in chain change events.

        :kroot: DSM-KROOT object
        :returns: nothing

        """
        self._stashed_kroot = kroot

    def _input_stashed_kroot(self):
        """Input a stashed DSM-KROOT to the engine and handle the
        initialization.

        :returns: success status

        """
        kroot = self._stashed_kroot
        if kroot != None:
            self.input_dsm_kroot(kroot)
            return True
        return False

    def write_kroot(self, kroot: DsmKrootMessage, filename=None):
        """Write the KROOT to a a file. If filename is not provided it will be
        stored to a file called kroot_<wn>_<tow>.

        :kroot: DsmKrootMessage
        :returns: nothing

        """
        wn = kroot.wn_kroot
        tow = kroot.tow_kroot

        if filename == None:
            filename = f"kroot_{wn}_{tow}"

        with open(filename, 'w') as f:
            f.write(kroot.raw_bits.hex)
