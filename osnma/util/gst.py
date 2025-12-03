import datetime
from bitstring import BitArray
from dataclasses import dataclass
from leapseconds import LEAP_SECONDS

# Start epoch of the GST and the number of leap seconds in GST
GST_START_EPOCH = datetime.datetime(1999, 8, 22)
GST_LEAP_SECONDS = len(LEAP_SECONDS) - 10

class GalileoSystemTime:

    seconds_in_week = 604800
    max_week_number = 4095

    def __init__(self, wn: int, tow: int):
        self.wn = wn # Week number between 0 and 4095
        self.tow = tow # Time of week between 0 and seconds_in_week-1

    # Seconds can also be negative
    def add_seconds(self, seconds: int):
        self.tow += seconds
        while self.tow >= GalileoSystemTime.seconds_in_week: # Overflow
            self.tow -= GalileoSystemTime.seconds_in_week
            self.wn += 1
        while self.tow < 0: # Underflow
            self.tow += GalileoSystemTime.seconds_in_week
            self.wn -= 1

        # Overflows and underflows in week number are never supposed to happen so they are not handled
        assert(self.wn >= 0)
        assert(self.wn <= GalileoSystemTime.max_week_number)

    def subtract_seconds(self, seconds: int):
        self.add_seconds(-seconds)

    def bit_packed(self):
        return BitArray(uint=self.wn, length=12) + BitArray(uint=self.tow, length=20)

    def total_seconds(self):
        return self.wn * GalileoSystemTime.seconds_in_week + self.tow

    def __lt__(self, other):
        return self.total_seconds() < other.total_seconds()

    def __repr__(self):
        return "GST(wn = {}, tow = {})".format(self.wn,self.tow)

    def __hash__(self):
        return self.total_seconds()

    def __eq__(self, other):
        return other != None and (self.total_seconds() == other.total_seconds())

@dataclass
class ObjectWithGst:
    """Represents and object with Galileo System Time, or rather Week Number
    and Time of Week
    """
    wn: int
    tow: int

    def get_gst(self):
        """Return a GalileoSystemTime object from the WN and TOW
        :returns: GalileoSystemTime

        """
        return GalileoSystemTime(self.wn, self.tow)

    def _is_same_subframe(self, obj_with_gst):
        """Check if two GSTs correspond to the same subframe

        :obj_with_gst: ObjectWithGst
        :returns: True, if the the timestamps are from the same subframe

        """
        t0 = self.get_gst_epoch()
        t1 = obj_with_gst.get_gst_epoch()

        return (t0 // 30) == (t1 // 30)

    def _get_subframe_start_tow(self):
        """Given a TOW of a page, get the start TOW of the subframe that page
        belongs to.

        :tow: time of week of the page
        :returns: time of week of the subframe start time, to which the page
        belongs to

        """
        page_number = (self.tow % 30) // 2
        # Note that this will always be positive
        tow = self.tow - 2*page_number
        return tow

    def get_gst_epoch(self):
        """ Return the GST epoch of the object

        :returns: number of seconds elapsed since GST start
        """
        return 604800*self.wn + self.tow

def gst2datetime(wn, tow):
    """Convert Galileo System Time to datetime

    :wn: Week Number of the GST
    :tow: Time of Week of the GST
    :returns: datetime corresponding to the gst

    """
    dt = GST_START_EPOCH + datetime.timedelta(days=wn*7, seconds=tow-GST_LEAP_SECONDS)
    return dt

def gst2timestamp(wn, tow):
    """Convert Galileo System Time to UNIX timestamp

    :wn: Week Number of the GST
    :tow: Time of Week of the GST
    :returns: timestamp corresponding to the GST

    """
    return int(gst2datetime(wn, tow).timestamp())

def get_gst_epoch(wn, tow):
    """ Return the GST epoch

    :wn: Week Number of the GST
    :tow: Time of Week of the GST
    :returns: number of seconds elapsed since GST start
    """
    return 604800*wn + tow
