#!/usr/bin/env python
#
# Copyright (c) 2013 Rafael Martinez Guerrero (PostgreSQL-es)
# rafael@postgresql.org.es / http://www.postgresql.org.es/
#
# This file is part of Nmap2db
# https://github.com/rafaelma/nmap2db
#
# Nmap2db is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Nmap2db is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Nmap2db.  If not, see <http://www.gnu.org/licenses/>.

import socket
import os
import ConfigParser

class configuration():

    # ############################################
    # Constructor
    # ############################################
    
    def __init__(self):
        """ The Constructor."""
        
        self.config_file = None

        # nmap2db database section
        self.dbhost = ''
        self.dbhostaddr = ''
        self.dbport = ''
        self.dbname = 'nmap2db'
        self.dbuser = 'nmap2db_user_rw'
        self.dbpassword = ''
        self.dsn = ''
        self.pg_connect_retry_interval = 10

        # Logging section
        self.log_level = 'ERROR'
        self.log_file = '/var/log/nmap2db/nmap2db.log'

        self.set_configuration_file()
        self.set_configuration_parameters()


    # ############################################
    # Method
    # ############################################
    
    def set_configuration_file(self):
        """Set the nmap2db configuration file"""
        
        config_file_list = (os.getenv('HOME') + '/.nmap2db/nmap2db.conf','/etc/nmap2db/nmap2db.conf','/etc/nmap2db.conf')
        
        for file in config_file_list:
            if os.path.isfile(file):
                self.config_file = file 
                break


    # ############################################
    # Method
    # ############################################
    
    def set_configuration_parameters(self):
        """Set configuration parameters"""

        dsn_parameters = []

        if self.config_file != None:

            config = ConfigParser.RawConfigParser()
            config.read(self.config_file)
    
            # nmap2db database section
            if config.has_option('nmap2db_database','host'):
                self.dbhost = config.get('nmap2db_database','host')

            if config.has_option('nmap2db_database','hostaddr'):
                self.dbhostaddr = config.get('nmap2db_database','hostaddr')

            if config.has_option('nmap2db_database','port'):
                self.dbport = config.get('nmap2db_database','port')

            if config.has_option('nmap2db_database','dbname'):
                self.dbname = config.get('nmap2db_database','dbname')

            if config.has_option('nmap2db_database','user'):
                self.dbuser = config.get('nmap2db_database','user')

            if config.has_option('nmap2db_database','password'):
                self.dbpassword = config.get('nmap2db_database','password')

            if config.has_option('nmap2db_database','pg_connect_retry_interval'):
                self.pg_connect_retry_interval = int(config.get('nmap2db_database','pg_connect_retry_interval'))

            # Logging section
            if config.has_option('logging','log_level'):
                self.log_level = config.get('logging','log_level')

            if config.has_option('logging','log_file'):
                self.log_file = config.get('logging','log_file')
            

        # Generate the DSN string 

        if self.dbhost != '':
            dsn_parameters.append('host=''' + self.dbhost + '')

        if self.dbhostaddr != '':
            dsn_parameters.append('hostaddr=''' + self.dbhostaddr + '')

        if self.dbport != '':
            dsn_parameters.append('port=''' + self.dbport + '')

        if self.dbname != '':
            dsn_parameters.append('dbname=''' + self.dbname + '')

        if self.dbuser != '':
            dsn_parameters.append('user=''' + self.dbuser + '')
    
        if self.dbpassword != '':
            dsn_parameters.append('password=''' + self.dbpassword + '')
          
        for parameter in dsn_parameters:
            self.dsn = self.dsn + parameter + ' '
