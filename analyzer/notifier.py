import psycopg2


class Notifier:
    def __init__(self, db):
        self.db = db
        self.notified = 0
    def initialize(self):
        cursor = self.db.cursor()
        cursor.execute("SELECT value from certificate_analysis where type='notifier_last_cert_id'")
        if len(cursor.fetchall()) == 0:
            cursor.execute("INSERT INTO certificate_analysis (type,value) VALUES ('notifier_last_cert_id',(SELECT max(id) from certificate))")

    def notify(self):
        cursor = self.db.cursor()

        self.initialize()

        cursor.execute("select CASE when ne.notify_for=0 or (ne.notify_for=1 and ci.name_type='dNSName') or (ne.notify_for=2 and ci.name_type='commonName') then true else false end as notify,  ne.email, ndn.name, ci.name_type, ca.name, x509_notBefore(c.certificate)  from notification_email ne inner join notification_dns_names ndn on ne.notification_dns_names_id = ndn.id inner join certificate_identity ci on ndn.name=ci.name_value and (ci.name_type='commonName' or ci.name_type='dNSName') inner join certificate c on ci.certificate_id = c.id inner join ca on ci.issuer_ca_id = ca.id WHERE ne.validated AND ne.active AND c.id > (SELECT value from certificate_analysis where type='notifier_last_cert_id'); ")

        for notify in cursor.fetchall():
            print(notify,"JAAA")

        self.db.commit()

        return self.print_log()

    def print_log(self):
        return "{{'type':'notifier', 'data':{{ }},".format()