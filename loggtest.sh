#!/bin/bash
#################################################################################################################
#
#       NAME: <nameofscrpthere>
#
#       AUTHOR:  B3nd3r15
#
#       SUPPORT:  please post issue on github.
#
#       DESCRIPTION:  <description of what script does here>
#
#       License: GPL-3.0
#       https://github.com/B3nd3r15/linuxscripts/blob/master/LICENSE
#
#################################################################################################################
#
#       ASSUMPTIONS: Script is run manually, target server has access to internet.
#
#       INSTALL LOCATION: Where to put the script.
#
#################################################################################################################
#
#       Command(s):
#           
#           
#           
#           
#           
#           
#           
#           
#           
#           
#           
#
#################################################################################################################
#
#    Version      AUTHOR      DATE          COMMENTS
#                 ------      ----          --------
#  VER 0.1.0      B3nd3r      2019/01/23    Initial creation and release.
#
#################################################################################################################


# Put at the beginning of every script for logging/debugging.
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3 RETURN
exec 1>logtester.out 2>&1
# Everything below will go to the file 'log.out':

#---------------------------------
# Run as Root.
#---------------------------------
#if (( EUID != 0 )); then
#        sudo /home/"$USER"/"$scriptname"
#        exit
#fi
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@" 
fi

#show the current time
time=$(date +"%T")

echo $time



return
exit 0
