import sys
import cryptography
import copy
import hashlib
import hmac
from enum import Enum
from dataclasses import dataclass
from bitstring import BitArray
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec as ec
from cryptography.hazmat.primitives.serialization import load_pem_public_key

from util.gst import GalileoSystemTime
from osnma.dsm import NmaHeader, DsmKrootMessage, DsmPkrMessage
from osnma.mack import TeslaKey, TagsAndInfo, Mack
from crypto.merkletree import MerkleTree

from datasink.events import EventHandler, Events, Event, SatelliteEvent, AuthEvent

# (MACLT_value, subframe_offset) -> MACLT sequence
MACLT_SEQUENCES = {}
MACLT_SEQUENCES[(27, 0)] = ["00S", "00E", "00E", "00E", "12S", "00E"]
MACLT_SEQUENCES[(27, 30)] = ["00S", "00E", "00E", "04S", "12S", "00E"]
MACLT_SEQUENCES[(28, 0)] = ["00S", "00E", "00E", "00E", "00S", "00E", "00E", "12S", "00E", "00E"]
MACLT_SEQUENCES[(28, 30)] = ["00S", "00E", "00E", "00S", "00E", "00E", "04S", "12S", "00E", "00E"]
MACLT_SEQUENCES[(31, 0)] = ["00S", "00E", "00E", "12S", "00E"]
MACLT_SEQUENCES[(31, 30)] = ["00S", "00E", "00E", "12S", "04S"]
MACLT_SEQUENCES[(33, 0)] = ["00S", "00E", "04S", "00E", "12S", "00E"]
MACLT_SEQUENCES[(33, 30)] = ["00S", "00E", "00E", "12S", "00E", "12E"]
MACLT_SEQUENCES[(34, 0)] = ["00S", "FLX", "04S", "FLX", "12S", "00E"]
MACLT_SEQUENCES[(34, 30)] = ["00S", "FLX", "00E", "12S", "00E", "12E"]
MACLT_SEQUENCES[(35, 0)] = ["00S", "FLX", "04S", "FLX", "12S", "FLX"]
MACLT_SEQUENCES[(35, 30)] = ["00S", "FLX", "FLX", "12S", "FLX", "FLX"]
MACLT_SEQUENCES[(36, 0)] = ["00S", "FLX", "04S", "FLX", "12S"]
MACLT_SEQUENCES[(36, 30)] = ["00S", "FLX", "00E", "12S", "12E"]
MACLT_SEQUENCES[(37, 0)] = ["00S", "00E", "04S", "00E", "12S"]
MACLT_SEQUENCES[(37, 30)] = ["00S", "00E", "00E", "12S", "12E"]
MACLT_SEQUENCES[(38, 0)] = ["00S", "FLX", "04S", "FLX", "12S"]
MACLT_SEQUENCES[(38, 30)] = ["00S", "FLX", "FLX", "12S", "FLX"]
MACLT_SEQUENCES[(39, 0)] = ["00S", "FLX", "04S", "FLX"]
MACLT_SEQUENCES[(39, 30)] = ["00S", "FLX", "00E", "12S"]
MACLT_SEQUENCES[(40, 0)] = ["00S", "00E", "04S", "12S"]
MACLT_SEQUENCES[(40, 30)] = ["00S", "00E", "00E", "12E"]
MACLT_SEQUENCES[(41, 0)] = ["00S", "FLX", "04S", "FLX"]
MACLT_SEQUENCES[(41, 30)] = ["00S", "FLX", "FLX", "12S"]

@dataclass
class AuthenticationUnit:
    """Unit containing all of the necessary information to perform an
    authentication, apart from the TESLA key.

    :tag: the authentication tag as BitArray
    :tag_index: index of the tag in the sequence
    :tag_gst: GST of tag reception
    :cop: cut off point, indicating how many subframes back the navigation data
    can be
    :navdata: the navigation data extracted as per the ADKD type. Can be None
    if the correct data was not received.
    :prnd: SVID of the satellite transmitting the navigation data to be
    authenticated
    :prna: SVID of the satellite transmitting the tag
    :adkd: Authentication Data and Key Delay value, as per ICD
    """
    tag: BitArray
    tag_index: int
    tag_gst: GalileoSystemTime
    cop: int
    navdata: BitArray
    prnd: int
    prna: int
    adkd: int

    def is_dummy(self):
        """Check if the unit corresponds to a dummy tag
        :returns: True if dummy

        """
        return cop == 0

    def verify_tag(self, key: TeslaKey, nma_header: NmaHeader):
        """TODO: Docstring for verify_tag.

        :key: TeslaKey to use in the verification
        :nma_header: NmaHeader to use in the verification
        :returns: AuthenticationAttempt object corresponding to the
        verification result

        """
        pass

class OsnmaException(Exception): # Base class for OSNMA expections
    pass

