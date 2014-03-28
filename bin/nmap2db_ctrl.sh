#!/bin/bash
#
# NMAP2DB is a set of scripts that can be used to run 
# automatic NMAP scans of a network and save 
# the results in a database for further analysis.
#
# @File: 
# nmap2db_ctrl.sh
#
# @Author: 
# Rafael Martinez Guerrero / rafael@postgresql.org.es
# 
# @Description: 
# NMAP2DB control script. Used to start/stop the nmap2db
#
# Some nmap scans must be run as root. We recommend to run 
# this script as 'root'
#
# Example: sudo ./nmap2db_ctrl.sh -c start
#

BINDIR="/usr/bin"

#
# Execute command
#

execute_command(){
    
    case $COMMAND in
	start)
	    
	    for SCANNER in `seq 1 $NUMBER_SCANNERS`
	    do
		echo "* Starting scanner num. $SCANNER"
		$BINDIR/nmap2db_scan &
		sleep 3;
	    done
	    exit 0
	    ;;
	
	stop)
	    for PID in `pidof -x nmap2db_scan`;
	    do
		kill -15 $PID
		echo "* Scanner with PID: ${PID} stopped"
	    done
            exit 0;;
    esac
    
}


# ########################################
# help()
# ########################################

help(){
    
    echo
    echo "Script: $0" 
    echo "Version: ${VERSION}"
    
    echo "Description:  This script is used to start/stop nmap2db"
    echo
    echo "Usage: "
    echo "       `basename $0` [-h][-v][-c <command>]"
    echo
    echo "       -h Help"
    echo "       -v Version"
    echo "       -c Command [start|stop] (*)"
    echo "       -n Number of scanners"
    echo "       (*) - Must be defined"
    echo
    echo "Example: sudo `basename $0` -c start"
    echo
}

# ########################################
# version()
# ########################################

version(){
    echo
    echo " Name: `basename $0`"
    echo " Version: ${VERSION}"
    echo
    echo " Description: This script is used 
 to control nmap2db execution"
    echo
    echo " Web: http://www.github.com/rafaelma/nmap2db/"      
    echo " Contact: rafael@postgresql.org.es"
    echo
}


# ########################################
# ########################################
# Getting command options
# ########################################
# ########################################

if [ $# -eq 0 ]
    then
    help
    exit 1   
fi  

while getopts "hvc:n:" Option
  do
  case $Option in
      h)
          help 
          exit 0;;
      
      v)
          version
          exit 0;;

      c)
	  COMMAND=$OPTARG;;

      n)
	  let NUMBER_SCANNERS=$OPTARG;;
	  
  esac
done
shift $(($OPTIND - 1))


# ########################################
# Sanity check
# ########################################



if [ -z "$COMMAND" ] 
    then
    echo
    echo "ERROR: No command has been defined"
    echo
    help
    exit 1
fi

if [ "$COMMAND" != "start" ] &&  [ "$COMMAND" != "stop" ] 
    then
    echo
    echo "ERROR: This command is not supported"
    echo
    help
    exit 1
fi

if [ -z "$NUMBER_SCANNERS" ] 
    then
    let NUMBER_SCANNERS=2
fi

if [ "$NUMBER_SCANNERS" -lt 2 ] 
    then
    let NUMBER_SCANNERS=2
fi


execute_command
exit 0

#
#EOF
#
