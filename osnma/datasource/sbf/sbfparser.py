"""
Septentrio binary file (SBF) format parser.

References:
    [1]- mosaic-X5 Reference Guide
"""
from datetime import datetime, timezone
from crccheck.crc import Crc16

import struct

from bitstring import BitArray
from util.gst import GalileoSystemTime
from osnma.navdata import InavPage
from datasink.events import SatelliteEvent, Events

class RawSbfBlock():
    """ Container of a SBF block (header + block body).
    """
    SYNC = bytes.fromhex("24 40")

    def __init__(self, rev_nr, blk_nr, tow, wnc, block_body_rem):
        self.rev_nr = rev_nr
        self.blk_nr = blk_nr
        self.tow = tow
        self.wnc = wnc
        self.block_body_rem = block_body_rem  # Reminder of the block body after tow and wnc


class SbfBlockBase:
    """ Base class for all SBF block classes to inherit.
    Note that the blk_nr is not a property in this class, since it is already a class property of subclasses.
    """
    TOW_DO_NOT_USE_VAL = 4294967295
    WNC_DO_NOT_USE_VAL = 65535

    def __init__(self, rev_nr, tow, wnc):
        self.rev_nr = rev_nr
        self.tow = tow
        self.wnc = wnc

    def isTowValid(self):
        """ Determines whether the TOW field is usable or not"""
        return self.tow != SbfBlockBase.TOW_DO_NOT_USE_VAL

    def isWnValid(self):
        """ Determines whether the WN field is usable or not"""
        return self.wnc != SbfBlockBase.WNC_DO_NOT_USE_VAL

class GalAuthStatusBlock(SbfBlockBase):
    """Class for Septentrio GALAuthStatus blocks"""
    BLK_NR = 4245
    OSNMA_STATUS = {
        0: 'Disabled',
        1: 'Initializing',
        2: 'Waiting on NTP',
        3: 'Init failed - inconsistent time',
        4: 'Init failed - KROOT signature invalid',
        5: 'Init failed - invalid param received',
        6: 'Authenticating',
    }

    def __init__(self, rev_nr, tow, wnc, osnma_status, osnma_init_progress, trusted_time_delta, gal_active_mask, gal_authentic_mask, gps_active_mask, gps_authentic_mask):
        SbfBlockBase.__init__(self, rev_nr, tow, wnc)
        self.osnma_status = osnma_status
        self.trusted_time_delta = trusted_time_delta
        self.gal_active_mask = gal_active_mask
        self.gal_authentic_mask = gal_authentic_mask
        self.gps_active_mask = gps_active_mask
        self.gps_authentic_mask = gps_authentic_mask

    @staticmethod
    def FromRawBlock(rawBlk):
        """Instantiate a GalAuthStatusBlock object from a SbfRawBlock

        :rawBlk: RawSbfBlock object
        :returns: parsed GALAuthStatusBlock object

        """
        # Total length: 2 + 4 + 8 + 8 + 8 + 8 + x = 38 content bytes + x padding bytes
        osnma_status_uint = struct.unpack('<H', rawBlk.block_body_rem[0:2])[0]
        osnma_status = GalAuthStatusBlock.OSNMA_STATUS[osnma_status_uint & 0x07]
        osnma_init_progress = osnma_status_uint & 0x07f8
        trusted_time_delta = struct.unpack('<f', rawBlk.block_body_rem[2:6])
        gal_active_mask = rawBlk.block_body_rem[6:14]
        gal_authentic_mask = rawBlk.block_body_rem[14:22]
        gps_active_mask = rawBlk.block_body_rem[22:30]
        gps_authentic_mask = rawBlk.block_body_rem[30:38]
        return GalAuthStatusBlock(rawBlk.rev_nr, rawBlk.tow, rawBlk.wnc, osnma_status, osnma_init_progress, trusted_time_delta, gal_active_mask, gal_authentic_mask, gps_active_mask, gps_authentic_mask)