class OsnmaAuthenticationException(OsnmaException):
    """ OSNMA Authentication failures raise this exception """
    pass

def pad_to_multiple_of_8(data: BitArray):
    """ Append zeros to data until the length is a multiple of 8
    """
    pad_length = 8 - len(data) % 8
    if pad_length < 8:
        padding = "0b" + "".join(['0']*pad_length) # pad_length zeroes
        data.append(BitArray(padding))

class OsnmaAuthenticator(EventHandler):
    """Class for OSNMA related cryptographic material and operations. See the
    OSNMA documentation for the full details.

    Members:
    :public_key: Galileo public key as bytes
    :tesla_root_key: TESLA root key as BitArray
    :tesla_newest_key: newest verified TESLA key as BitArray
    :alpha: hash salt that is received with the DSM-KROOT message

    :key_iteration_limit: sets a limit to the number of hash iterations that
    will be done to authenticate a single key. During normal use this is not
    needed, but if we receive a subframe (or rather a TESLA key) with a
    faulty/false timestamp, we may end up doing an unreasonable number of hash
    iterations to verify the faulty key, which we want to avoid in real-time
    use.

    """
    def __init__(self, public_key_pem, merkle_root=None, iteration_limit=None):
        # TODO: cryptography doesn't accept this format anymore: take the BEGIN EC PARAMETERS OUT
        """
        :public_key_pem: The Galileo OSNMA public key, in PEM text format. The
        key can be downloaded from the OSNMA website. The PEM should contain
        both the elliptic curve parameters and the key. For example, the key on
        6.12.2021 is encoded as follows:

        -----BEGIN EC PARAMETERS-----
        BggqhkjOPQMBBw==
        -----END EC PARAMETERS-----
        -----BEGIN PUBLIC KEY-----
        MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAErZl4QOS6BOJl6zeHCTnwGpmgYHEb
        gezdrKuYu/ghBqHcKerOpF1eEDAU1azJ0vGwe4cYiwzYm2IiC30L1EjlVQ==
        -----END PUBLIC KEY-----
        """
        self.public_key = bytes(public_key_pem, encoding="ascii")
        self.merkle_tree = None
        if merkle_root != None:
            self.merkle_tree = MerkleTree(merkle_root)

        # These will be usually obtained with a delay
        self.tesla_root_key = None
        self.tesla_newest_key = None
        self.alpha = None

        self.key_iteration_limit = None

        self.hash_function = hashlib.sha256
        # TODO: mac function
        self.mac_function = None

    def validate_dsm_kroot(self, dsm_kroot: DsmKrootMessage, nma_header: NmaHeader, public_key_pem: bytes=None):
        """ Authenticate the DSM-KROOT message and the NMA header using the given public key. Implements Section 6.3 of [1].

        :nma_header: NMA header as NmaHeader object
        :dsm_kroot: DSM-KROOT as DsmKrootMessage object
        :public_key_pem: The public key in ASCII-encoded pem format.
        :return: True if authentication was successful.
        :raises OsnmaAuthenticationException: If authentication was unsuccesful.
        """

        ks = dsm_kroot.key_size
        ds = dsm_kroot.digital_signature

        bits_to_authenticate = nma_header.raw_bits + dsm_kroot.raw_bits[8:104+ks]
        pad_to_multiple_of_8(bits_to_authenticate)

        # https://cryptography.io/en/latest/hazmat/primitives/asymmetric/ec/
        # Split the digital signature into the parts (r,s) and encode in DER
        # format
        sig_der = cryptography.hazmat.primitives.asymmetric.utils.encode_dss_signature(ds[0:256].uint, ds[256:512].uint)

        # Verify that DS is a valid signature of the message with the known public key of Galileo OSNMA
        # Use the state public key unless a key is explicitly given
        if public_key_pem == None:
            public_key_pem = self.public_key
        public_key = load_pem_public_key(public_key_pem)

        try:
            public_key.verify(sig_der, bits_to_authenticate.tobytes(), ec.ECDSA(hashes.SHA256()))
            return True
        except cryptography.exceptions.InvalidSignature:
            raise OsnmaAuthenticationException("DSM-KROOT authentication failure.")

    def iterate_key_chain(self, key: TeslaKey, alpha: BitArray, steps: int):
        """ Iterate the key chain to the past

        :key: The key to start from.
        :alpha: hash salt
        :steps: How many steps to go to the past.
        :return: The computed past key
        """
        K = key.key[:]
        t = copy.deepcopy(key.time)
        for i in range(steps):
            t.subtract_seconds(30)
            m = self.hash_function()
            m.update((K + t.bit_packed() + alpha).tobytes())
            K = BitArray(m.digest())[0 : len(K)]
        return TeslaKey(K,t)

    def iterate_to_correct_key(self, key, target_gst, alpha, adkd=0):
        """Iterate key until the correct key.

        :key: TeslaKey object
        :target_gst: gst to iterate until
        :alpha: salt to use in hashing
        :adkd: ADKD number, specifies whether there should be 1 or 11 subframe
        offset between the key and the tag

        :returns: the iterated key, or None if the iteration cannot be
        performed. This can be the case because the key corresponding to the
        tag is transmitted with a delay.
        """
        if key == None:
            return None

        # Key and tesla key timestamp should differ by a multiple of
        # subframe time (30s), and to perform authentication, the key must
        # be at least one subframe after the tag
        dt = key.time.total_seconds() - target_gst.total_seconds()
        assert(dt % 30 == 0)
        if dt <= 0: return None

        # ADKD 12 aka slow MAC: additional 10 key delay instead of 1
        if adkd == 12 and dt < 11*30:
            # Not ready for ADKD 12 authentication
            return None

        # Derive the correct key from the newest key for others than ADKD=12
        past_key = key
        if dt > 30 and adkd != 12:
            n_steps = dt // 30 - 1
            past_key = self.iterate_key_chain(key, alpha, n_steps)

        # ADKD=12 key iteration
        if adkd == 12 and dt > 11*30:
            # Slow MAC: normal delay is 330s, iterate to that
            n_steps = (dt - 330) // 30
            past_key = self.iterate_key_chain(key, alpha, n_steps)

        return past_key

    def verify_and_input_tesla_key(self, key: TeslaKey):
        """Verify the TESLA key against either the root key or a previously
        verified key.

        :key: TESLA key to verify
        :returns: True if the key is valid, return False if the key is not
        processed (i.e. key is not newer than current)
        :except: throw exception if the key is not valid

        """
        if self.tesla_newest_key == None:
            raise OsnmaAuthenticationException(f"Key could not be authenticated: no root/verified key available")

        if key.time.total_seconds() <= self.tesla_newest_key.time.total_seconds():
            # Do not process keys unless they are newer than current
            return False

        is_valid = self.verify_tesla_key_against_trusted_key(key, self.tesla_newest_key, self.alpha)
        if is_valid:
            self.tesla_newest_key = key
            return True
        return False

    def verify_tesla_key_against_trusted_key(self, key: TeslaKey, trusted_key: TeslaKey, alpha: BitArray):
        """ Authenticate a new TESLA key against a trusted TESLA key. Implements Section 6.4 of [1].

        :key: The key to authenticate.
        :trusted_key: The trusted key.
        :alpha: The hash salt of the key chain (distributed in the DSM_KROOT message).
        :return: True if authentication was successful.
        :raises OsnmaAuthenticationException: If authentication was unsuccesful.
        """

        # Key must come after a trusted key
        dt = key.time.total_seconds() - trusted_key.time.total_seconds()
        assert(dt > 0)
        assert(dt % 30 == 0)
        n_iter = dt // 30
        if self.key_iteration_limit and n_iter > self.key_iteration_limit:
            self.handle_event(Event(key.time.wn, key.time.tow, Events.KEY_ITERATION_LIMIT_REACHED))
            self.handle_event(Event(key.time.wn, key.time.tow, "Required iterations: " + str(n_iter) + ", "))
            return False
        K = self.iterate_key_chain(key, alpha, n_iter)

        if K.key.hex == trusted_key.key.hex:
            return True
        return False

    def verify_macseq(self, mack: Mack, prna: int, gst: GalileoSystemTime, flx_indices: list):
        """Verify the received MACSEQ.

        """
        # MACSEQ verification is not mandatory if there are no FLX tags
        if len(flx_indices) == 0:
            return True

        prna_bits = BitArray(uint=prna, length=8)
        macseq_bits = mack.mack_header.macseq
        msg = prna_bits + gst.bit_packed()

        # Iterate through the info list and append the info bits from any flex
        # tags
        for i in flx_indices:
            info = mack.tags_and_info.info_list[i]
            msg += info.raw_bits

        # The key used for the MACSEQ verification is the same one that
        # generated the tags, i.e. from the next subframe
        key = self.iterate_to_correct_key(self.tesla_newest_key, gst, self.alpha)

        computed_macseq = BitArray(bytes=hmac.new(key.key.tobytes(), msg.tobytes(), hashlib.sha256).digest())[0:12]

        if macseq_bits == computed_macseq:
            return True

        print("Failed to authenticate MACSEQ:", mack, key, file=sys.stderr)
        return False

    def verify_tag_sequence(self, maclt: int, mack: Mack, subframe_time: GalileoSystemTime, prna: int):
        """ Verify that the tag info sequence matches the MACLT entry. Implements Section 6.5 of [1].

        :MACLT: The pointer to the MACLT table (transmitted in the DMS_KROOT message).
        :mack: the Mack object corresponding to the MACK message
        :subframe_time: Start time of the subframe containing the data.
        :prna: The SVID (Space Vehicle ID) of the satellite transmitting the tag info.
        :return: True if authentication was successful.

        """
        # Fetch the correct tag sequence
        seq = MACLT_SEQUENCES.get((maclt, subframe_time.tow % 60))
        if seq == None:
            return False

        # Check the length. The tag0 is not contained in the tags and info, hence the +1
        tags_and_info = mack.tags_and_info
        if len(tags_and_info.info_list) + 1 != len(seq):
            return False

        flx_indices = []
        for i in range(1, len(seq)):
            # seq[0] is not checked as it always corresponds to ADKD0
            # self-authentication. Therefore, first tag info corresponds to the
            # second tag
            tag_info = tags_and_info.info_list[i-1]

            if seq[i] == "FLX":
                # The validity of the flex tags are checked in the next step,
                # right now just mark their indices
                flx_indices.append(i-1)
                continue

            expected_adkd = int(seq[i][0:2])
            is_self_auth = (tag_info.prnd == prna) or (tag_info.adkd == 4 and tag_info.prnd == 255)
            # Self-auth is marked with 'S' in the MAC sequence, cross-auth with a 'E'
            should_be_self_auth = seq[i][2] == 'S'

            if tag_info.adkd != expected_adkd:
                return False

            if is_self_auth != should_be_self_auth:
                return False

        if not self.verify_macseq(mack, prna, subframe_time, flx_indices):
            return False

        return True

    #def verify_tag(self, tag: BitArray, key: TeslaKey, nav_data: BitArray,
    #               tag_gst: GalileoSystemTime, nma_header: NmaHeader,
    #               index: int, prnd: int, prna: int, adkd: int):
    def verify_tag(self, authunit: AuthenticationUnit, key: TeslaKey, nma_header: NmaHeader):
        """Verify a tag be recomputing it from the navigation data and
        metadata, and comparing the result to the target tag.

        :authunit: AuthenticationUnit containing most of the data needed to
        authenticate
        :key: TeslaKey object to use
        :nma_header: NmaHeader object
        :returns: AuthAttempt object with the authentication result

        """
        tag = authunit.tag
        navdata = authunit.navdata
        tag_gst = authunit.tag_gst
        index = authunit.tag_index
        prnd = authunit.prnd
        prna = authunit.prna
        adkd = authunit.adkd

        received_tag = tag.tobytes()
        data = self.create_auth_msg(navdata, prnd, prna, tag_gst, index, nma_header)
        computed_tag = hmac.new(key.key.tobytes(), data.tobytes(), hashlib.sha256).digest()[0:len(received_tag)]

        attempt = AuthEvent(tag_gst.wn, tag_gst.tow, Events.INVALID_TAG, prnd, prna, adkd)
        if received_tag == computed_tag:
            attempt.event = Events.AUTH_OK

        return attempt

    def verify_public_key(self, pkr_msg: DsmPkrMessage):
        """Verify a public key by using the cryptographic material from a PKR
        message.

        :pkr_msg: the entire PKR message as DsmPkrMessage
        :returns: True when the public key is valid

        """
        if self.merkle_tree == None:
            self.handle_event(Event(-1, -1, Events.NO_MERKLE_TREE))
            return True
        return self.merkle_tree.validate_public_key(pkr_msg)

    def create_auth_msg(self, auth_data: BitArray, PRND: int, PRNA: int, gst: GalileoSystemTime, tag_index: int, nma_header: NmaHeader):
        """Concatenate context information to create the input for the tag
        creation and authentication.

        :auth_data: Bits to be authenticated (e.g. from _get_ADKD0_data or _get_ADKD4_data)
        :PRND: the id of the satellite transmitting the authentication data
        :PRNA: the id of the satellite transmitting the tag
        :gst: The time at which `auth_data` was transmitted
        :tag_index: The 0-based index of the tag that authenticates `auth_data` in the tag list (tag0 has index 0).
        :nma_header: The current NMA header

        :return: the message that will be authenticated
        """

        PRNA_byte = BitArray(uint=PRNA, length=8)
        PRND_byte = BitArray(uint=PRND, length=8)
        GST = gst.bit_packed()
        CTR = BitArray(uint=tag_index+1, length=8) # +1: the counter uses 1-based indexing
        nmas = nma_header.raw_bits[0:2]

        # ADKD=4 calculation uses PRND=PRNA
        if PRND == 255:
            PRND_byte = PRNA_byte

        if tag_index == 0: # TAG0
            msg = PRNA_byte + GST + CTR + nmas + auth_data
        else:
            msg = PRND_byte + PRNA_byte + GST + CTR + nmas + auth_data

        pad_to_multiple_of_8(msg)
        return msg

