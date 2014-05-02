#!/usr/bin/env python
#
# Copyright (c) 2014 Rafael Martinez Guerrero (PostgreSQL-es)
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
#

import cmd
import sys
import os
import time
import datetime
import signal
import shlex

from nmap2db.database import * 
from nmap2db.config import *
from nmap2db.logs import *

# ############################################
# class nmap2db_cli
#
# This class implements the nmap2db shell.
# It is based on the python module cmd
# ############################################

class nmap2db_cli(cmd.Cmd):
    
    # ###############################
    # Constructor
    # ###############################

    def __init__(self):
        cmd.Cmd.__init__(self)
        
        self.intro =  '\n########################################################\n' + \
            'Welcome to the Nmap2DB shell (v.1.0.0)\n' + \
            '########################################################\n' + \
            'Type help or \? to list commands.\n'
        
        self.prompt = '[nmap2db]$ '
        self.file = None

        self.conf = configuration() 
        self.dsn = self.conf.dsn
        
        self.logs = logs("nmap2db_cli")

        self.db = nmap2db_db(self.dsn,self.logs,'nmap2db_cli')
        self.output_format = 'table'


    # ############################################
    # Method do_show_network_definitions
    # ############################################

    def do_show_network_definitions(self,args):
        """
        DESCRIPTION:
        This command shows all networks defined in nmap2db.
        
        COMMAND:
        show_network_definitions
        """
        
        #
        # If a parameter has more than one token, it has to be
        # defined between doble quotes
        #
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False
        
        if len(arg_list) == 0:
            try:
                self.db.show_network_definitions()

            except Exception as e:
                print "\n[ERROR]: ",e
                
        else:
            print "\n[ERROR] - This command does not accept parameters.\n          Type help or \? to list commands\n"
            
    # ############################################
    # Method do_show_scan_definitions
    # ############################################

    def do_show_scan_definitions(self,args):
        """
        DESCRIPTION:
        This command shows all scans types defined in nmap2db.
        
        COMMAND:
        show_scan_definitions
        """
        
        #
        # If a parameter has more than one token, it has to be
        # defined between doble quotes
        #
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False
        
        if len(arg_list) == 0:
            try:
                self.db.show_scan_definitions()

            except Exception as e:
                print "\n[ERROR]: ",e
                
        else:
            print "\n[ERROR] - This command does not accept parameters.\n          Type help or \? to list commands\n"
            

    # ############################################
    # Method do_show_scan_jobs
    # ############################################

    def do_show_scan_jobs(self,args):
        """
        DESCRIPTION:
        This command shows all scans jobs defined in nmap2db.
        
        COMMAND:
        show_scan_jobs [NETWORK_CIDR]
        """
        
        #
        # If a parameter has more than one token, it has to be
        # defined between doble quotes
        #
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False
        
        if len(arg_list) == 0:
            
            print "--------------------------------------------------------"
            network_cidr = raw_input("# Network CIDR [all]: ")
            print "--------------------------------------------------------"

            if network_cidr == '':
                network_cidr = 'ALL'

            try:
                self.db.show_scan_jobs(network_cidr)
            except Exception as e:
                print "\n[ERROR]: ",e
                
        elif len(arg_list) == 1:
            
            network_cidr = arg_list[0].upper()

            print "--------------------------------------------------------"
            print "# Network CIDR: " + network_cidr
            print "--------------------------------------------------------"
            
            try:
                self.db.show_scan_jobs(network_cidr)
            except Exception as e:
                print "\n[ERROR]: ",e

        else:
            print "\n[ERROR] - Wrong number of parameters used.\n          Type help or ? to list commands\n"
            

    # ############################################
    # Method do_show_host_reports
    # ############################################

    def do_show_host_reports(self,args):
        """
        DESCRIPTION:
        This command shows scans reports for a hostname / IP 
        in a period of time.
        
        COMMAND:
        show_host_reports [IP|HOSTNAME][FROM][TO]
        """
        
        #
        # If a parameter has more than one token, it has to be
        # defined between doble quotes
        #
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False
        
        if len(arg_list) == 0:
            
            to_default =  datetime.datetime.now()
            from_default = to_default - datetime.timedelta(days=7)

            print "--------------------------------------------------------"
            host = raw_input("# IP / Hostname []: ")
            from_timestamp = raw_input("# From [" + str(from_default) + "]: ")
            to_timestamp = raw_input("# To [" + str(to_default) + "]: ")
            print "--------------------------------------------------------"

            if from_timestamp == '':
                from_timestamp = from_default
                
            if to_timestamp == '':
                to_timestamp = to_default

            try:
                self.db.show_host_reports(host,from_timestamp,to_timestamp)
            except Exception as e:
                print "\n[ERROR]: ",e
                
        elif len(arg_list) == 3:
            
            host = arg_list[0].lower()
            from_timestamp = arg_list[1]
            to_timestamp = arg_list[2]

            print "--------------------------------------------------------"
            print "# IP / Hostname: " + host
            print "# From: " + from_timestamp
            print "# To: " + to_timestamp
            print "--------------------------------------------------------"
            
            try:
                self.db.show_host_reports(host,from_timestamp,to_timestamp)
            except Exception as e:
                print "\n[ERROR]: ",e

        else:
            print "\n[ERROR] - Wrong number of parameters used.\n          Type help or ? to list commands\n"

            
    # ############################################
    # Method do_show_host_details
    # ############################################

    def do_show_report_details(self,args):
        """
        DESCRIPTION:
        This command shows host and service details from a report.
        
        COMMAND:
        show_host_details [ReportID]
        """
        
        #
        # If a parameter has more than one token, it has to be
        # defined between doble quotes
        #
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False
        
        if len(arg_list) == 0:
            
            print "--------------------------------------------------------"
            report_id = raw_input("# ReportID []: ")
            print "--------------------------------------------------------"

            try:
                self.db.show_host_details(report_id)
                self.db.show_services_details(report_id)

            except Exception as e:
                print "\n[ERROR]: ",e
                
        elif len(arg_list) == 1:
            
            report_id = arg_list[0].lower()
          
            print "--------------------------------------------------------"
            print "# ReportID: " + report_id
            print "--------------------------------------------------------"
            
            try:
                self.db.show_host_details(report_id)
                self.db.show_services_details(report_id)

            except Exception as e:
                print "\n[ERROR]: ",e

        else:
            print "\n[ERROR] - Wrong number of parameters used.\n          Type help or ? to list commands\n"
            
    # ############################################
    # Method do_show_network_definitions
    # ############################################

    def do_show_host_without_hostname(self,args):
        """
        DESCRIPTION:
        This command shows all host registered without a hostname.
        
        COMMAND:
        show_host_without_hostname
        """
        
        #
        # If a parameter has more than one token, it has to be
        # defined between doble quotes
        #
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False
        
        if len(arg_list) == 0:
            try:
                self.db.show_host_without_hostname()

            except Exception as e:
                print "\n[ERROR]: ",e
                
        else:
            print "\n[ERROR] - This command does not accept parameters.\n          Type help or \? to list commands\n"


    # ############################################
    # Method do_show_host_reports
    # ############################################

    def do_show_port(self,args):
        """
        DESCRIPTION:
        This command shows registered ports/services in a period of time.
        
        COMMAND:
        show_port [network, ...] [port, ...] [service, ...] [from] [to]
        """
                
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False
        
        if len(arg_list) == 0:
            
            to_default =  datetime.datetime.now()
            from_default = to_default - datetime.timedelta(days=7)

            print "--------------------------------------------------------"
            networks = raw_input("# Networks CIDR [all]: ")
            ports = str(raw_input("# Ports []: "))
            services = raw_input("# Services []: ")
            from_timestamp = raw_input("# From [" + str(from_default) + "]: ")
            to_timestamp = raw_input("# To [" + str(to_default) + "]: ")
            print "--------------------------------------------------------"

            if networks == '':
                network_list = None
            else:
                network_list = networks.strip().replace(' ','').split(',')

            if ports == '':
                port_list = None
            else:
                port_list = ports.strip().replace(' ','').split(',')

            if services == '':
                service_list = None
            else:
                service_list = services.split(',')
                service_list_tmp = []

                for service_tmp in service_list:
                    service_list_tmp.append('%' + service_tmp + '%')
                    
                service_list = service_list_tmp

            if from_timestamp == '':
                from_timestamp = from_default
                
            if to_timestamp == '':
                to_timestamp = to_default

            try:
                self.db.show_ports(network_list,port_list,service_list,from_timestamp,to_timestamp)
            except Exception as e:
                print "\n[ERROR]: ",e
                
        elif len(arg_list) == 5:
            
            networks = arg_list[0]
            ports = arg_list[1]
            services = arg_list[2]
            from_timestamp = arg_list[3]
            to_timestamp = arg_list[4]

            if self.output_format == 'table':
            
                print "--------------------------------------------------------"
                print "# Networks: " + networks
                print "# Ports: " + str(ports)
                print "# Services: " + services
                print "# From: " + str(from_timestamp)
                print "# To: " + str(to_timestamp)
                print "--------------------------------------------------------"
            
            if networks == '':
                network_list = None
            else:
                network_list = networks.strip().replace(' ','').split(',')
                
            if ports == '':
                port_list = None
            else:
                port_list = ports.strip().replace(' ','').split(',')

            if services == '':
                service_list = None
            else:
                service_list = services.split(',')
                service_list_tmp = []

                for service_tmp in service_list:
                    service_list_tmp.append('%' + service_tmp + '%')
                    
                service_list = service_list_tmp

            try:
                self.db.show_ports(network_list,port_list,service_list,from_timestamp,to_timestamp)
            except Exception as e:
                print "\n[ERROR]: ",e

        else:
            print "\n[ERROR] - Wrong number of parameters used.\n          Type help or ? to list commands\n"

    # ############################################
    # Method do_show_host_reports
    # ############################################

    def do_show_os(self,args):
        """
        DESCRIPTION:
        This command shows hostnames running an operativ system.
        
        COMMAND:
        show_os [NETWORK][OS][FROM][TO]
        """
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False
        
        if len(arg_list) == 0:
            
            to_default =  datetime.datetime.now()
            from_default = to_default - datetime.timedelta(days=7)

            print "--------------------------------------------------------"
            networks = raw_input("# Networks CIDR [all]: ")
            osname = raw_input("# OSname []: ")
            from_timestamp = raw_input("# From [" + str(from_default) + "]: ")
            to_timestamp = raw_input("# To [" + str(to_default) + "]: ")
            print "--------------------------------------------------------"

            if networks == '':
                network_list = None
            else:
                network_list = networks.strip().replace(' ','').split(',')

            if osname == '':
                os_list = None
            else:
                os_list = osname.split(',')
                os_list_tmp = []

                for os_tmp in os_list:
                    os_list_tmp.append('%' + os_tmp + '%')
                    
                os_list = os_list_tmp
            
            if from_timestamp == '':
                from_timestamp = from_default
                
            if to_timestamp == '':
                to_timestamp = to_default

            try:
                self.db.show_os(network_list,os_list,from_timestamp,to_timestamp)
            except Exception as e:
                print "\n[ERROR]: ",e
                
        elif len(arg_list) == 4:
            
            networks = arg_list[0]
            osname = arg_list[1]
            from_timestamp = arg_list[2]
            to_timestamp = arg_list[3]

            if self.output_format == 'table':
            
                print "--------------------------------------------------------"
                print "# Networks: " + networks
                print "# OSname: " + osname
                print "# From: " + from_timestamp
                print "# To: " + to_timestamp
                print "--------------------------------------------------------"
            
            if networks == '':
                network_list = None
            else:
                network_list = networks.strip().replace(' ','').split(',')
                
            if osname == '':
                os_list = None
            else:
                os_list = osname.split(',')
                os_list_tmp = []

                for os_tmp in os_list:
                    os_list_tmp.append('%' + os_tmp + '%')
                    
                os_list = os_list_tmp

            try:
                self.db.show_os(network_list,os_list,from_timestamp,to_timestamp)
            except Exception as e:
                print "\n[ERROR]: ",e

        else:
            print "\n[ERROR] - Wrong number of parameters used.\n          Type help or ? to list commands\n"
                 

    # ############################################
    # Method do_register_backup_server
    # ############################################

    def do_register_network(self,args):
        """
        DESCRIPTION:
        This command registers a new network.

        COMMAND:
        register_network [Network CIDR][Remarks]
        """
        
        #
        # If a parameter has more than one token, it has to be
        # defined between doble quotes
        #
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False

        #
        # Command without parameters
        #

        if len(arg_list) == 0:
            
            ack = ""

            print "--------------------------------------------------------"
            network_cidr = raw_input("# Network CIDR []: ")
            remarks = raw_input("# Remarks []: ")
            print

            while ack != "yes" and ack != "no":
                ack = raw_input("# Are all values correct (yes/no): ")
                
            print "--------------------------------------------------------"

            if ack.lower() == "yes":
                try:
                    self.db.register_network(network_cidr.lower().strip(),remarks.strip())
                    print "\n[Done]\n"

                except Exception as e:
                    print "\n[ERROR]: Could not register this network\n",e  

            elif ack.lower() == "no":
                print "\n[Aborted]\n"

        #
        # Command with the 2 parameters that can be defined.
        # Hostname, domain, status and remarks
        #

        elif len(arg_list) == 2:

            network_cidr = arg_list[0]
            remarks = arg_list[1]
 
            try:    
                self.db.register_network(network_cidr.lower().strip(),remarks.strip())
                print "\n[Done]\n"

            except Exception as e:
                print "\n[ERROR]: Could not register this network\n",e
    
        #
        # Command with the wrong number of parameters
        #

        else:
            print "\n[ERROR] - Wrong number of parameters used.\n          Type help or \? to list commands\n"

    

    # ############################################
    # Method do_register_backup_server
    # ############################################

    def do_register_scan_job(self,args):
        """
        DESCRIPTION:
        This command registers a new scan job.

        COMMAND:
        register_scan_job [Network CIDR][ScanID][Execution interval][is_Active]

        is_Active
        ----------
        TRUE
        FALSE
        """
        
        #
        # If a parameter has more than one token, it has to be
        # defined between doble quotes
        #
        
        try: 
            arg_list = shlex.split(args)
        
        except ValueError as e:
            print "\n[ERROR]: ",e,"\n"
            return False

        #
        # Command without parameters
        #

        if len(arg_list) == 0:
            
            ack = ""

            print "--------------------------------------------------------"
            network_cidr = raw_input("# Network CIDR []: ")
            scan_id = raw_input("# ScanID [sn-traceroute]: ")
            execution_interval = raw_input("# Remarks [7 days]: ")
            is_active = raw_input("# Activated [true]: ")
            print

            while ack != "yes" and ack != "no":
                ack = raw_input("# Are all values correct (yes/no): ")
                
            print "--------------------------------------------------------"
            
            if scan_id == '':
                scan_id = 'sn-traceroute'

            if execution_interval == '':
                execution_interval = '7 days'

            if is_active == '':
                is_active = 'true'
                
            if ack.lower() == "yes":
                try:
                    self.db.register_scan_job(network_cidr.lower().strip(),scan_id.strip(),execution_interval.lower().strip(),is_active.lower().strip())
                    print "\n[Done]\n"

                except Exception as e:
                    print "\n[ERROR]: Could not register this scan job\n",e  

            elif ack.lower() == "no":
                print "\n[Aborted]\n"

        #
        # Command with the 2 parameters that can be defined.
        # Hostname, domain, status and remarks
        #

        elif len(arg_list) == 4:

            network_cidr = arg_list[0]
            scan_id = arg_list[1]
            execution_interval = arg_list[2]
            is_active = arg_list[3]
 
            try:    
                self.db.register_scan_job(network_cidr.lower().strip(),scan_id.lower().strip(),execution_interval.lower().strip(),is_active.lower().strip())
                print "\n[Done]\n"

            except Exception as e:
                print "\n[ERROR]: Could not register this scan job\n",e
    
        #
        # Command with the wrong number of parameters
        #

        else:
            print "\n[ERROR] - Wrong number of parameters used.\n          Type help or \? to list commands\n"




    # ############################################
    # Method do_clear
    # ############################################

    def do_clear(self,args):
        """Command clear"""
        
        os.system('clear')
        print self.intro


    # ############################################
    # Method default
    # ############################################

    def default(self,line):
        print "\n[ERROR] - Unknown command: %s.\n          Type help or \? to list commands\n" % line


    # ############################################
    # Method emptyline
    # ############################################

    def emptyline(self):
        pass


    # ############################################
    # Method precmd
    # ############################################

    def precmd(self, line_in):

        if line_in != '':
            split_line = line_in.split()

            if split_line[0] not in ['EOF','shell','SHELL','!']:
                line_out = line_in.lower()
            else:
                line_out = line_in
        else:
            line_out = ''

        if line_out.strip() != '':
            self._hist += [ line_out.strip() ]

        if line_out == "\h":
            line_out = "help"
        elif line_out == "\?":
            line_out = "help"
        elif line_out == "\s":
            line_out = "show_history"    
        elif line_out == "\q":
            line_out = "quit" 
              
        return cmd.Cmd.precmd(self, line_out)


    # ############################################
    # Method do_shell
    # ############################################

    def do_shell(self, line):
        "Run a shell command"
        
        try:
            os.system(line)
        except:
            print "* Problems running '%s'" % line


    # ############################################
    # Method do_quit
    # ############################################

    def do_quit(self, args):
        'Quit the Nmap2db shell.'
        
        print "\nDone, thank you for using Nmap2db"
        return True


    # ############################################
    # Method do_EOF
    # ############################################
    
    def do_EOF(self, line):
        'Quit the Nmap2db shell.'
        
        print
        print "Thank you for using Nmap2db"
        return True


    # ############################################
    # Method do_hist
    # ############################################

    def do_show_history(self, args):
        """Print a list of commands that have been entered"""

        for line in self._hist:
            print line


    # ############################################
    # Method preloop
    # ############################################

    def preloop(self):
        """
        Initialization before prompting user for commands.
        """
        
        cmd.Cmd.preloop(self)   ## sets up command completion
        self._hist    = []      ## No history yet
        self._locals  = {}      ## Initialize execution namespace for user
        self._globals = {}


    # ############################################
    # Method help_shortcuts
    # ############################################

    def help_shortcuts(self):
        """Help information about shortcuts in Nmap2db"""
        
        print """
        Shortcuts in Nmap2db:

        \h Help information
        \? Help information
        
        \s - display history 
        \q - quit Nmap2db shell

        \! [COMMAND] - Execute command in shell
          
        """

    # ############################################
    # Method handler
    # ############################################

    def signal_handler(self,signum, frame):
        cmd.Cmd.onecmd(self,'quit')
        sys.exit(0)


    # ############################################
    # Method check_digit
    # ############################################

    def check_digit(self,digit):
        
        if digit.isdigit():
            return True
        else:
            print "\n* ERROR - %s should be a digit\n" % digit 
            return False



signal.signal(signal.SIGINT, nmap2db_cli().signal_handler)


if __name__ == '__main__':

    nmap2db_cli().cmdloop()

