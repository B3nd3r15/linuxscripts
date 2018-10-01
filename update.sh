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
scriptname=`echo $(basename ${0})`

#---------------------------------
# Sets the current date/time
#---------------------------------
date=`date +"%Y%m%d_%H%M%S"`

#---------------------------------
# Gets OS Version
#---------------------------------
osver=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)

#---------------------------------
# Gets Yum version
#---------------------------------
YUM_CMD=$(which yum)

#---------------------------------
# Gets Apt version
#---------------------------------
APT_GET_CMD=$(which apt-get)

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

if (( $EUID != 0 )); then
    sudo /home/$USER/$scriptname
        exit
fi

#---------------------------------
#	Clear the screen
#---------------------------------
clear 
echo ""

#---------------------------------
#	Set log Location
#---------------------------------
LOG_LOCATION=/var/log
exec > >(tee -ai $LOG_LOCATION/${scriptname}.log )
exec 2>&1
echo ""
echo "Log Location should be: [ $LOG_LOCATION ]"
echo ""

#--------------------------------------------------
#	Determine Installed packaging system
#--------------------------------------------------
if [[ ! -z $YUM_CMD ]]; then


		#---------------------------------
		#	Update
		#---------------------------------
		echo "" 
		echo "################################################################################" 
		echo "# Upgrading $osver on $(timestamp) #" 
		echo "################################################################################" 
		echo "" 
		
		#---------------------------------
		#	Update Yum
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Updating Yum
		echo ""
		yes | sudo yum update -y | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""
		
		#---------------------------------
		#	Install Updates
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Installing Updates
		echo ""
		yes | sudo yum upgrade | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""

		#---------------------------------
		#	Clean up unused pacakages
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Cleaning Up Yum Packages
		echo ""
		yes | sudo yum clean packages | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""

		#---------------------------------
		#	Clean up Yum Metadata
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Cleaning Up Yum Metadata
		echo ""
		yes | sudo yum clean metadata | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""

		#---------------------------------
		#	Clean Yum DB Cache
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Cleaning Up Yum DBCache
		echo ""
		yes | sudo yum clean dbcache | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""

		#---------------------------------
		#	Clean anything leftover
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Cleaning up Yum Everything
		echo ""
		yes | sudo yum clean all | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""

		#---------------------------------
		#	Remove /var/cache/yum file
		#---------------------------------
		echo ""
		echo -e "\xE2\x9C\x94" Removing /var/cache/yum
		yes | sudo rm -rf /var/cache/yum | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""

		echo "" 
		echo "################################################################################" 
		echo "# End of Upgrade on $(timestamp) #" 
		echo "################################################################################" 
		echo "" 

		echo ""
 	    echo "################################################################################"
 	    echo "# Configuring NTP on $(timestamp) #"
 	    echo "################################################################################"
 	    echo ""

    	#-------------------------------------------------------------------------------------
		# Checks to see if NTP is installed. If it is, continues to check if the config file
    	# is modified if not it will install it and update the config file
		#-------------------------------------------------------------------------------------
    	if yum list installed | grep ntp.x86_64 > /dev/null 2>&1 | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"; then
    		echo ""
    		echo -e "\xE2\x9C\x94" NTP Successfully Installed | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		else
			echo ""
    		echo -e "\xE2\x9C\x94" Installing NTP
    		yes | sudo yum install ntp | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		fi  

		#-------------------------------------------------
		# Checks to see if the config files need updated
		#-------------------------------------------------
		if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
 			echo ""
 			echo -e "\xE2\x9C\x94" NTP conf file already updated. | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		else
			echo ""
			echo -e "\xE2\x9C\x94" Updating NTP conf file | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
	

		#-----------------------------------------------------------------------------------
		# The config files for ntp lies in /etc/ntp.conf
		# We are changing the Servers time to google's public NTP servers
		# Look here for more info : https://developers.google.com/time/guides#linux_ntpd
		#-----------------------------------------------------------------------------------
			echo "" 
			echo -e "\xE2\x9C\x94" Modifying NTP config file | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
			
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
			echo -e "\xE2\x9C\x94" Restarting NTP Service | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
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
		echo -e "\xE2\x9C\x94" Waiting for NTP service to start | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"

		#-------------------------------------------------
		# Show NTP servers
		#-------------------------------------------------
		echo "" 
		echo -e "\xE2\x9C\x94" Showing current NTP Servers | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""
		ntpq -p
		echo ""

		echo ""
 	    echo "################################################################################"
 	    echo "# Completed NTP Configuration on $(timestamp) #"
 	    echo "################################################################################"
 	    echo ""