class GalRawINavBlock(SbfBlockBase):
    BLK_NR = 4023
    SVID_DO_NOT_USE_VAL = 0
    SIGNAL_TYPES = {  # See [Sec. 4.1.10,1]
        17: 'E1',
        19: 'E6',
        20: 'E5a',
        21: 'E5b',
        22: 'E5AltBoc'
    }

    def __init__(self, rev_nr, tow, wnc, sv_id, crc_passed, viterbi_cnt, signal_type, from_e5b_e1, freq_nr, rx_channel,
                 nav_bits):
        SbfBlockBase.__init__(self, rev_nr, tow, wnc)
        self.sv_id = sv_id
        self.crc_passed = crc_passed
        self.viterbi_cnt = viterbi_cnt
        self.signal_type = signal_type
        self.from_e5b_e1 = from_e5b_e1
        self.freqnr = freq_nr
        self.rx_channel = rx_channel
        self.nav_bits = nav_bits

    def to_inav_page(self, arrival_dt=None):
        """Convert the SBF GalRawInavBlock to a InavPage object. If the signal
        type is not E1 or the CRC is not passed, or if it contains invalid
        values, return None.

        :returns: InavPage, or None

        """
        # Section 4.1.3 of the mosaic-X5 reference guide says that Galileo
        # system time is wnc minus 1024. The tow is converted to seconds.
        tow = self.tow // 1000
        wn = self.wnc - 1024

        # Conditions under which the block is invalid and None will be returned.
        if self.signal_type != "E1":
            return None
        if self.crc_passed == 0:
            SatelliteEvent(wn, tow, Events.CRC_ERROR, self.sv_id).print()
            return None
        # See SBF do not use values
        if not (tow >= 0 and tow <= 604799):
            return None
        if not (wn >= 0 and wn <= 4096):
            return None

        # The tow is the end of the first page in a subframe. A page takes 2
        # seconds, so we need to subtract 2 seconds to get the time at the
        # start of the page. Additionally section 6.4. of the ICD says that we
        # need to subtract one more second. So in total, we subtract three
        # seconds.
        gst = GalileoSystemTime(wn, tow)
        gst.subtract_seconds(3)

        # Unpack the bits into a BitArray
        bits = BitArray()
        for i in range(8):
            bits.append('uintbe:32=' + str(self.nav_bits[i]))

        evenpage = bits[0 : 120 - 6]
        oddpage = bits[120 - 6 : 120 - 6 + 120]
        navbits = evenpage + oddpage

        return InavPage(gst.wn, gst.tow, self.sv_id, navbits, arrival_dt=arrival_dt)

    @staticmethod
    def FromRawBlock(rawBlk):
        """Instantiates a GalRawINavBlock object from a SbfRawBlock"""
        sv_id = rawBlk.block_body_rem[0] - 70  # See [Sec. 4.1.9, 1], p. 242-242.
        crc_passed = rawBlk.block_body_rem[1]
        viterbi_cnt = rawBlk.block_body_rem[2]
        source = rawBlk.block_body_rem[3]
        st_key = source & 0x1F  # bits 0-4
        signal_type = GalRawINavBlock.SIGNAL_TYPES[st_key]
        from_e5b_e1 = source & 0x20  # bit 5
        freq_nr = rawBlk.block_body_rem[4]
        rx_channel = rawBlk.block_body_rem[5]
        nav_bits = []
        for i in range(8):
            nav_bits.append(int.from_bytes(rawBlk.block_body_rem[6 + i * 4: 6 + i * 4 + 4], byteorder='little'))
        return GalRawINavBlock(rawBlk.rev_nr, rawBlk.tow, rawBlk.wnc,
                               sv_id, crc_passed, viterbi_cnt, signal_type, from_e5b_e1, freq_nr, rx_channel, nav_bits)


