#!/usr/bin/env python
import os
import sys
import logging

from nmap2db.config import *

class logs(logging.Logger):

    # ############################################
    # Constructor    
    # ############################################

    def __init__(self, logger_name):
        """ The Constructor."""
     
        self.logger_name = logger_name
        
        self.logger = logging.getLogger(logger_name)
        self.logger.setLevel('DEBUG')
        
        try:
            self.fh = logging.FileHandler('/tmp/tmp.log')
            self.fh.setLevel('DEBUG')

            self.formatter = logging.Formatter("%(asctime)s [%(name)s][%(process)d][%(levelname)s]: %(message)s")
            self.fh.setFormatter(self.formatter)
            self.logger.addHandler(self.fh)
        
        except IOError as e:
            print "ERROR: Problems with the log configuration needed by nmap2db: %s" % e
            sys.exit()
        

logs = logs("nmap2db_test")
logs.logger.info('**** nmap2db_test started. ****')
