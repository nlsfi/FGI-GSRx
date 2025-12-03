from bitstring import BitArray
from dataclasses import dataclass
from enum import Enum

'''
Classes for DSM related data structures.
'''

@dataclass
class NmaHeader:
    '''Navigation message authentication header, which is part of the HKROOT
    messages.
    '''
    raw_bits: BitArray  # The header as raw bits
    nmas: str           # NMA status
    cid: str            # Chain id
    cpks: str           # Chain and public key status

class DsmMessageType(Enum):
    """Message type of the DSM-message. This is either 'kroot' for the
    DSM-KROOT message (used in initialization), or 'pkr' for the DSM-PKR
    message (used in public key renewal).
    """
    kroot = 0
    pkr = 1

@dataclass
class DsmHeader: 
    '''Digital signature message header. Part of the HKROOT message.
    '''
    raw_bits: BitArray      # The header as raw bits
    dsm_id: DsmMessageType  # Type of the header
    bid: int                # block ID, DSM messages consist of many blocks

@dataclass
class DsmKrootMessage: 
    raw_bits: BitArray          # The message as raw bits
    num_blocks: int             # Number of blocks in the message
    public_key_id: int
    kroot_cid: int              # KROOT Chain ID
    hash_function: str
    mac_funciton: str
    key_size: int
    tag_size: int
    mac_lt: int                 # Mac look-up table
    # Start time applicability: week number and time of week
    wn_kroot: int
    tow_kroot: int
    alpha: BitArray             # Hash salt
    root_key: BitArray
    digital_signature: BitArray # Digital signature of KROOT

@dataclass
class DsmPkrMessage: 
    '''Public key renewal message.

    Note that the message_id, new_public_key_type, new_public_key_id are
    actually uints, but the bit representation is required in some operations,
    hence they are encoded as BitArrays.
    '''
    raw_bits: BitArray
    num_blocks: int
    message_id: BitArray
    intermediate_tree_nodes: BitArray
    new_public_key_type: BitArray
    new_public_key_id: BitArray
    new_public_key: BitArray
