import copy
import util.gst as gst

from datetime import datetime
from bitstring import BitArray
from collections import defaultdict
from dataclasses import dataclass

from util.gst import GalileoSystemTime
from datasink.events import EventHandler, SatelliteEvent, Events

# Following the Septentrio convention: the middle 6 bits of the 240b double
# page removed
INAV_PAGE_SIZE = 234

@dataclass
class InavSubframe(gst.ObjectWithGst):
    """
    Embodies an I/NAV subframe.

    Attributes
    ----------
    wn: int
        Galileo week number. Inherited from superclass.
    tow: int
        Galileo time of week. Inherited from superclass.

    svid: int
        Space vehicle identifier of the satellite transmitting the subframe.
    data: BitArray
        The concatenation of the 15 nominal pages of a E1 subframe, 234 bits
        per page, therefore total length of 3510, in the order: even, odd,
        even, odd... This arrray is preallocated by default.
    pages_received: list
        Consists of 15 booleans, where the i:th elements represents whether the
        i:th page has been received.
    """
    svid: int

    data: BitArray = 0

    def __post_init__(self):
        """Validate the input data.
        """
        assert(self.svid>0)
        assert(self.wn>0)
        #The remainder after division by 60 should be either 0 or 30.
        assert(self.tow%60==0 or self.tow%60==30)

        self.pages_received: list = [False]*15
        # If no data or empty data was given, allocate one subframe
        if self.data == 0:
            self.data = BitArray(bin='0'*3510)

    def strId(self):
        return "wn={}, tow={}, svid={}".format(self.wn, self.tow, self.svid)

    def clear_data(self):
        """Reset the data and the pages received.

        :returns: nothing

        """
        self.data[:] = BitArray(bin='0'*3510)
        for i, _ in enumerate(self.pages_received):
            self.pages_received[i] = False

    def insert_page(self, page):
        """Insert InavPage to the subframe

        :page: InavPage to insert
        :returns: nothing, but modifies the internal data

        """
        page_number = page.page_number
        start = INAV_PAGE_SIZE*page_number
        stop = start + INAV_PAGE_SIZE
        self.data[start:stop] = page.navbits
        self.pages_received[page_number] = True

    @staticmethod
    def from_list_of_pages(pages, allow_gaps=False):
        """Initialize a InavSubframe from a list of InavPage objects. Note that
        in order to get a complete subframe, the first page should be the start
        of the subframe and there should be 15 consecutive pages. If there are
        gaps, i.e. a page is missing, the subframe will still be returned if
        the allow_gaps argument is true, and the missing pages will contain
        only 0s. All of the pages should be from the same subframe.

        :pages: list of InavPages
        :allow_gaps: If True, return the subframe even if pages are missing.
        :returns: InavSubframe object or None, if it was not possible to create
        the subframe.

        """

        if len(pages) == 0:
            return None

        if len(pages) < 15:
            SatelliteEvent(pages[0].wn, pages[0].tow, Events.INCOMPLETE_SUBFRAME, pages[0].svid).print()

        # If we do not allow gaps in the subframe, make sure that we have
        # exactly 15 pages, each with 2 second offset from the previous (so 30s
        # of continuous data).
        if not allow_gaps:
            if len(pages) < 15:
                return None

        p = pages[0]
        subframe = InavSubframe(p.wn, p._get_subframe_start_tow(), p.svid)
        for page in pages:
            subframe.insert_page(page)

        return subframe

@dataclass
class InavPage(gst.ObjectWithGst):
    """
    Embodies a single nominal I/NAV page.

    Attributes
    ----------
    navbits: BitArray
        Raw INAV navigation bits.
    svid: int
        Space vehicle identifier of the satellite transmitting the page.
    wn: int
        Galileo week number. Inherited from superclass.
    tow: int
        Galileo time of week. Inherited from superclass.
    page_number: int
        The number of the page, starting from 0. Is calculated from the tow.
    arrival_dt: datetime
        Optional: datetime of the reception of the InavPage. In realtime
        operations this can be used the check the consistency between the
        system time and receiver time.
    """
    svid: int
    navbits: BitArray
    arrival_dt: datetime = None

    def __post_init__(self):
        self.page_number = (self.tow % 30) // 2

