import sys
import socket
from abc import abstractmethod

class OutputStream:
    """Abstract class for writing data (subframe reports etc) to some
    output (file, tcp, etc)."""

    @abstractmethod
    def write(self, data):
        """Write data to some output.

        :data: data to write to output stream
        :returns: nothing
        """

class FileOutput(OutputStream):
    """Output reports to a file (default: stdout). The specified file can be
    either a filename, in which case the file is opened for writing, or it can
    be a already open file descriptor."""

    def __init__(self, file=sys.stdout):
        # Open file for writing in case of a string argument.
        if isinstance(file, str):
            self.file = open(file, "w")
        else:
            self.file = file

    def write(self, data):
        """Print data to self.file

        :data: data to print
        :returns: nothing

        """
        print(data, file=self.file)

class NetworkOutput(OutputStream):
    """TCP outputter"""

    def __init__(self, host="localhost", port=3001, tcp=True):
        self.host = host
        self.port = port
        self.connected = False
        if tcp:
            self.output_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        else:
            self.output_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

        try:
            self.output_socket.connect((host, port))
            self.connected = True
        except socket.error as e:
            print(f"Unable to connect to {host}:{port}")
        
    def write(self, data: str):
        """ Send data to TCP output.

        :data: data to send, in string format
        :returns: nothing

        """
        try:
            if self.connected:
                self.output_socket.send(bytes(data + "\n", 'utf-8'))
        except:
            self.connected = False
