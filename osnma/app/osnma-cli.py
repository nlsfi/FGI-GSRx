#!/usr/bin/env python3
import sys

sys.path.insert(0, '..')


import argparse
from bitstring import BitArray

from datasource.sbf.sbfparser import SbfBlockFactory
from datasource.sources import SourceException, Source
from osnma.navdata import SubframeFactory
from osnma.engine import OsnmaEngine
from datasource.pagereader import PageReader
from crypto.merkletree import MerkleTree

DESCRIPTION="""
Command line interface for Galileo OSNMA processing.
"""
INPUT_DESCRIPTION="""
Input configuration. Examples:
filepath                - Reads data from the given filepath
file:filepath           - Same as above, only more explicit
serial:dev:baudrate     - Read from a serial device
net:ip:port             - Read data from the network

If the option is not specified, stdin will be used.
"""
HASH_ITERATION_LIMIT_DESCRIPTION = """
Set a limit for the number of hash iterations when verifying new keys. This is
usually not needed, but can be useful if faulty timestamps can be expected, as
faulty timestamps can result in arbitrary number of hash iterations that can
take a very long time.  This should still be high enough to allow iteration
from the first received TESLA key to the root key.
"""

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=DESCRIPTION,
                                     formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("-i", "--input", type=str,
                        help=INPUT_DESCRIPTION)
    parser.add_argument("-p", "--protocol", type=str,
                        choices=['sbf', 'ascii'], default='sbf',
                        help="Protocol/format of the input, such as SBF")
    parser.add_argument("-k", "--public-key-path", type=str, required=True,
                        help="Path to public key file (pem)")
    parser.add_argument("-r", "--root-key-path", type=str,
                        help="Path to the TESLA root key")
    parser.add_argument("-m", "--merkle-tree", type=str,
                        help="Path to the Merkle tree file")
    parser.add_argument("-g", "--allow-gaps", action="store_true",
                        help="Allow gaps in the subframes")
    parser.add_argument("-s", "--save-kroot", action="store_true",
                        help="Store the received KROOT for later use")
    parser.add_argument("-l", "--hash-iteration-limit", type=int,
                        help=HASH_ITERATION_LIMIT_DESCRIPTION)
    args = parser.parse_args()


    source = Source.from_string(args.input)
    reader = PageReader.create(source, args.protocol)

    sf_factory = SubframeFactory(reader, args.allow_gaps)
    public_key = open(args.public_key_path).read()
    osnma = OsnmaEngine(public_key)

    if args.save_kroot:
        osnma.save_kroot = True

    # Hot start
    if args.root_key_path:
        with open(args.root_key_path, 'r') as f:
            kroot_bits = BitArray(hex=f.readline().rstrip())
            dsm_kroot = osnma.decoder.parse_dsm_kroot_message(kroot_bits)
            osnma.input_dsm_kroot(dsm_kroot)

    # Merkle tree for public key verification
    if args.merkle_tree:
        merkle_tree = MerkleTree.from_file(args.merkle_tree)
        osnma.authenticator.merkle_tree = merkle_tree

    if args.hash_iteration_limit:
        osnma.authenticator.key_iteration_limit = args.hash_iteration_limit

    try:
        while True:
            subframe = sf_factory.read()
            if subframe == None:
                continue
            osnma.process_subframe(subframe)
    except SourceException as e:
        print(e, file=sys.stderr)
    except SbfBlockFactory.InvalidBlockException as e:
        print(e, file=sys.stderr)
    except KeyboardInterrupt:
        pass