elif [[ ! -z $APT_GET_CMD ]]; then

		#---------------------------------
 	    # Update all the things!
		#---------------------------------
 		echo ""
  		echo "################################################################################"
  		echo "# Upgrading $osver on $(timestamp) #"
  		echo "################################################################################"
  		echo ""

  		#---------------------------------
	    # Update all the repos.
		#---------------------------------
   		echo ""
   		echo -e "\xE2\x9C\x94" Updating Repos 
   		echo ""
   		yes | sudo apt-get update | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
   		echo ""

   		#---------------------------------
 	    # Upgrade all the things.
		#---------------------------------
		echo ""
 		echo -e "\xE2\x9C\x94" Upgrading System 
 		echo ""
 		yes | sudo apt-get dist-upgrade | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
   		echo ""

   		#---------------------------------
	    # Remove old software.
		#---------------------------------
    	echo ""
 		echo -e "\xE2\x9C\x94" Removing Unused Software
 		echo ""
 		yes|sudo apt-get autoremove | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
    	echo ""

    	#---------------------------------
	    # Purge config files
		#---------------------------------
    	echo ""
 		echo -e "\xE2\x9C\x94" Purging Leftover Config Files 
 		echo ""
 		apt-get purge -y $(dpkg -l | awk '/^rc/ { print $2 }') | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
    	echo ""

    	echo ""
    	echo "################################################################################"
    	echo "# End of Upgrade on $(timestamp) #"
    	echo "################################################################################"
    	echo "" 

 	    echo ""
 	    echo "################################################################################"
 	    echo "# Configuring NTP on $(timestamp) #"
 	    echo "################################################################################"
 	    echo ""

 	    #---------------------------------
    	# Checks to see if NTP is installed. If it is, continues to modify config file.
    	# if not it will install it. 
		#---------------------------------
    	if apt-get -qq install ntp ntpstat; then 
    		echo ""
    		echo -e "\xE2\x9C\x94" NTP Successfully Installed | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		else
			echo ""
    		yes | sudo apt-get install ntp ntpstat | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		fi  

		#---------------------------------
		# Checks to see if the config files need updated
		#---------------------------------
		if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
 			echo ""
 			echo -e "\xE2\x9C\x94" NTP config file already updated. | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		else

		#---------------------------------
		# The config files for ntp lies in /etc/ntp.conf
		# We are changing the Servers time to google's public NTP servers
		# Look here for more info : https://developers.google.com/time/guides#linux_ntpd
		#---------------------------------
			echo "" 
			echo -e "\xE2\x9C\x94" Modifying NTP config file | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
	
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
			echo -e "\xE2\x9C\x94" Restarting NTP Service | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
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
			echo -e "\xE2\x9C\x94" Waiting for NTP service to start | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
			sleep 5
		fi
		
		#---------------------------------
		# Show NTP servers
		#---------------------------------
		echo "" 
		echo -e "\xE2\x9C\x94" Showing current NTP Servers | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""
		ntpq -p 
		echo ""

		echo ""
 	    echo "################################################################################"
 	    echo "# Completed NTP Configuration on $(timestamp) #"
 	    echo "################################################################################"
 	    echo ""

 	    echo ""
 	    echo "################################################################################"
 	    echo "# Checking for new LTS release on $(timestamp) #"
 	    echo "################################################################################"
 	    echo ""

    	#---------------------------------
		# Ask user if they would like to
		# check for new LTS release
		#---------------------------------
		if do-release-upgrade -c; then 
    		echo ""
    		read -p "Would you like to install the new LTS release? " yn
    		 case $yn in
       		 [Yy]* ) do-release-upgrade; break;;
     		 [Nn]* ) break;;
     	  		 * ) echo "Please answer yes or no.";;
			esac
		else
			echo ""
    		echo "No action taken."
		fi

		echo ""
 	    echo "################################################################################"
 	    echo "# Completed Checking for LTS release on $(timestamp) #"
 	    echo "################################################################################"
 	    echo ""

#---------------------------------
# If neither Yum or Apt are installed, exit and have user manually install updates on their system.
#---------------------------------
else
	echo "Cannot determine installed packaging system, Please manually update." | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
 	exit 1; 
fi