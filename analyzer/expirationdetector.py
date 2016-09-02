import psycopg2
import threading
import logging

class ExpirationDetector(threading.Thread):

    def __init__(self, dbname, dbuser, dbhost):
        threading.Thread.__init__(self)
        self.newly_expired_counter = 0
        self.dbname = dbname
        self.dbuser = dbuser
        self.dbhost = dbhost
        self.db = None
        self.logger = logging.getLogger(__name__)
        
    def run(self):
        self.db = psycopg2.connect(dbname=self.dbname, user=self.dbuser, host=self.dbhost)
        self.update_expired_flag()
        self.db.close()

    def update_expired_flag(self):
        cursor = self.db.cursor()
        
        self.logger.debug("Counting certificates...")
        cursor.execute("SELECT COUNT(*) FROM certificate")
        count = cursor.fetchone()[0]
        self.logger.debug("{0} certificates found.".format(count))
        step = 100000
        
        for i in range(0, count+1, step):
            cursor.execute("UPDATE certificate SET EXPIRED=TRUE WHERE ((x509_notAfter(CERTIFICATE) < NOW() ) AND EXPIRED=FALSE) AND id > %s AND id < %s", (i, i+step))
            self.newly_expired_counter += cursor.rowcount
            self.db.commit()
            self.logger.debug("Handled {0}/{1} certificates ({2:.2f} %), found {3} newly expired".format(i+step, count, float(i+step)/float(count)*100, self.newly_expired_counter))

        self.logger.info(self.print_log())

    def print_log(self):
        return "{{'type':'expired','data':{{'new':{} }} }},".format(self.newly_expired_counter)
