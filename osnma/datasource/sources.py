import sys
import time
import serial
import socket

class SourceException(Exception):
    pass

class FileSource:
    """Encapsulates the details of reading from a file"""

    def __init__(self, filepath=None, mode='rb'):
        if not filepath:
            print("No source specification given: reading from stdin")
            self.file = sys.stdin
        else:
            self.file = open(filepath, mode)

    def read(self, nbytes):
        bytes_chunk = self.file.read(nbytes)
        if len(bytes_chunk) != nbytes:
            raise SourceException('EOF reached.')
        return bytes_chunk

    def readline(self):
        line = self.file.readline()
        if not line:
            raise SourceException('EOF reached.')
        return line

    def flush(self):
        pass

    def close(self):
        self.file.close()

    def __del__(self):
        self.close()

class SerialPortSource(serial.Serial):
    """Encapsulates the details of reading from a serial port"""

    class SerialPortSourceException(SourceException):
        pass

    def __init__(self, dev, baudrate):
        super().__init__(dev, baudrate)
        time.sleep(0.5)  # Allow for the port to really open
        if not self.isOpen():
            raise SerialPortSource.SerialPortSourceException('Could not open serial port.')

    def flushInput(self):
        """Reads all the input discarding its contents"""
        self.read_all()  # This was necessary. Otherwise there were leftover bytes, maybe coming from the receiver's send buffer?
        #self.reset_input_buffer() #This did not work as expected!

class NetSource:
    """Encapsulates the details of reading from a network source"""
    def __init__(self, ip, port, protocol=socket.SOCK_STREAM):
        self.sock = socket.socket(socket.AF_INET, protocol)
        self.sock.bind((ip, port))

    def read(self, nbytes):
        data = self.sock.recv(nbytes)
        return data

class SerialPortDumperSource(SerialPortSource):
    def __init__(self, dev, baudrate, filepath):
        super().__init__(dev, baudrate)
        self.file = open(filepath, 'wb')

    def close(self):
        super().close()
        self.file.close()

    def read(self,nbytes):
        s = super().read(nbytes)
        self.file.write(s)
        return s

class BufferedSerialPortDumperSource(SerialPortSource):
    def __init__(self, dev, baudrate):
        super().__init__(dev, baudrate)
        self.buffer = bytearray()

    def read(self, nbytes):
        s = super().read(nbytes)
        self.buffer.extend(s)
        return s

    def dump(self,filepath):
        file = open(filepath, 'wb')
        file.write(self.buffer)
        file.close()

# TODO: filepaths containing : will cause issues
class Source:

    @staticmethod
    def from_string(string=None):
        """Instantiates a Source object from a string. If an empty argument is
        given, the source the default FileSource() (reading from stdin).

        Example strings:
        - file:filepath
        - serial:dev:baudrate
        """
        if not string:
            return FileSource()

        tok = string.split(':')

        # Read from a filepath by default
        if len(tok) == 1:
            return FileSource(tok[0])

        input_type = tok[0]

        if input_type == 'file':
            filepath = tok[1]
            return FileSource(filepath)
        elif input_type == 'serial':
            if len(tok) != 3:
                raise Exception("Invalid SerialPortSource instantiation string")
            dev = tok[1]
            baudrate = tok[2]
            return SerialPortSource(dev, baudrate)
        elif input_type == 'net':
            if len(tok) != 3:
                raise Exception("Invalid NetSource instantiation string")
            ip = tok[1]
            port = tok[2]
            return NetSource(ip, port)
        else:
            raise Exception("Invalid type for a Source")