class PageAccumulator:
    """Accumulates (INAV) pages (from all of the satellites) and returns
    subframes when enough pages have been accumulated.
    """

    def __init__(self, allow_gaps=False):
        # svid -> list of pages received
        self.pages = defaultdict(list)
        self.allow_gaps = allow_gaps

    def _is_subframe_started(self, svid):
        """Check if the subframe corresponding to given SVID is started

        :svid: target SVID
        :returns: True if the subframe is started

        """
        if len(self.pages[svid]) > 0:
            return True
        return False

    def handle_page(self, page: InavPage):
        """Handle incoming pages: append it to a list of pages and return the
        subframe once it is possible.

        :page: InavPage to process
        :returns: InavSubframe if a subframe is ready, None otherwise

        """

        # If the page is from a different subframe return the old one and
        # insert the page to a new one
        if self._is_subframe_started(page.svid) and not page._is_same_subframe(self.pages[page.svid][0]):
            subframe = self._return_subframe_and_clear(page.svid, self.allow_gaps)
            self._insert_page(page)
            return subframe

        # Usually just insert the page
        self._insert_page(page)

        # Subframe ready, note that there can be gaps
        if page.page_number == 14:
            subframe = self._return_subframe_and_clear(page.svid, self.allow_gaps)
            return subframe

        return None

    def _insert_page(self, page: InavPage):
        """Insert a new page. This function does not validate that the page is
        from the current subframe. This should be checked before calling the
        function.

        :page: Page to insert in the list
        :returns: nothing

        """
        self.pages[page.svid].append(page)

    def _return_subframe_and_clear(self, svid, allow_gaps=False):
        """Check if the subframe from the given SVID can be returned, return it and clear the subframe

        :svid: target SVID
        :returns: InavSubframe, if it can be returned, None otherwise

        """
        subframe = InavSubframe.from_list_of_pages(self.pages[svid], allow_gaps)
        self.pages[svid] = []
        return subframe

class SubframeFactory:
    """
    Instantiates InavSubframe objects from a source of InavPage objects.
    """
    def __init__(self, pagereader, allow_gaps=False):
        self.pagereader = pagereader
        self.page_accumulator = PageAccumulator(allow_gaps)

    def read(self):
        while True:
            page = self.pagereader.read()

            if page == None:
                continue

            result = self.page_accumulator.handle_page(page)
            if result == None:
                continue
            return result

