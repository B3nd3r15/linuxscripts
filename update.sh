#!/bin/bash

#----------------------------------
#			VARIABLES
#----------------------------------

# Pulls the script name without directory paths
scriptname=`echo $(basename ${0})`

# Sets the current date/time
date=`date +"%Y%m%d_%H%M%S"`

# Gets OS Version
osver=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)

# Gets Yum version
YUM_CMD=$(which yum)

# Gets Apt version
APT_GET_CMD=$(which apt-get)

# Timestamp function
timestamp()
{
 date +"%Y-%m-%d %T"
}

#---------------------------------
#			Run as Root
#---------------------------------

# if not root, run as root
if (( $EUID != 0 )); then
    sudo /home/$USER/$scriptname
        exit
fi


#---------------------------------
#			Clear the screen
#---------------------------------

# Clear the screen
clear 
echo ""

#---------------------------------
#			Set log Location
#---------------------------------

# Log Location on Server
LOG_LOCATION=/var/log
exec > >(tee -ai $LOG_LOCATION/${scriptname}.log )
exec 2>&1
echo ""
echo "Log Location should be: [ $LOG_LOCATION ]"
echo ""

#--------------------------------------------------
#			Determine Installed packaging system
#--------------------------------------------------


if [[ ! -z $YUM_CMD ]]; then


		#---------------------------------
		#			Update
		#---------------------------------
		
		# Update all the things!
		
		echo "" 
		echo "################################################################################" 
		echo "# Upgrading $osver on $(timestamp) #" 
		echo "################################################################################" 
		echo "" 
		
		
		# Update yum
		echo "Updating Yum"
		yes | sudo yum update -y | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		
		# Install updates
		echo "Installing Updates"
		yes | sudo yum upgrade | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		
		# Clean up unused pacakages
		echo "Cleaning Up Yum Packages"
		yes | sudo yum clean packages | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		
		# Clean up Yum Metadata
		echo "Cleaning Up Yum Metadata"
		yes | sudo yum clean metadata | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		
		# Clean Yum DB Cache
		echo "Cleaning Up Yum DBCache"
		yes | sudo yum clean dbcache | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		
		# Clean anything leftover
		echo "Cleaning up Yum Everything"
		yes | sudo yum clean all | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		yes | sudo rm -rf /var/cache/yum | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		
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

    	# Install NTP Service to be configured later.
	    echo ""
 	    echo -e "\xE2\x9C\x94" Installing NTP Service
 	    yes | sudo yum install ntp | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
 	    echo ""

 	    # The config files for ntp lies in /etc/ntp.conf.
		# We are changing the Servers time to google's public NTP servers.
		# Look here for more info : https://developers.google.com/time/guides#linux_ntpd
		echo "" 
		echo -e "\xE2\x9C\x94" Modifying /etc/ntp.conf file
		sed -i '/# Specify one or more NTP servers./a server time1.google.com iburst' /etc/ntp.conf
		sed -i '/server time1.google.com iburst/a server time2.google.com iburst' /etc/ntp.conf
		sed -i '/server time2.google.com iburst/a server time3.google.com iburst' /etc/ntp.conf
		sed -i '/server time3.google.com iburst/a server time4.google.com iburst' /etc/ntp.conf

		# Comment out the default pool servers.
		sed -i 's/pool/#&/' /etc/ntp.conf

		# Restart the service.
		echo "" 
		echo -e "\xE2\x9C\x94" Restarting NTP Service
		sudo systemctl stop ntpd | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		sudo systemctl start ntpd | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		sudo systemctl enable ntpd | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
 		sudo systemctl status ntpd | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		sleep 5

		# Show NTP servers
		echo "" 
		echo -e "\xE2\x9C\x94" Showing current NTP Servers
		echo ""
		ntpq -p | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""

		echo ""
 	    echo "################################################################################"
 	    echo "# Completed NTP Configuration on $(timestamp) #"
 	    echo "################################################################################"
 	    echo ""

elif [[ ! -z $APT_GET_CMD ]]; then

		#---------------------------------
		#			Update
		#---------------------------------

 	    # Update all the things!
 		echo ""
  		echo "################################################################################"
  		echo "# Upgrading $osver on $(timestamp) #"
  		echo "################################################################################"
  		echo ""

	    # Update all the repos.
   		echo ""
   		echo -e "\xE2\x9C\x94" Updating Repos 
   		yes | sudo apt-get update | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
   		echo ""

 	    # Upgrade all the things.
		echo ""
 		echo -e "\xE2\x9C\x94" Upgrading System 
 		yes | sudo apt-get dist-upgrade | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
   		echo ""

	    # Remove old software.
    	echo ""
 		echo -e "\xE2\x9C\x94" Removing Unused Software
 		yes|sudo apt-get autoremove | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
    	echo ""

	    # Purge config files
    	echo ""
 		echo -e "\xE2\x9C\x94" Purging Leftover Config Files 
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

    	# Install NTP Service to be configured later.
	    echo ""
 	    echo -e "\xE2\x9C\x94" Installing NTP Service
 	    yes | sudo apt-get install ntp | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
 	    echo ""

 	    # The config files for ntp lies in /etc/ntp.conf.
		# We are changing the Servers time to google's public NTP servers.
		# Look here for more info : https://developers.google.com/time/guides#linux_ntpd
		echo "" 
		echo -e "\xE2\x9C\x94" Modifying /etc/ntp.conf file
		sed -i '/# Specify one or more NTP servers./a server time1.google.com iburst' /etc/ntp.conf
		sed -i '/server time1.google.com iburst/a server time2.google.com iburst' /etc/ntp.conf
		sed -i '/server time2.google.com iburst/a server time3.google.com iburst' /etc/ntp.conf
		sed -i '/server time3.google.com iburst/a server time4.google.com iburst' /etc/ntp.conf

		# Comment out the default pool servers.
		sed -i 's/pool/#&/' /etc/ntp.conf

		# Restart the service.
		echo "" 
		echo -e "\xE2\x9C\x94" Restarting NTP Service
		sudo service ntp stop | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		sudo service ntp start | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		sleep 5

		# Show NTP servers
		echo "" 
		echo -e "\xE2\x9C\x94" Showing current NTP Servers
		echo ""
		ntpq -p | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
		echo ""

		echo ""
 	    echo "################################################################################"
 	    echo "# Completed NTP Configuration on $(timestamp) #"
 	    echo "################################################################################"
 	    echo ""

# If neither Yum or Apt are installed, exit and have user manually install updates on their system.
else
	echo "Cannot determine installed packaging system, Please manually update." | sed "s/$/ [$(date +"%Y-%m-%d %T")]/"
 	exit 1; 
fi