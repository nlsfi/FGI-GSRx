import hashlib
import re
from bitstring import BitArray

from osnma.dsm import DsmPkrMessage

'''
Minimal Merkle tree implementation for OSNMA.
'''

class MerkleTree:
    def __init__(self, root: BitArray):
        '''
        Initialize the Merkle tree by giving the Merkle tree root as BitArray
        '''
        self.root = root

    @staticmethod
    def from_file(filename):
        """Initialize a merkle tree by giving a file containing the Merkle tree
        information. The expected file format is the xml that the official
        Merkle tree comes in.

        :filename: filepath containing the Merkle tree
        :returns: corresponding MerkleTree object

        """
        pattern = re.compile(r'<TreeNode><j>4</j><i>0</i><lengthInBits>256</lengthInBits><x_ji>(.*)</x_ji></TreeNode>')
        with open(filename, 'r') as f:
            content = f.readline()
            m = pattern.match(content)

            if m:
                root = BitArray(hex=m.group(1))
                return MerkleTree(root)
            else:
                print("Unable to parse the Merkle tree root from file")
        

    def validate_public_key(self, pkr: DsmPkrMessage):
        """Validate public key by hashing towards the Merkle tree root.

        :pkr: DSM-PKR message, which contains all of the needed information
        (except for the Merkle tree root) for the verification.

        :returns: True, if the public key is vefied successfully.

        """
        msg = pkr.new_public_key_type + pkr.new_public_key_id + pkr.new_public_key
        mid = pkr.message_id
        itn = pkr.intermediate_tree_nodes

        result = hashlib.sha256(msg.bytes).digest()

        # To get the parent node, the two child nodes (result, node) need to be
        # concatenated and hashed. The order of the concatenation at each steps
        # depend on the public key id. The bit representation determines this.
        # For example in public key id 0='0000' the result will be the left
        # node at all steps, while in id 7='0111' the result will be the right
        # node in the first three steps and the left node in the last step.
        for i, bit in enumerate(mid[::-1]):
            start = i*256
            stop = (i + 1)*256
            node = itn[start:stop].bytes

            # When the bit is 0 the result is the left child node
            if bit:
                result = hashlib.sha256(node + result).digest()
            else:
                result = hashlib.sha256(result + node).digest()

        return result == self.root.bytes
