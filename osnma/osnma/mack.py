from bitstring import BitArray
from dataclasses import dataclass

from util.gst import GalileoSystemTime

'''
Classes for MACK related data structures.
'''

@dataclass
class MackHeader:
    raw_bits: BitArray # All data in the header in raw bits
    tag0: BitArray # The authentication tag for ADKD=0 of the satellite transmitting this message
    macseq: BitArray
    cop: int

@dataclass
class TagInfo:
    raw_bits: BitArray # All data in the message in raw bits
    prnd: int # The id of the satellite transmitting the bits that this tag authenticates
    adkd: int # Authentication data and key delay. Described which data is being authenticated and how long the TESLA key delay is

@dataclass
class TagsAndInfo:
    """Tags and info field from a MACK data section.

    :tag_list: list of BitArray objects representing the tags
    :info_list: list of TagInfo objects
    """
    raw_bits: BitArray
    tag_list: list
    info_list: list

@dataclass
class TeslaKey:
    """TESLA key with the associated GST timestamp"""
    key: BitArray
    time: GalileoSystemTime

@dataclass
class Mack:
    """Data parsed from a MACK message"""
    mack_header: MackHeader
    tags_and_info: TagsAndInfo
    tesla_key: TeslaKey

    def get_gst(self):
        """Get the GST corresponding to the MACK.
        :returns: GST

        """
        # The time of the MACK is the same as its TESLA key time
        return self.tesla_key.time
