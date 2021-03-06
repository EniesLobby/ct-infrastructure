-- schema for use with monitorInPython.py
-- surplus tables and columns have been removed

CREATE TABLE ca (
	ID				serial,
	COUNTRY_NAME			text,
	STATE_OR_PROVINCE_NAME		text,
	LOCALITY_NAME			text,
	ORGANIZATION_NAME		text,
	ORGANIZATIONAL_UNIT_NAME	text,
	COMMON_NAME			text,
	EMAIL_ADDRESS			text,
	PUBLIC_KEY		        bytea	NOT NULL,
	
	CONSTRAINT ca_pk
		PRIMARY KEY (ID)
);

CREATE UNIQUE INDEX ca_uniq
	ON ca (COMMON_NAME text_pattern_ops, PUBLIC_KEY);

CREATE INDEX ca_name
	ON ca (lower(COMMON_NAME) text_pattern_ops);

CREATE INDEX ca_name_reverse
	ON ca (reverse(lower(COMMON_NAME)) text_pattern_ops);


CREATE TABLE certificate (
	ID				serial,
	CERTIFICATE			bytea		NOT NULL,
	ISSUER_CA_ID			integer		NOT NULL,
	SERIAL				bytea		NOT NULL,
	SHA256                  	text		NOT NULL,
	NOT_BEFORE			timestamp,
	NOT_AFTER			timestamp,
	KEY_ALGORITHM			text,
	KEY_SIZE			integer,
	SIGNATURE_ALGORITHM		text,
	
	CONSTRAINT c_pk
		PRIMARY KEY (ID),
	CONSTRAINT c_ica_fk
		FOREIGN KEY (ISSUER_CA_ID) REFERENCES ca(ID)
);

CREATE INDEX c_notbefore
	ON certificate (NOT_BEFORE);

CREATE INDEX c_notafter
	ON certificate (NOT_AFTER);

CREATE UNIQUE INDEX c_sha256
	ON certificate (SHA256);

CREATE INDEX c_serial
	ON certificate(SERIAL);
	

CREATE TYPE name_type AS ENUM (
'countryName', 'stateOrProvinceName', 'localityName', 'commonName', 'organizationName', 'emailAddress',
'rfc822Name', 'dNSName', 'iPAddress', 'organizationalUnitName'
);

CREATE TABLE certificate_identity (
	ID				serial,
	CERTIFICATE_ID		        integer		NOT NULL,
	NAME_TYPE			name_type	NOT NULL,
	NAME_VALUE			 text		NOT NULL,

	CONSTRAINT ci_c_fk
		FOREIGN KEY (CERTIFICATE_ID) REFERENCES certificate(ID)
);

CREATE UNIQUE INDEX ci_uniq
	ON certificate_identity (CERTIFICATE_ID, lower(NAME_VALUE) text_pattern_ops, NAME_TYPE);

CREATE INDEX ci_forward
	ON certificate_identity (NAME_TYPE, lower(NAME_VALUE) text_pattern_ops);

CREATE INDEX ci_reverse
	ON certificate_identity (NAME_TYPE, reverse(lower(NAME_VALUE)) text_pattern_ops);
	

CREATE TABLE revoked_certificate (
	ID 				serial,
	CERTIFICATE_ID			integer,
	DATE				timestamp,
	REASON	                 	text,
	CONSTRAINT rc_pk
		PRIMARY KEY (ID),
	CONSTRAINT rc_c_fk
		FOREIGN KEY (CERTIFICATE_ID) REFERENCES certificate(ID)
);

CREATE TABLE ca_certificate (
	ID				serial,
	CERTIFICATE_ID	            	integer,
	CA_ID				integer,
	CONSTRAINT cac_pk
		PRIMARY KEY (ID),
	CONSTRAINT cac_c_fk
		FOREIGN KEY (CERTIFICATE_ID) REFERENCES certificate(ID),
	CONSTRAINT cac_ca_fk
		FOREIGN KEY (CA_ID) REFERENCES ca(ID),
	CONSTRAINT cac_unq
		UNIQUE (CERTIFICATE_ID, CA_ID)
);

CREATE INDEX cac_ca_cert
	ON ca_certificate (CA_ID, CERTIFICATE_ID);


