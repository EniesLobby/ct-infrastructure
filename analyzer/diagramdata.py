import urllib
import urlparse
import shutil
import logging
import os
import ssl

class Diagramdata:
	def __init__(self, baseurl, target_directory,debug):
		self.baseurl = baseurl
		self.target_directory = target_directory
		self.debug = debug
	
	def update_getactivekeysizedistribution(self):
		self.update_data("/api/getactivekeysizedistribution", 'getactivekeysizedistribution')
		
	def update_getsignaturealgorithmdistribution(self):
		self.update_data("/api/getsignaturealgorithmdistribution", 'getsignaturealgorithmdistribution')
		
	def update_data(self, url, filename):
		request_url = urlparse.urljoin(self.baseurl, url)
		target_filename = os.path.join(self.target_directory, filename)
		
		logging.debug("Retrieving {url}, saving as {path}".format(url=request_url, path=target_filename))
		
		if(self.debug):
			c = ssl.SSLContext(ssl.PROTOCOL_TLSv1)
			urllib.urlretrieve(request_url, target_filename, context=c)
		else:
			urllib.urlretrieve(request_url, target_filename)
			
		logging.debug("File {path} has been saved".format(path=target_filename))
		
		
	def update_diagrams(self):
		logging.debug("Updating getactivekeysizedistribution...")
		self.update_getactivekeysizedistribution()
		
		logging.debug("Updating getsignaturealgorithmdistribution...")
		self.update_getsignaturealgorithmdistribution()
		
		logging.debug("Done (Diagramdata.update_diagrams).")
		
		return "Successfully updated diagrams."