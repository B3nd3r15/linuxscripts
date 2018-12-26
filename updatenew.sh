#!/bin/bash

###################################################################
# Script Name: update.sh
#
# Date Created: 2018-09-01
#
# Description: script to detect which package manger you are using
# install updates, cleans up old pacakges, installs ntp if needed,
# configure ntp with google time servers, and check for new LTS 
# releases if applicable. 
#
# Args: N/A
#
# Author:B3nd3r15
# Email:
#
# License: GPL-3.0  
# https://github.com/B3nd3r15/linuxscripts/blob/master/LICENSE
###################################################################



#----------------------------------
#		VARIABLES
#----------------------------------

#---------------------------------
# Pulls the script name without directory paths
#---------------------------------
scriptname="$(basename "${0}")"

#---------------------------------
# Gets OS Version
#---------------------------------
osver=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)

#---------------------------------
# Gets Yum version
#---------------------------------
YUM_CMD=$(command -v yum)

#---------------------------------
# Gets Apt version
#---------------------------------
APT_GET_CMD=$(command -v apt-get)

#---------------------------------
# Timestamp function
#---------------------------------
timestamp()
{
 date +"%Y-%m-%d %T"
}

#---------------------------------
#	Run as Root
#---------------------------------

if (( EUID != 0 )); then
    sudo /home/"$USER"/"$scriptname"
        exit
fi

#---------------------------------
#	chronyd service
#---------------------------------
SERVICE=chronyd;

#---------------------------------
#	Clear the screen
#---------------------------------
clear 
echo ""

#---------------------------------
#	Set log Location
#---------------------------------
LOG_LOCATION=/var/log
exec > >(tee -ai $LOG_LOCATION/"${scriptname}".log )
exec 2>&1
echo ""