CREATE TABLE ct_log (
	ID				serial,
	URL				text,
	NAME				text,
	PUBLIC_KEY			bytea,
	LATEST_ENTRY_ID			integer,
	LATEST_UPDATE			timestamp,
	LATEST_LOG_SIZE			integer,
	OPERATOR			text,
	IS_ACTIVE			boolean,
	LATEST_STH_TIMESTAMP	    	timestamp,
	MMD_IN_SECONDS			integer,
	
	CONSTRAINT ctl_pk
		PRIMARY KEY (ID),
	CONSTRAINT crl_url_unq
		UNIQUE (URL)
);

CREATE TABLE ct_log_entry (
	ID				serial,
	CERTIFICATE_ID	            	integer,
	CT_LOG_ID			smallint,
	ENTRY_ID			integer,
	ENTRY_TIMESTAMP	            	timestamp,
	
	CONSTRAINT ctle_pk
		PRIMARY KEY (ID),
	CONSTRAINT ctle_c_fk
		FOREIGN KEY (CERTIFICATE_ID) REFERENCES certificate(ID),
	CONSTRAINT ctle_ctl_fk
		FOREIGN KEY (CT_LOG_ID) REFERENCES ct_log(ID),
        CONSTRAINT ctle_unq
                UNIQUE (CERTIFICATE_ID, CT_LOG_ID, ENTRY_ID)
);

CREATE INDEX ctle_le
	ON ct_log_entry (CT_LOG_ID, ENTRY_ID);

CREATE INDEX ctle_el
	ON ct_log_entry (ENTRY_ID, CT_LOG_ID);

	
CREATE TABLE metadata (
	ID				serial,
	NAME_TYPE			text,
	NAME_VALUE			integer,
	
	CONSTRAINT metadata_pk
		PRIMARY KEY (ID),
	CONSTRAINT metadata_nt_unq
		UNIQUE (NAME_TYPE)
);

INSERT INTO metadata(NAME_TYPE, NAME_VALUE) VALUES
('number_of_certs',0),
('number_of_cas',0),
('number_of_active_certs',0),
('number_of_expired_certs',0),
('number_of_revoked_certs',0),
('number_of_misissued_certs',0),
('number_of_correctly_behaving_cas',0),
('number_of_interesting_cas',0),
('number_of_certs_in_biggest_log',0),
('biggest_log_id',0),
('number_of_certs_in_smallest_log',0),
('smallest_log_id',0);


-- CREATE TABLE certificate_analysis (
-- 	ID serial,
-- 	type text,
-- 	value integer
-- );
-- 
-- INSERT INTO certificate_analysis (type, value) VALUES ('es_last_cert_id',-1);

CREATE TABLE notification_dns_names (
	ID serial,
	name text,
	
	CONSTRAINT notification_unq
		UNIQUE (id)
);

CREATE TABLE notification_email (
	ID serial,
	NOTIFY_FOR integer,
	EMAIL text,
	VALIDATE_KEY text,
	VALIDATED boolean,
	ACTIVE boolean,
	notification_dns_names_id integer,
	
	CONSTRAINT not_dns_fk
		FOREIGN KEY (notification_dns_names_id) REFERENCES notification_dns_names(ID)
);

GRANT SELECT ON ca TO crtsh;
GRANT SELECT ON certificate TO crtsh;
GRANT SELECT ON certificate_identity TO crtsh;
GRANT SELECT ON ca_certificate TO crtsh;
GRANT SELECT ON ct_log TO crtsh;
GRANT SELECT ON ct_log_entry TO crtsh;
GRANT SELECT ON metadata TO crtsh;

INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.googleapis.com/pilot','Google Pilot log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEfahLEimAoz2t01p3uMziiLOl/fHTDM0YDOhBRuiBARsV4UvxG2LdNgoIGLrtCzWE0J5APC2em4JlvR8EEEFMoA==','Google',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.googleapis.com/aviator','Google Aviator log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE1/TMabLkDpCjiupacAlP7xNi0I1JYP8bQFAHDG1xhtolSY1l4QgNRzRrvSe8liE+NPWHdjGxfx3JhTsN9x8/6Q==','Google',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.googleapis.com/icarus','Google Icarus log','','Google',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.googleapis.com/rocketeer','Google Rocketeer log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEIFsYyDzBi7MxCAC/oJBXK7dHjG+1aLCOkHjpoHPqTyghLpzA9BYbqvnV16mAw04vUjyYASVGJCUoI3ctBcJAeg==','Google',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.googleapis.com/skydiver','Google Skydiver log','','Google',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct1.digicert-ct.com/log','DigiCert Log Server','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEAkbFvhu7gkAW6MHSrBlpE1n4+HCFRkC5OLAjgqhkTH+/uzSfSl8ois8ZxAD2NgaTZe1M9akhYlrYkes4JECs6A==','DigiCert',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.ws.symantec.com','Symantec log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEluqsHEYMG1XcDfy1lCdGV0JwOmkY4r87xNuroPS2bMBTP01CEDPwWJePa75y9CrsHEKqAy8afig1dpkIPSEUhg==','Symantec',86400,true);

INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://vega.ws.symantec.com','Symantec VEGA log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE6pWeAv/u8TNtS4e8zf0ZF2L/lNPQWQc/Ai0ckP7IRzA78d0NuBEMXR2G3avTK0Zm+25ltzv9WWis36b4ztIYTQ==','Symantec',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ctlog.api.venafi.com','Venafi log','MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAolpIHxdSlTXLo1s6H1OCdpSj/4DyHDc8wLG9wVmLqy1lk9fz4ATVmm+/1iN2Nk8jmctUKK2MFUtlWXZBSpym97M7frGlSaQXUWyA3CqQUEuIJOmlEjKTBEiQAvpfDjCHjlV2Be4qTM6jamkJbiWtgnYPhJL6ONaGTiSPm7Byy57iaz/hbckldSOIoRhYBiMzeNoA0DiRZ9KmfSeXZ1rB8y8X5urSW+iBzf2SaOfzBvDpcoTuAaWx2DPazoOl28fP1hZ+kHUYvxbcMjttjauCFx+JII0dmuZNIwjfeG/GBb9frpSX219k1O4Wi6OEbHEr8at/XQ0y7gTikOxBn/s5wQIDAQAB','Venafi',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ctlog.wosign.com','WoSign log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEzBGIey1my66PTTBmJxklIpMhRrQvAdPG+SvVyLpzmwai8IoCnNBrRhgwhbrpJIsO0VtwKAx+8TpFf1rzgkJgMQ==','WoSign',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ctserver.cnnic.cn','CNNIC CT log','MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv7UIYZopMgTTJWPp2IXhhuAf1l6a9zM7gBvntj5fLaFm9pVKhKYhVnno94XuXeN8EsDgiSIJIj66FpUGvai5samyetZhLocRuXhAiXXbDNyQ4KR51tVebtEq2zT0mT9liTtGwiksFQccyUsaVPhsHq9gJ2IKZdWauVA2Fm5x9h8B9xKn/L/2IaMpkIYtd967TNTP/dLPgixN1PLCLaypvurDGSVDsuWabA3FHKWL9z8wr7kBkbdpEhLlg2H+NAC+9nGKx+tQkuhZ/hWR65aX+CNUPy2OB9/u2rNPyDydb988LENXoUcMkQT0dU3aiYGkFAY0uZjD2vH97TM20xYtNQIDAQAB','CNNIC',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.startssl.com','StartCom log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAESPNZ8/YFGNPbsu1Gfs/IEbVXsajWTOaft0oaFIZDqUiwy1o/PErK38SCFFWa+PeOQFXc9NKv6nV0+05/YIYuUQ==','StartCom',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.izenpe.eus','Izenpe log',NULL,'Izenpe',86400,false);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.gdca.com.cn','GDCA log 2',NULL,'Wang Shengnan',86400,false);

INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ctlog.gdca.com.cn','GDCA log 1',NULL,'Wang Shengnan',86400,false);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://www.certificatetransparency.cn/ct','PuChuangSiDa CT Log 1',NULL,'Beijing PuChuangSiDa Technology Ltd.',86400,true);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://alpha.ctlogs.org','alpha.ctlogs.org',NULL,'Matt Palmer',86400,false);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.izenpe.com','Izenpe log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEJ2Q5DC3cUBj4IQCiDu0s6j51up+TZAkAEcQRF6tczw90rLWXkJMAW7jr9yc92bIKgV8vDXU4lDeZHvYHduDuvg==','Izenpe',86400,false);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://log.certly.io','Certly.IO log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAECyPLhWKYYUgEc+tUXfPQB4wtGS2MNvXrjwFCCnyYJifBtd2Sk7Cu+Js9DNhMTh35FftHaHu6ZrclnNBKwmbbSA==','Certly',86400,false);
    
INSERT INTO ct_log (url, name, public_key, operator, mmd_in_seconds, is_active) VALUES
    ('https://ct.wosign.com','WoSign log','MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE1+wvK3VPN7yjQ7qLZWY8fWrlDCqmwuUm/gx9TnzwOrzi0yLcAdAfbkOcXG6DrZwV9sSNYLUdu6NiaX7rp6oBmw==','WoSign',86400,false);