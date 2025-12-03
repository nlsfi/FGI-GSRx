# To write straight into a DB
import psycopg2 as pg
import util.gst as gst

QUERY = '''
insert into authentication_events(timestamp, prnd, prna, adkd, status)
values (to_timestamp(%s), %s, %s, %s, %s)'''

class EventHandler:
    """Write the authentication events to a database. Test for GF, not meant to be commited.
    """
    def __init__(self):
        self.connection = pg.connect(host='172.17.0.2', user='postgres', dbname='postgres')
        self.columns = ["timestamp", "prnd", "prna", "adkd", "status"]
        self.table = "authentication_events"

        self.connection.autocommit = True
        self.cursor = self.connection.cursor()
        pass

    def handle_event(self, event):
        event.print()

    # Will be only called for the subframe report
    def handle_events(self, events):
        for event in events:
            prnd = event.svid if event.svid != None else -1
            prna = event.prna if event.prna != None else -1
            ts = gst.gst2timestamp(event.wn, event.tow)
            adkd = event.adkd
            status = event.event.name.capitalize().replace("_", " ")
            print(ts, prnd, prna, adkd, status)
            try:
                self.cursor.execute(QUERY, (ts, prnd, prna, adkd, status))
            except Exception as e:
                print(e)
                self.connection.rollback()

        self.connection.commit()