class PvtGeodeticBlock(SbfBlockBase):
    BLK_NR = 4007
    FLOAT_DO_NOT_USE_VAL = -2 * 10 ^ 10

    def __init__(self,
                 rev_nr, tow, wnc, mode, error, lat, lon, height, undulation, v_n, v_e, v_u, cog, rx_clk_bias,
                 rx_clk_drift, time_system, datum, nr_sv, wa_corr_info, rf_id, mean_corr_age, signal_info, alert_flag,
                 nr_bases, ppp_info, latency, h_accuracy, v_accuracy, misc):
        SbfBlockBase.__init__(self, rev_nr, tow, wnc)
        self.mode = mode
        self.error = error
        self.lat = lat
        self.lon = lon
        self.height = height
        self.undulation = undulation
        self.v_n = v_n
        self.v_e = v_e
        self.v_u = v_u
        self.cog = cog
        self.rx_clk_bias = rx_clk_bias
        self.rx_clk_drift = rx_clk_drift
        self.time_system = time_system
        self.datum = datum
        self.nr_sv = nr_sv
        self.wa_corr_info = wa_corr_info
        self.rf_id = rf_id
        self.mean_corr_age = mean_corr_age
        self.signal_info = signal_info
        self.alert_flag = alert_flag
        self.nr_bases = nr_bases
        self.ppp_info = ppp_info
        self.latency = latency
        self.h_accuracy = h_accuracy
        self.v_accuracy = v_accuracy
        self.misc = misc

    @staticmethod
    def FromRawBlock(rawBlk):
        """Instantiates a PvtGeodeticBlock object from a SbfRawBlock"""
        mode = rawBlk.block_body_rem[0]  # u1
        error = rawBlk.block_body_rem[1]  # u1
        lat = struct.unpack('<d', rawBlk.block_body_rem[2:10])[0]  # f8, units of 1 rad
        lon = struct.unpack('<d', rawBlk.block_body_rem[10:18])[0]  # f8, units of 1 rad
        height = struct.unpack('<d', rawBlk.block_body_rem[18:26])[0]  # f8, units of 1 m
        undulation = struct.unpack('<f', rawBlk.block_body_rem[26:30])[0]  # f4, units of 1 m
        v_n = struct.unpack('<f', rawBlk.block_body_rem[30:34])[0]  # f4, units of 1 m/s
        v_e = struct.unpack('<f', rawBlk.block_body_rem[34:38])[0]  # f4, units of 1 m/s
        v_u = struct.unpack('<f', rawBlk.block_body_rem[38:42])[0]  # f4, units of 1 m/s
        cog = struct.unpack('<f', rawBlk.block_body_rem[42:46])[0]  # f4, units of 1 degree
        rx_clk_bias = struct.unpack('<d', rawBlk.block_body_rem[46:54])[0]  # f8, units of 1 ms
        rx_clk_drift = struct.unpack('<f', rawBlk.block_body_rem[54:58])[0]  # f4, units of 1 ppm
        time_system = rawBlk.block_body_rem[58]  # u1
        datum = rawBlk.block_body_rem[59]  # u1
        nr_sv = rawBlk.block_body_rem[60]  # u1
        wa_corr_info = rawBlk.block_body_rem[61]  # u1
        rf_id = int.from_bytes(rawBlk.block_body_rem[62:64], byteorder='little', signed=False)  # u2
        mean_corr_age = int.from_bytes(rawBlk.block_body_rem[64:66], byteorder='little', signed=False)  # u2, units of 0.01 s
        signal_info = int.from_bytes(rawBlk.block_body_rem[66:70], byteorder='little', signed=False)  # u4
        alert_flag = rawBlk.block_body_rem[70]  # u1
        # Rev1
        nr_bases = rawBlk.block_body_rem[71]  # u1
        ppp_info = int.from_bytes(rawBlk.block_body_rem[72:74], byteorder='little', signed=False)  # u2, units of 1 s
        # Rev2
        latency = int.from_bytes(rawBlk.block_body_rem[74:76], byteorder='little', signed=False)  # u2, units of 0.0001 s
        h_accuracy = int.from_bytes(rawBlk.block_body_rem[76:78], byteorder='little', signed=False)  # u2, units of 0.01 m
        v_accuracy = int.from_bytes(rawBlk.block_body_rem[78:80], byteorder='little', signed=False)  # u2, units of 0.01 m
        misc = rawBlk.block_body_rem[80]  # u1

        return PvtGeodeticBlock(rawBlk.rev_nr, rawBlk.tow, rawBlk.wnc,
                                mode, error, lat, lon, height, undulation, v_n, v_e, v_u, cog, rx_clk_bias,
                                rx_clk_drift, time_system, datum, nr_sv, wa_corr_info, rf_id, mean_corr_age, signal_info,
                                alert_flag, nr_bases, ppp_info, latency, h_accuracy, v_accuracy, misc)

