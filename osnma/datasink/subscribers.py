from collections import defaultdict

from datasink.output import OutputStream, FileOutput

class Subscriber:
    """Abstract class that defines via what callback functions upper layers can
    receive info from the OsnmaDecoder class."""

    def on_subframe_report_received(self, outcomes):
        pass

    def on_osnma_exception_received(self, exception):
        pass

    def on_info_received(self, info_string):
        pass

class PrintSubscriber(Subscriber):
    """Default implementation of the Subscriber class that prints all the
    information to the specified output stream (default: stdout)
    """

    def __init__(self, verbose=1, ostream=None):
        self.verbose_mode = verbose
        if ostream == None:
            self.ostream = FileOutput()
        else:
            self.ostream = ostream

    def on_subframe_report_received(self, outcomes):
        """Report (i.e. write to ostream) authentication status for all
        navigation data received at a subframe.

        :outcomes: list of AuthAttempt objects
        :returns: nothing

        """
        for outcome in outcomes:
            self.ostream.write(outcome)

    def on_info_received(self, info):
        """Print the info when received

        :info: received info to print
        :returns: nothing

        """
        self.ostream.write(info)

    def on_osnma_exception_received(self, exception):
        """Print the exception when received

        :exception: received exception to print
        :returns: nothing

        """
        self.ostream.write(exception)

class AuthReportWriter(Subscriber):
    """Write the information from the authentication attempts to a file"""

    def __init__(self, file=None, sep=" "):
        self.ostream = FileOutput(file)
        self.sep = sep

        # Header to the file
        self.ostream.write(self.sep.join(["PRND", "PRNA", "WN", "TOW", "ADKD", "Outcome"]))

    def stringify_outcome(self, outcome):
        """Take an AuthOutcome object and make a clear, printable string of it.

        :outcome: AuthAttempt object. Has information PRND, PRNA, wn, tow, ADKD, and
        authentication outcome
        :returns: nothing, but the result is written to self.ostream
        """
        prnd = str(outcome.PRND) if outcome.PRND != None else "-1"
        prna = str(outcome.PRNA) if outcome.PRNA != None else "-1"
        wn = str(outcome.wn)
        tow = str(outcome.tow)
        adkd = str(outcome.adkd)
        status = str(outcome.outcome.value)

        output = self.sep.join([prnd, prna, wn, tow, adkd, status])
        return output

    def on_subframe_report_received(self, outcomes):
        """Report authentication status for all navigation data received at a
        subframe. Write it into a csv-like file with a header. The separator is
        specified in the class.

        :outcomes: list of AuthAttempt objects
        :returns: nothing
        """
        for outcome in outcomes:
            self.ostream.write(self.stringify_outcome(outcome))

class SubscriberSystem:
    """SubscriberSystem: collection of subscribers"""
    def __init__(self):
        self.subscribers = []

    def register_subscriber(self, subscriber: Subscriber):
        """Add a subscriber to the list

        :subscriber: Subscriber to register
        :returns: nothing
        """
        self.subscribers.append(subscriber)

    def send_subframe_report(self, outcomes):
        for sub in self.subscribers:
            sub.on_subframe_report_received(outcomes)

    def send_osnma_exception(self, exception):
        for sub in self.subscribers:
            sub.on_osnma_exception_received(exception)

    def send_info(self, info_string):
        for sub in self.subscribers:
            sub.on_info_received(info_string)
