from enum import Enum
from dataclasses import dataclass

from util.gst import ObjectWithGst

class EventType(Enum):
    """List of different categories of events, that can be used to filter the
    events of interest.

    Explanations:

    NAV_AUTH_EVENT: event related directly to navigation message
    authentication, such as successful or failed tag authentication.

    CRYPTO_AUTH_EVENT: event related to authentication of cryptographic
    material, such as success or failure to authenticate TESLA keys

    DATA_EVENT: events related to data reception, such as subframe not
    containing OSNMA bits, or CRC error in navigation page.

    """
    NAV_AUTH_EVENT = 0
    CRYPTO_AUTH_EVENT = 1
    DATA_EVENT = 2

    def __str__(self):
        return self.name

class Events(Enum):
    """List of the common events related to OSNMA and data reception that will
    be reported.

    Event descriptions:

    AUTH_OK: authentication fully successful.

    AUTH_OK_WITH_OLD_NAVDATA: authentication successful, but older navigation
    data was used because the correct navigation data was not received. It is
    up to the user the decide whether to trust this form of authentication.

    INVALID_TAG: authentication failed with no clear reason why.

    INVALID_TAG_WITH_OLD_NAVDATA: authentication failed, but old navigation
    data was used, because the correct navigation data was not received.
    Therefore, this may not be anomalous.

    KROOT_BLOCK_RECEIVED: a DSM-KROOT block was received

    KROOT_RECEIVED: the entire DSM-KROOT message was received

    INITIALIZATION_COMPLETE: OSNMA initialization completed. Ready to authenticate.

    PUBLIC_KEY_VERIFIED: public key verified successfully by using the Merkle tree

    CANNOT_VERIFY_PUBLIC_KEY: public key cannot be verified, because we are
    missing some information, such as the Merkle tree.

    TAG_SEQUENCE_VERIFICATION_FAILED: the tags should be transmitted in fixed
    sequence specified by the MACLT value. This is reported when the received
    sequence differs from the expected sequence.

    CRC_ERROR: received a navigation page with a failed CRC. The data is likely
    corrupted.

    INCOMPLETE_SUBFRAME: received a subframe with one or more missing pages.
    You may try to extract the relevant data in any case.

    NO_OSNMA_BITS: the received navigation page does not contain OSNMA bits.
    """
    # Authentication events
    AUTH_OK = 0
    NAVDATA_MISSING = 8
    INVALID_TAG = 9

    # Crypto events
    PUBLIC_KEY_VERIFIED = 20
    KROOT_VERIFIED = 21
    TESLA_KEY_VERIFIED = 22
    TESLA_KEY_VERIFICATION_FAILED = 26
    KROOT_VERIFICATION_FAILED = 27
    PUBLIC_KEY_VERIFICATION_FAILED = 28
    TAG_SEQUENCE_VERIFICATION_FAILED = 29
    KEY_ITERATION_LIMIT_REACHED = 30
    NO_MERKLE_TREE = 31

    # DSM events
    KROOT_BLOCK_RECEIVED = 40
    KROOT_RECEIVED = 41
    INITIALIZATION_COMPLETE = 42

    # Data transmission events
    CRC_ERROR = 60
    INCOMPLETE_SUBFRAME = 61
    SUBFRAME_RECEIVED = 62
    NO_OSNMA_BITS = 63

    def get_type(self):
        if self.value < 9:
            return EventType.NAV_AUTH_EVENT
        if self.value < 50:
            return EventType.CRYPTO_AUTH_EVENT
        return EventType.DATA_EVENT

    def is_about_authentication(self):
        """Return true if the event is related to an authentication attempt.
        """
        if self.value < 10:
            return True
        return False

    def is_successful_authentication(self, strict=False):
        """Return true if the event is about a successful authentication.

        :strict: when True, only accept AUTH_OK as successful authentication.
        In other words, AUTH_OK_WITH_OLD_NAVDATA and others will not be
        accepted.
        """
        if strict:
            return self.value == Events.AUTH_OK.value
        else:
            return self.value < 3
        return False

    def used_old_navdata(self):
        """For authentications events, declare that older navigation message
        was used. For example, change the AUTH_OK to AUTH_OK_WITH_OLD_NAVDATA.
        Does nothing for events where this is not applicable.

        :returns: the corresponding event, but with the old navigation data
        declaration
        """
        # Not applicable
        if self.value == Events.AUTH_OK.value or self.value == Events.INVALID_TAG.value:
            return Events(self.value + 1)
        return self

    def __str__(self):
        return self.name

@dataclass
class Event(ObjectWithGst):
    """
    """
    event: Events

    def msg(self):
        m = ""
        if type(self.event) == Events:
            m += f"{self.event.get_type()}, "
        m += f"{self.event}: wn={self.wn}, tow={self.tow}"
        return m

    def print(self):
        print(self.msg())

#@dataclass
#class Event(ObjectWithGst):
#    """Represents any timestampped event that can be handled by the
#    EventHandler.
#
#    :event: describes the represented event. Can be from the standard list of
#    events, it can be a string describing the event as well.
#
#    """
#    event: str
#
#    def msg(self):
#        return f"{self.event}: wn: {self.wn}, tow: {self.tow}"
#
#    def print(self):
#        print(self.msg())

@dataclass
class SatelliteEvent(Event):
    """Event that involves a satellite or data from a satellite. For example a
    page CRC error, or receiving a DSM-block from a satellite.

    :svid: SVID of the satellite involved in the event
    """
    svid: int

    def msg(self):
        return super().msg() + f", svid={self.svid}"

@dataclass
class AuthEvent(SatelliteEvent):
    """Event involving authentication. For example successful and failed tag
    authentications.

    :svid: the SVID of the satellite whose navigation message is being
    authenticated
    :prna: SVID of the satellite transmitting the authentication information
    :adkd: ADKD number as defined in the ICD
    """
    prna: int
    adkd: int

    def msg(self):
        return super().msg() + f", prna={self.prna}, adkd={self.adkd}"

    def is_successful(self):
        return self.event.is_successful_authentication()

class EventHandler:
    """Event handler that will be implemented by the core classes (OsnmaEngine,
    OsnmaDecoder, NavigationDataManager, OsnmaAuthenticator, etc). This way the
    classes can handle events (i.e. call 'handle_event'), and indirectly get
    access to the 'subscriber_system', which handles the event callbacks.

    """
    def __init__(self):
        self.callbacks = []

    def handle_event(self, event: Event):
        """Handle the event by deferring the event handling to the subscriber
        system. The callback functions registered in the subscriber system will
        be called.

        :event: Event object to handle
        :returns: nothing

        """
        event.print()

    def handle_events(self, events: list):
        """Handle a list of events.

        :events: list to handle
        :returns: nothing

        """
        for event in events:
            self.handle_event(event)