class SbfBlockFactory:
    """Instantiates SBF blocks (children of SbfBlock) retrieving the content from the given source.

    A source can be anything from which bytes can be read, such as a serial port, a file, etc. Sources are represented
    by a class with a read(nbytes) method
    """

    class InvalidBlockException(Exception):
        pass

    def __init__(self, source):
        self.source = source
        self.registeredBlocks = {}

    def registerBlock(self, blk):
        """    At the moment only GalRawINavBlock and PvtGeodeticBlock objects can be registered and instantiated."""
        if not issubclass(blk, SbfBlockBase):
            raise SbfBlockFactory.InvalidBlockException('Invalid block.')
        self.registeredBlocks[blk.BLK_NR] = blk

    def read(self):
        while True:
            rawBlk, arrival_dt = SbfBlockFactory.ReadRawBlock(self.source)
            # Instantiate the appropriate block type.
            if rawBlk.blk_nr in self.registeredBlocks.keys():
                blockClass = self.registeredBlocks[rawBlk.blk_nr]
                block = blockClass.FromRawBlock(rawBlk)
                break
        return block, arrival_dt

    @staticmethod
    def ReadRawBlock(source):
        """ Reads bytes from a source and returns the first SBF block found (an SbfRawBlock)

        A source in this context is an object encapsulating the details of how the data is obtained (e.g. from a serial
        port, a file, a buffer). It simply has to contain a read(nbytes) method

        The block decoding is implemented according to the recommended procedure in [Sec 4.1.12, 1]

        :source: an object with a read method where to read bytes.
        :return: an SbfBlock object
        """
        while True:
            arrival_dt = SbfBlockFactory.FindSync(source)
            crc = int.from_bytes(source.read(2), byteorder='little', signed=False)
            buffer = bytearray()
            buffer.extend(source.read(2))
            id = int.from_bytes(buffer[0:2], byteorder='little')
            rev_nr = (id & 0xE000) >> 12  # bits 13-15
            blk_nr = id & 0x1FFF  # bits 0-12
            buffer.extend(source.read(2))
            length = int.from_bytes(buffer[2:4], byteorder='little', signed=False)
            if not (length % 4 == 0):  # length must be a multiple of 4
                continue
            buffer.extend(source.read(length - 8))  # sync, CRC, ID and length fields (8 bytes) are already read
            crc_computed = Crc16.calc(bytes(buffer))
            if not (crc_computed == crc):
                continue
            block_body = buffer[4:]
            tow = int.from_bytes(block_body[0:4], 'little', signed=False)  # u4, units of 0.001s
            wnc = int.from_bytes(block_body[4:6], 'little', signed=False)  # u2, units of 1 week
            block_body_rem = block_body[6:]  # Reminder of the block body after tow and wnc
            return RawSbfBlock(rev_nr, blk_nr, tow, wnc, block_body_rem), arrival_dt

    @staticmethod
    def FindSync(reader):
        buffer = b""
        while True:
            buffer += reader.read(1)
            if buffer[-2:] == RawSbfBlock.SYNC:
                arrival_dt = datetime.now(timezone.utc)
                break
        return arrival_dt