class NavDataManager:
    def __init__(self):
        # (gst, svid, adkd) -> BitArray
        self.navdata = {}
        # (svid, adkd) -> (BitArray, gst)
        self.prev_nav_data = {}

    def get(self, key):
        """Get the value based on the key

        :key: key of the format (gst, svid, adkd) to use in the lookup
        :returns: the value corresponding to the key or None if nothing was
        found
        """
        navdata = self.navdata.get(key)
        return navdata

    def get_with_cop(self, key, cop):
        """Get the navigation data according to the key. Accept older
        navigation data according to the COP (cut off point) value, and return
        a dummy tag when cop=0.

        :key: key of the format (tag_gst, svid, adkd) to use in the lookup. The
        navigation data one subframe before the tag_gst will be searched for,
        as defined by the ICD.
        :cop: Cut-Off Point, as defined in the ICD

        :returns: the value corresponding to the key or None if nothing was
        found

        """
        target_gst = copy.deepcopy(key[0])
        target_gst.subtract_seconds(30)
        svid = key[1]
        adkd = key[2]

        if cop == 0:
            return self._get_dummy_navdata(adkd)

        offset = 30
        limit = 30*cop
        while offset <= limit:
            navdata = self.get((target_gst, svid, adkd))
            if navdata != None:
                return navdata
            target_gst.subtract_seconds(30)
            offset += 30

        return None

    def get_any(self, key):
        """Get any available navigation data matching the key. Can be old.

        :key: triple (gst, svid, adkd) to use in the lookup
        :returns: pair navdata, gst, where data is the lookup results and the
        GST is the time corresponding to the data. Can be None if nothing is
        found.
        """
        navdata = self.navdata.get(key)

        # Exactly matching data found
        if navdata != None:
            return navdata, target_gst

        # Previous/old navdata and the navdata GST, can be None
        res = self.prev_nav_data.get(key[1:])
        return res

    def get_latest(self, key):
        """Get the latest available navdata corresponding to the key.

        :key: triple (gst, svid, adkd) to use in the lookup
        :returns: pair navdata, gst, where data is the lookup results and the
        GST is the time corresponding to the data. Can be None if nothing is
        found.
        """
        result = self.prev_nav_data.get(key[1:])
        return result

    def add_nav_data(self, svid, gst, adkd, navdata):
        """Add auth/nav data to the list

        :svid: SVID corresponding to the data
        :gst: GST when the data was received
        :adkd: ADKD number as per specification
        :navdata: the navidation data corresponding to the ADKD
        :returns: nothing

        """
        self.navdata[(gst, svid, adkd)] = navdata
        self.prev_nav_data[(svid, adkd)] = (navdata, gst)

    def remove(self, key):
        """Remove entry from the navdata dictionary if it exists

        :key: Key to remove the value from
        :returns: nothing

        """
        if key in self.navdata:
            del self.navdata[key]

    def extract_and_insert_authdata(self, subframe: InavSubframe, insert_adkd4=True, insert_adkd12=True):
        """Extract ADKD=0 authdata (same for ADKD=12), and optionally ADKD=4
        data as well. Insert the specified data to the authenticator.

        :subframe: InavSubframe object
        :insert_adkd4: whether to extract and insert adkd=4 data as well
        :insert_adkd12: whether to insert adkd=12 data as well
        :returns: nothing
        """
        subframe_data = subframe.data
        this_svid = subframe.svid
        this_gst = GalileoSystemTime(subframe.wn, subframe.tow)

        adkd0_authdata = self._get_ADKD0_data(subframe_data)
        adkd4_authdata = None

        self.add_nav_data(this_svid, this_gst, 0, adkd0_authdata)

        if insert_adkd12:
            self.add_nav_data(this_svid, this_gst, 12, adkd0_authdata)

        # ADKD=4 authdata uses words 6 and 10, but word 10 is not
        # present in every frame, in which case adkd4_authdata is
        # None
        if insert_adkd4:
            adkd4_authdata = self._get_ADKD4_data(subframe_data)
        if adkd4_authdata != None:
            self.add_nav_data(255, this_gst, 4, adkd4_authdata)

    def _get_halfpage(self, subframe: BitArray, page_idx: int, even: bool):
        """ An utility function to extract a given page from a subframe. Assumes we're reading the E1 band.
        :param subframe: The subframe in the same format as in process_subframe.
        :param page_ids: The index of the page we want
        :parem even: Whether we want the even or the odd page
        """
        even_page_size = 114
        odd_page_size = 120
        if even:
            return subframe[(even_page_size+odd_page_size) * page_idx : \
                            (even_page_size+odd_page_size) * page_idx + even_page_size]
        else:
            return subframe[(even_page_size+odd_page_size) * page_idx + even_page_size : \
                            (even_page_size+odd_page_size) * page_idx + even_page_size + odd_page_size]

    def _get_ADKD0_data(self, subframe):
        """ Get the data authenticated by the ADKD0 tag.
        :param subframe: The subframe in the same format as in process_subframe.
        """
        # Assumes we're reading the E1 band.
        # Extract words 1,2,3,4 and 5
        # See OSNMA ICD Annex B and SIS ICD Section 4.3.3
        word1 = self._get_halfpage(subframe, 10, True)[2:2+112] + self._get_halfpage(subframe, 10, False)[2:2+16]
        word2 = self._get_halfpage(subframe, 0, True)[2:2+112] + self._get_halfpage(subframe, 0, False)[2:2+16]
        word3 = self._get_halfpage(subframe, 11, True)[2:2+112] + self._get_halfpage(subframe, 11, False)[2:2+16]
        word4 = self._get_halfpage(subframe, 1, True)[2:2+112] + self._get_halfpage(subframe, 1, False)[2:2+16]
        word5 = self._get_halfpage(subframe, 12, True)[2:2+112] + self._get_halfpage(subframe, 12, False)[2:2+16]

        authdata = BitArray()
        authdata.append(word1[6 : 6 +10+14+32+32+32])
        authdata.append(word2[6 : 6 +10+32+32+32+14])
        authdata.append(word3[6 : 6 +10+24+16+16+16+16+16+8])
        authdata.append(word4[6 : 6 +10+6+16+16+14+31+21+6])
        authdata.append(word5[6 : 6 +11+11+14+1+1+1+1+1+10+10+2+2+1+1])

        assert(len(authdata) == 549)

        return authdata

    def _get_ADKD4_data(self, subframe, old_icd=False):
        word6 = self._get_halfpage(subframe, 2, True)[2:2+112] + self._get_halfpage(subframe, 2, False)[2:2+16]
        word10 = self._get_halfpage(subframe, 4, True)[2:2+112] + self._get_halfpage(subframe, 4, False)[2:2+16]

        # Word 10 position can contain either word 8 or 10, check the type
        pagetype = word10[:6].uint
        if pagetype != 10:
            return None

        authdata = BitArray()

        # Older ICDs use a different slightly different data for ADKD=4
        if old_icd:
            authdata.append(word6[6 : 6+32+24+8+8+8+8+3+8+20])
            authdata.append(word10[6+4+16+11+16+16+13+2+2 : 6+4+16+11+16+16+13+2+2 + 16+12+8+6])
            assert(len(authdata) == 161)
            return authdata

        authdata.append(word6[6 : 6+32+24+8+8+8+8+3+8])
        authdata.append(word10[6+4+16+11+16+16+13+2+2 : 6+4+16+11+16+16+13+2+2 + 16+12+8+6])
        assert(len(authdata) == 141)
        return authdata

    def _get_dummy_navdata(self, adkd):
        """Get a dummy navdata.

        :adkd: ADKD type
        :returns: BitArray full of zeros with the correct length

        """
        if adkd == 4:
            return BitArray('0'*141)
        return BitArray('0'*549)
