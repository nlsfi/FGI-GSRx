'''
Utilities for reading the EUSPA test vectors.
'''
import re
import datetime

from bitstring import BitArray
from osnma.navdata import InavSubframe
from util.gst import GalileoSystemTime, GST_START_EPOCH

def testvectordate2gst(datetime):
    """Datetime as written in the testvector file names converted into GST.

    Example correspondence: 2022-02-20 08:00:01 -> 1174, 28800

    :datetime: datetime
    :returns: corresponding GalileoSystemTime

    """
    delta =  datetime - GST_START_EPOCH
    wn = int(delta.total_seconds() // 604800)
    tow = int(delta.total_seconds() % 604800)
    return GalileoSystemTime(wn, tow - 1)

class TestVectorReader:
    """Reads the test vector format, and parses InavSubframe objects from it"""

    page_size_hex = 60  # Nominal page is 240b = 60 hex symbols
    subframe_size_hex = 60*15

    def __init__(self, filename):
        self.filename = filename
        self.gst_start = self._get_gst_from_filename(filename)
        self.current_gst = self.gst_start
        self.nav_bit_streams = dict()
        self.i = 0  # index, from which the next subframe will be returned
        self.offset = 0 # current offset in the navbit stream
        self.round = 0  # round consists of reading subframes from all of the satellites once

        fd = open(filename, "r")
        reading_header = True
        for line in fd:
            # Skip header
            if reading_header:
                reading_header = False
                continue

            t = line.rstrip().split(",")
            svid = int(t[0])
            nav_bits = t[2]
            self.nav_bit_streams[svid] = nav_bits

        fd.close()
        self.svids = list(self.nav_bit_streams.keys())

        # Assume that each stream has equal size. This is the case for the
        # current test vectors
        self.stream_length = len(self.nav_bit_streams[self.svids[0]])

    def _get_gst_from_filename(self, filename):
        """Get Galileo System Time from test vector filename
        See the GSC documentation on test vectors for more information

        :filename: filename of the test vector, contains the time
        :returns: GST object of the start of the test vector

        """
        pattern = r".*(\d{2})_(\w{3})_(\d{4})_GST_(\d{2})_(\d{2})_(\d{2}).csv$"
        m = re.match(pattern, filename)

        if not m:
            print("invalid filename")
            return None

        day = m.group(1)
        month = m.group(2)
        year = m.group(3)
        hours = m.group(4)
        minutes = m.group(5)
        seconds = m.group(6)
        datestr = " ".join([year, month, day, hours, minutes, seconds])
        dt = datetime.datetime.strptime(datestr, '%Y %b %d %H %M %S')

        return testvectordate2gst(dt)

    def _get_subframe_from_navbit_stream(self):
        """Return next subframe from the current navbit stream. Note that we
        want pages to be 234b (same as in SBF), hence from each page we discard
        the 6 last bits from the even (first) page.

        :returns: InavSubframe

        """
        svid = self.svids[self.i]
        navbits = BitArray()

        for i in range(15):
            start_hex = self.offset + i*self.page_size_hex
            end_hex = start_hex + self.page_size_hex

            # Return None at the end of the stream, which is a sign for the
            # program to stop reading 
            if end_hex >= self.stream_length:
                return None

            page = BitArray(hex=self.nav_bit_streams[svid][start_hex:end_hex])
            evenpage = page[:114]
            oddpage = page[120:]
            navbits.append(evenpage)
            navbits.append(oddpage)
        return navbits

    def read(self):
        """Return next InavSubframe object. Increments i and stream offset.

        :returns: the next InavSubframe object

        """
        svid = self.svids[self.i]
        navbits = self._get_subframe_from_navbit_stream()

        self.i += 1
        # We have gone through all of the satellites, reset i, increase offset,
        # and increment round, increase current GST by 30s (one subframe)
        if self.i >= len(self.svids):
            self.i = 0
            self.round += 1
            self.current_gst.add_seconds(30)
            self.offset += self.subframe_size_hex

        wn = self.current_gst.wn
        tow = self.current_gst.tow
        return InavSubframe(wn, tow, svid, navbits)
