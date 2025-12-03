from datetime import datetime
from bitstring import BitArray

from osnma.navdata import InavPage
from datasource.sources import SourceException
from datasource.sbf.sbfparser import SbfBlockFactory, GalRawINavBlock

class PageReader:
    """Class for reading navigation pages and returning InavPage objects.
    """
    @staticmethod
    def create(source, protocol):
        """Create a PageReader given the source and the protocol.

        :source: the source from which the data is read from
        :protocol: String specifying the type of the reader
        :returns: PageReader subclass for reading the specified data

        """
        if protocol == 'ascii':
            return AsciiPageReader(source)
        return SbfPageReader(source)

    def read(self):
        '''Read a Galileo INAV page from some source. Abstract.
        '''
        pass

class SbfPageReader(PageReader):
    """Read SBF files and construct InavPage object from the GalRawInav blocks."""
    def __init__(self, source):
        self.source = source
        self.bf = SbfBlockFactory(source)
        self.bf.registerBlock(GalRawINavBlock)

    def read(self):
        """Read an SBF GalRawInavBlock and convert it to InavPage, which is
        returned.

        :returns: InavPage with the equivalent data

        """
        block, arrival_dt = self.bf.read()
        page = block.to_inav_page(arrival_dt)
        return page

class AsciiPageReader(PageReader):
    """Class for producing InavPages from ASCII input. Format is expected to be
    ASCII lines with format: svid, wn, tow, navigation_page_in_hex
    The delimiter can be set, and the file descriptor 'fd' can be anything with
    the method 'readline'. Therefore it can be for example an open file
    descriptor (opened with 'open'), 'sys.stdin', or a 'FileSource'.

    We mostly use the "SBF-format" where the 6 zero-bits between the even and
    odd page are removed. Septentrio for example gives the pages already in
    this format so they do not need to be removed. In case your navigation bits
    have length 240, set 'remove_middle_6_bits' to True.

    'line_is_bytes' specifies whether the lines read from the self.fd are
    coming as bytes as opposed to strings. Even if it is a ASCII file, this
    might be the case if it was opened in mode 'rb'.
    """
    def __init__(self, fd, delimiter=",", remove_middle_6_bits=True, line_is_bytes=True):
        self.fd = fd
        self.delimiter = delimiter
        self.remove_middle_6_bits = remove_middle_6_bits
        self.line_is_bytes = line_is_bytes

    def read(self):
        """Read the next line from the input
        :returns: InavPage parsed from the input

        """
        line = self.fd.readline()
        if self.line_is_bytes:
            line = line.decode()

        if not line:
            raise SourceException('EOF reached.')

        t = line.rstrip().split(self.delimiter)
        svid = int(t[0])
        wn = int(t[1])
        tow = int(t[2])
        page = BitArray(hex=t[3])

        navbits = BitArray()
        if self.remove_middle_6_bits:
            evenpage = page[:114]
            oddpage = page[120:240]
            navbits.append(evenpage)
            navbits.append(oddpage)
        else:
            navbits = page[:234]

        return InavPage(wn, tow, svid, navbits, datetime.now())