#--------------------------------------------------
#	Determine Installed packaging system
#--------------------------------------------------
if [[ -n $YUM_CMD ]]; then


		#---------------------------------
		#	Update
		#---------------------------------
		echo "" 
		echo "# Upgrading $osver on $(timestamp) #" 
		
		#---------------------------------
		#	Update Yum
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Updating Yum
		echo ""
		yes | sudo yum update -y >> $LOG_LOCATION/"${scriptname}".log
		
		#---------------------------------
		#	Install Updates
		#---------------------------------
		echo -e "\xE2\x9C\x94" Installing Updates
		echo ""
		yes | sudo yum upgrade >> $LOG_LOCATION/"${scriptname}".log
		echo ""

		#---------------------------------
		#	Clean up unused pacakages
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Cleaning Up Yum Packages
		echo ""
		yes | sudo yum clean packages >> $LOG_LOCATION/"${scriptname}".log
		echo ""

		#---------------------------------
		#	Clean up Yum Metadata
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Cleaning Up Yum Metadata
		echo ""
		yes | sudo yum clean metadata >> $LOG_LOCATION/"${scriptname}".log
		echo ""

		#---------------------------------
		#	Clean Yum DB Cache
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Cleaning Up Yum DBCache
		echo ""
		yes | sudo yum clean dbcache >> $LOG_LOCATION/"${scriptname}".log
		echo ""

		#---------------------------------
		#	Clean anything leftover
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Cleaning up Yum Everything
		echo ""
		yes | sudo yum clean all >> $LOG_LOCATION/"${scriptname}".log
		echo ""

		#---------------------------------
		#	Remove /var/cache/yum file
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Removing /var/cache/yum
		yes | sudo rm -rf /var/cache/yum >> $LOG_LOCATION/"${scriptname}".log
		echo ""

		echo "" 
		echo "# End of Upgrade on $(timestamp) #" 
		echo "" 

		echo "" 
		echo "# Start disable of Chronyd Service on $(timestamp) #"
		echo "" 

		if P=$(pgrep $SERVICE); then
   			echo "$SERVICE is running, PID is $P, Disabling chronyd service."
   			#Stop the Chronyd Service
   			systemctl stop chronyd
   			#Disable chronyd so it cannot start if server reboots.
   			systemctl disable chronyd
		else
   			echo "$SERVICE is not running or has been disabled."
   		fi

		echo "" 
		echo "# End of disabling Chronyd Service on $(timestamp) #"
		echo "" 

		echo ""
 	    echo "# Configuring NTP on $(timestamp) #"

    	#-------------------------------------------------------------------------------------
		# Checks to see if NTP is installed. If it is, continues to check if the config file
    	# is modified if not it will install it and update the config file
		#-------------------------------------------------------------------------------------
    	if yum list installed | grep ntp.x86_64 > /dev/null 2>&1; then
    		echo ""
    		echo -e "\xE2\x9C\x94" NTP Successfully Installed
		else
			echo ""
    		echo -e "\xE2\x9C\x94" Installing NTP
    		yes | sudo yum install ntp ntpd >> $LOG_LOCATION/"${scriptname}".log
		fi  

		#-------------------------------------------------
		# Checks to see if the config files need updated
		#-------------------------------------------------
		if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
 			echo ""
 			echo -e "\xE2\x9C\x94" NTP conf file already updated.
		else
			echo ""
			echo -e "\xE2\x9C\x94" Updating NTP conf file
	

		#-----------------------------------------------\------------------------------------
		# The config files for ntp lies in /etc/ntp.conf
		# We are changing the Servers time to google's public NTP servers
		# Look here for more info : https://developers.google.com/time/guides#linux_ntpd
		#-----------------------------------------------------------------------------------
			echo "" 
			echo -e "\xE2\x9C\x94" Modifying NTP config file
			
			#-------------------------------------------------
			# Comment out the default pool servers.
			#-------------------------------------------------
			sed -i 's/pool/#&/' /etc/ntp.conf
			sed -i 's/server/#&/' /etc/ntp.conf
		
			#-------------------------------------------------
			# Add the new servers to the end of the file.
			#-------------------------------------------------
			sed -i "\$aserver time1.google.com iburst" /etc/ntp.conf
			sed -i "\$aserver time2.google.com iburst" /etc/ntp.conf
			sed -i "\$aserver time3.google.com iburst" /etc/ntp.conf
			sed -i "\$aserver time4.google.com iburst" /etc/ntp.conf
			
			#-------------------------------------------------
			# Restart, enable, and show the status of the service
			#-------------------------------------------------
			echo "" 
			echo -e "\xE2\x9C\x94" Restarting NTP Service
			sudo systemctl stop ntpd
			sleep 2
			sudo systemctl start ntpd
			sleep 2
			sudo systemctl enable ntpd
			sleep 2
 			sudo systemctl status ntpd
		fi

		#-------------------------------------------------
		# Give ntp service time to start up and talk to time*.google.com
		#-------------------------------------------------
		sleep 5
		echo ""
		echo -e "\xE2\x9C\x94" Waiting for NTP service to start

		#-------------------------------------------------
		# Show NTP servers
		#-------------------------------------------------
		echo "" 
		echo -e "\xE2\x9C\x94" Showing current NTP Servers
		echo ""
		ntpq -p
		echo ""
		ntpstat
		echo ""

		echo ""
 	    echo "# Completed NTP Configuration on $(timestamp) #"
 	    echo ""

		echo ""
		echo "To view the log file: [ less $LOG_LOCATION/"${scriptname}".log ]"
		echo ""

