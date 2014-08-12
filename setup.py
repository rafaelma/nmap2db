#!/usr/bin/env python
#
# Copyright (c) 2013-2014 Rafael Martinez Guerrero / PostgreSQL-es
# rafael@postgresql.org.es / http://www.postgresql.org.es/
#
# Copyright (c) 2014 USIT-University of Oslo 
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

import subprocess
import platform
import shutil
import sys
import os
import pwd
import grp
from setuptools import setup

'''
setup.py installation file
'''
try:
    nmap2db = {}
    with open('nmap2db/version.py', 'r') as version_file:
        exec (version_file.read(), nmap2db)
        
    if sys.version_info < (2, 6):
        raise SystemExit('ERROR: nmap2db needs at least python 2.6 to work')
    else:
        install_requires = ['psycopg2','argparse']
                
    #
    # Setup
    #

    setup(name='nmap2db',
          version=nmap2db['__version__'],
          description='NMAP2DB - NMAP scan manager',
          author='Rafael Martinez Guerrero',
          author_email='rafael@postgresql.org.es',
          url='https://github.com/rafaelma/nmap2db',
          packages=['nmap2db',],
          scripts=['bin/nmap2db','bin/nmap2db_scan'],
          data_files=[('/etc/init.d', ['bin/nmap2db_ctrl.sh']),
                      ('/etc/nmap2db', ['etc/nmap2db.conf']),
                      ('/usr/share/nmap2db', ['sql/nmap2db.sql']),
                      ('/usr/share/nmap2db', ['sql/nmap2db_table_partition.sql']),
                      ('/var/log/nmap2db',['etc/nmap2db.log'])],
          install_requires=install_requires,
          platforms=['Linux'],
          classifiers=[
            'Environment :: Console',
            'Development Status :: 5 - Production/Stable',
            'Intended Audience :: System Administrators',
            'License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)',
            'Programming Language :: Python',
            'Programming Language :: Python :: 2.6',
            'Programming Language :: Python :: 2.7',
            ],
          )

except Exception as e:
    print e