elif [[ -n $APT_GET_CMD ]]; then

		#---------------------------------
 	    # Update all the things!
		#---------------------------------
 		echo ""
  		echo "# Upgrading $osver on $(timestamp) #"
  		echo ""

  		#---------------------------------
	    # Update all the repos.
		#---------------------------------
   		echo -e "\xE2\x9C\x94" Updating Repos
   		yes | sudo apt-get update >> $LOG_LOCATION/"${scriptname}".log

   		#---------------------------------
 	    # Upgrade all the things.
		#---------------------------------
 		echo -e "\xE2\x9C\x94" Upgrading System
 		yes | sudo apt-get dist-upgrade >> $LOG_LOCATION/"${scriptname}".log

   		#---------------------------------
	    # Remove old software.
		#---------------------------------
 		echo -e "\xE2\x9C\x94" Removing Unused Software
 		yes|sudo apt-get autoremove >> $LOG_LOCATION/"${scriptname}".log

    	#---------------------------------
	    # Purge config files
		#---------------------------------
 		echo -e "\xE2\x9C\x94" Purging Leftover Config Files
 		apt-get purge -y "$(dpkg -l | awk '/^rc/ { print $2 }')" >>$LOG_LOCATION/"${scriptname}".log

    	echo ""
    	echo "# End of Upgrade on $(timestamp) #"

    	echo ""
 	    echo "# Checking for new LTS release on $(timestamp) #"
 	    echo ""

    	#---------------------------------
		# Ask user if they would like to
		# check for new LTS release
		#---------------------------------
		if do-release-upgrade -c; then 
    		echo ""
    		read -p "Would you like to install the new LTS release? " yn
    		 case $yn in
       		 [Yy]* ) do-release-upgrade;;
     		 [Nn]* ) ;;
     	  		 * ) echo "Please answer yes or no.";;
			esac
		else
			echo ""
    		echo "No action taken."
		fi

		echo ""
 	    echo "# Completed Checking for LTS release on $(timestamp) #"
 	    echo ""

 	    echo ""
 	    echo "# Configuring NTP on $(timestamp) #"
 	    echo ""

 	    #---------------------------------
    	# Checks to see if NTP is installed. If it is, continues to modify config file.
    	# if not it will install it. 
		#---------------------------------
    	if apt-get -qq install ntp ntpstat; then 
    		echo -e "\xE2\x9C\x94" NTP Successfully Installed
		else
    		yes | sudo apt-get install ntp ntpstat >> $LOG_LOCATION/"${scriptname}".log
		fi  

		#---------------------------------
		# Checks to see if the config files need updated
		#---------------------------------
		if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
 			echo -e "\xE2\x9C\x94" NTP config file already updated.
		else

		#---------------------------------
		# The config files for ntp lies in /etc/ntp.conf
		# We are changing the Servers time to google's public NTP servers
		# Look here for more info : https://developers.google.com/time/guides#linux_ntpd
		#---------------------------------
			echo "" 
			echo -e "\xE2\x9C\x94" Modifying NTP config file
	
		#---------------------------------
		# Comment out the default pool servers.
		#---------------------------------
			sed -i 's/pool/#&/' /etc/ntp.conf
			sed -i 's/server/#&/' /etc/ntp.conf
		
		#---------------------------------
		# Add the new servers to the end of the file.	
		#---------------------------------
			sed -i "\$aserver time1.google.com iburst" /etc/ntp.conf
			sed -i "\$aserver time2.google.com iburst" /etc/ntp.conf
			sed -i "\$aserver time3.google.com iburst" /etc/ntp.conf
			sed -i "\$aserver time4.google.com iburst" /etc/ntp.conf
			
		#---------------------------------
		# Restart the NTP service.
		#---------------------------------
			echo "" 
			echo -e "\xE2\x9C\x94" Restarting NTP Service
			echo ""
			sudo systemctl stop ntp
			sleep 2
			sudo systemctl start ntp
			sleep 2
			sudo systemctl enable ntp
			sleep 2
 			sudo systemctl status ntp

 		#---------------------------------
 		# Sleep 5 seconds to give the service time to start and talk to the servers
		#---------------------------------
			echo ""
			echo -e "\xE2\x9C\x94" Waiting for NTP service to start
			sleep 5
		fi
		
		#---------------------------------
		# Show NTP servers
		#---------------------------------
		echo -e "\xE2\x9C\x94" Showing current NTP Servers
		echo ""
		ntpq -p 
		echo ""
		ntpstat
		echo ""

		echo ""
 	    echo "# Completed NTP Configuration on $(timestamp) #"
 	    echo ""

 	    echo ""
		echo "To view the log file: [ less $LOG_LOCATION/"${scriptname}".log ]"
		echo ""

#---------------------------------
# If neither Yum or Apt are installed, exit and have user manually install updates on their system.
#---------------------------------
else
	echo "Cannot determine installed packaging system, Please manually update." | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
 	exit 1;
fi