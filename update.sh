#!/bin/bash

#################################################################################################################
#
#       NAME: update.sh
#
#       AUTHOR:  B3nd3r
#
#       SUPPORT:  None
#
#       DESCRIPTION:  Update Linux Server
#
#       License: GPL-3.0
#       https://github.com/B3nd3r15/linuxscripts/blob/master/LICENSE
#
#################################################################################################################
#
#       ASSUMPTIONS: Script is run manually, target server has access to internet.
#
#################################################################################################################
#
#                 AUTHOR      DATE          COMMENTS
#                 ------      ----          --------
#  VER 0.1.0      B3nd3r      2019/01/23    Initial creation and release.
#
#################################################################################################################


#--------------------------
# Variables
#--------------------------

#---------------------------------
# Pulls the script name without directory paths
#---------------------------------
scriptname="$(basename "${0}")"

#---------------------------------
#       Run as Root
#---------------------------------

if (( EUID != 0 )); then
        sudo /home/"$USER"/"$scriptname"
        exit
fi

#---------------------------------
#       Set log Location
#---------------------------------
LOG_LOCATION=/var/log
exec > >(tee -ai $LOG_LOCATION/"${scriptname}".log )
exec 2>&1
echo ""

#----------------------------------
# Bash Colors
#----------------------------------
reset="\033[0m"
red="\033[0;31m"          # Red
green="\033[0;32m"        # Green
yellow="\033[0;33m"       # Yellow
blue="\033[0;34m"         # Blue
cyan="\033[0;36m"         # Cyan
#white="\033[0;37m"        # White
check="\xE2\x9C\x94"      # Check Mark

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
#       chronyd service
#---------------------------------
SERVICE=chronyd;

#---------------------------------
# Timestamp function
#---------------------------------
timestamp()
{
 date +"%Y-%m-%d %T"
}

#---------------------------------
#       Clear the screen
#---------------------------------
clear 
echo ""

abort()
{
  echo -e "\n${RED}###############################################################\n\n          An error occurred. Aborting script..\nPlease check the log file for errors!\n\n${RESET}"
  exit 1
}


ntpconfig() {

#-------------------------------------------------
# Checks to see if the config files need updated
#-------------------------------------------------
    if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
        echo -e "$green" "$check" NTP conf file already updated. "$reset"
    else
        echo -e "$yellow" "$check" Updating NTP conf file "$reset"


#------------------------------------------------------------------------------------
# The config files for ntp lies in /etc/ntp.conf
# We are changing the Servers time to google's public NTP servers
# Look here for more info : https://developers.google.com/time/guides#linux_ntpd
#-----------------------------------------------------------------------------------
        echo -e "$yellow" "$check" Modifying NTP config file "$reset"

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
        echo -e "$green" "$check" Restarting NTP Service "$reset"
        sudo systemctl stop ntpd || abort
        sleep 2
        sudo systemctl start ntpd || abort
        sleep 2
        sudo systemctl enable ntpd || abort
        sleep 2
        sudo systemctl status ntpd || abort
    fi

#-------------------------------------------------
# Give ntp service time to start up and talk to time*.google.com
#-------------------------------------------------
        sleep 5
        echo -e "$yellow" "$check" Waiting for NTP service to start "$reset"

#-------------------------------------------------
# Show NTP servers
#-------------------------------------------------
        echo -e "$green" "$check" Showing current NTP Servers "$reset"
        echo ""
        ntpq -p || abort
        echo ""
        ntpstat || abort
        echo ""

}

#---------------------------------
#       Yum Function
#---------------------------------
yumupdate() {

#---------------------------------
#       Update
#---------------------------------
        echo ""
        echo -e "$blue" "# Upgrading $osver on $(timestamp) #" "$reset"

#---------------------------------
#       Update Yum
#---------------------------------
        echo ""
        echo -e "$green" "$check" Updating Yum "$reset"
        yes | sudo yum update -y | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
#       Install Updates
#---------------------------------
        echo -e "$green" "$check" Installing Updates "$reset"
        yes | sudo yum upgrade | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
#       Clean up unused pacakages
#---------------------------------
        echo -e "$green" "$check" Cleaning Up Yum Packages "$reset"
        yes | sudo yum clean packages | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
#       Clean up Yum Metadata
#---------------------------------
        echo -e "$green" "$check" Cleaning Up Yum Metadata "$reset"
        yes | sudo yum clean metadata | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
#       Clean Yum DB Cache
#---------------------------------
        echo -e "$green" "$check" Cleaning Up Yum DBCache "$reset"
        yes | sudo yum clean dbcache | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
#       Clean anything leftover
#---------------------------------
        echo -e "$green" "$check" Cleaning up Yum Everything "$reset"
        yes | sudo yum clean all | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
#       Remove /var/cache/yum file
#---------------------------------
        echo -e "$green" "$check" Removing /var/cache/yum "$reset"
        yes | sudo rm -rf /var/cache/yum | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

        echo ""
        echo -e "$blue" "# End of Upgrade on $(timestamp) #" "$reset"
        echo ""

#---------------------------------
# Start disable of Chronyd Service #"
#---------------------------------
        if P=$(pgrep $SERVICE); then
                 echo -e "$red" "$SERVICE" is running, PID is "$P", Disabling chronyd service. "$reset"
                #Stop the Chronyd Service
                systemctl stop chronyd || abort
                #Disable chronyd so it cannot start if server reboots.
                systemctl disable chronyd || abort
        else
                echo -e "$green" "$check" "$SERVICE" is not running or has been disabled. "$reset"
        fi

#--------------------------------------------------------------------------------------
# Checks to see if NTP is installed. If it is, continues to check if the config file
#dified if not it will install it and update the config file
#-------------------------------------------------------------------------------------
        if yum list installed | grep ntp.x86_64 > /dev/null 2>&1; then
                echo ""
                echo -e "$green" "$check" NTP Successfully Installed "$reset"
        else
                echo -e "$yellow" "$check" Installing NTP "$reset"
                yes | sudo yum install ntp ntpd | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort
        fi

ntpconfig
##-------------------------------------------------
## Checks to see if the config files need updated
##-------------------------------------------------
#        if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
#                echo -e "$green" "$check" NTP conf file already updated. "$reset"
#        else
#                echo -e "$yellow" "$check" Updating NTP conf file "$reset"
#
#
##------------------------------------------------------------------------------------
## The config files for ntp lies in /etc/ntp.conf
## We are changing the Servers time to google's public NTP servers
## Look here for more info : https://developers.google.com/time/guides#linux_ntpd
##-----------------------------------------------------------------------------------
#                echo -e "$yellow" "$check" Modifying NTP config file "$reset"
#
##-------------------------------------------------
## Comment out the default pool servers.
##-------------------------------------------------
#                sed -i 's/pool/#&/' /etc/ntp.conf
#                sed -i 's/server/#&/' /etc/ntp.conf
#
##-------------------------------------------------
## Add the new servers to the end of the file.
##-------------------------------------------------
#                sed -i "\$aserver time1.google.com iburst" /etc/ntp.conf
#                sed -i "\$aserver time2.google.com iburst" /etc/ntp.conf
#                sed -i "\$aserver time3.google.com iburst" /etc/ntp.conf
#                sed -i "\$aserver time4.google.com iburst" /etc/ntp.conf
#
##-------------------------------------------------
## Restart, enable, and show the status of the service
##-------------------------------------------------
#                echo -e "$green" "$check" Restarting NTP Service "$reset"
#                sudo systemctl stop ntpd || abort
#                sleep 2
#                sudo systemctl start ntpd || abort
#                sleep 2
#                sudo systemctl enable ntpd || abort
#                sleep 2
#                sudo systemctl status ntpd || abort
#        fi

#-------------------------------------------------
# Give ntp service time to start up and talk to time*.google.com
#-------------------------------------------------
        sleep 5
        echo -e "$yellow" "$check" Waiting for NTP service to start "$reset"

#-------------------------------------------------
# Show NTP servers
#-------------------------------------------------
        echo -e "$green" "$check" Showing current NTP Servers "$reset"
        echo ""
        ntpq -p || abort
        echo ""
        ntpstat || abort
        echo ""

        echo ""
        echo -e "$cyan" To view the log file: [ less $LOG_LOCATION/"${scriptname}".log ] "$reset"
        echo ""
}

#---------------------------------
#       Apt Function
#---------------------------------
aptupdate() {

#---------------------------------
# Update all the things!
#---------------------------------
        echo ""
        echo -e "$blue" "# Upgrading $osver on $(timestamp) #" "$reset"
        echo ""

#---------------------------------
# Update all the repos.
#---------------------------------
        echo -e "$green" "$check" Updating Repos "$reset"
        yes | sudo apt-get update | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
# Upgrade all the things.
#---------------------------------
        echo -e "$green" "$check" Upgrading System "$reset"
        yes | sudo apt-get dist-upgrade | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
# Remove old software.
#---------------------------------
        echo -e "$green" "$check" Removing Unused Software "$reset"
        yes|sudo apt-get autoremove | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

#---------------------------------
# Purge config files
#---------------------------------
        echo -e "$green" "$check" Purging Leftover Config Files "$reset"
        apt-get purge -y "$(dpkg -l | awk '/^rc/ { print $2 }')" | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort

        echo ""
        echo -e "$blue" "# End of Upgrade on $(timestamp) #" "$reset"
        echo ""

#---------------------------------
# Ask user if they would like 
# to check for new LTS release
#---------------------------------
        if do-release-upgrade -c; then
                echo ""
                read -r -t 10 -p "Would you like to install the new LTS release?  " -e -i 'N' input
                yesno=${input:-n}
                echo ""
        case $yesno in
                [Yy]* ) do-release-upgrade || abort;;
                [Nn]* ) echo -e "$yellow" "Skipping Upgrade" "$reset";;
                * ) echo -e "$yellow" "Invalid option, Skipping Upgrade" "$reset";;
                esac
        else
                echo ""
                echo -e "$green" "No action taken." "$reset"
        fi

ntpconfig
##---------------------------------
## Checks to see if NTP is installed. If it is, continues to modify config file.
## if not it will install it.
##---------------------------------
#
#        if apt-get -qq install ntp ntpstat; then
#                echo ""
#                echo -e "$green" "$check" NTP Successfully Installed "$reset"
#        else
#                yes | sudo apt-get install ntp ntpstat | sudo tee -a $LOG_LOCATION/"${scriptname}".log || abort
#        fi
#
##---------------------------------
## Checks to see if the config files need updated
##---------------------------------
#        if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
#                echo -e "$green" "$check" NTP config file already updated. "$reset"
#        else
#
##---------------------------------
## The config files for ntp lies in /etc/ntp.conf
## We are changing the Servers time to google's public NTP servers
## Look here for more info : https://developers.google.com/time/guides#linux_ntpd
##---------------------------------
#                echo "" 
#                echo -e "$yellow" "$check" Modifying NTP config file "$reset"
#
##---------------------------------
## Comment out the default pool servers.
##---------------------------------
#                sed -i 's/pool/#&/' /etc/ntp.conf
#                sed -i 's/server/#&/' /etc/ntp.conf
#
##---------------------------------
## Add the new servers to the end of the file.
##---------------------------------
#                sed -i "\$aserver time1.google.com iburst" /etc/ntp.conf
#                sed -i "\$aserver time2.google.com iburst" /etc/ntp.conf
#                sed -i "\$aserver time3.google.com iburst" /etc/ntp.conf
#                sed -i "\$aserver time4.google.com iburst" /etc/ntp.conf
#
##---------------------------------
## Restart the NTP service.
##---------------------------------
#                echo ""
#                echo -e "$green" "$check" Restarting NTP Service "$reset"
#                echo ""
#                sudo systemctl stop ntp || abort
#                sleep 2
#                sudo systemctl start ntp || abort
#                sleep 2
#                sudo systemctl enable ntp || abort
#                sleep 2
#                sudo systemctl status ntp || abort

#---------------------------------
# Sleep 5 seconds to give the service time to start and talk to the servers
#---------------------------------
                echo ""
                echo -e "$yellow" "$check" Waiting for NTP service to start "$reset"
                sleep 5
        fi

#---------------------------------
# Show NTP servers
#---------------------------------
        echo -e "$green" "$check" Showing current NTP Servers "$reset"
        echo ""
        ntpq -p || abort
        echo ""
        ntpstat || abort
        echo ""

        echo ""
        echo -e "$cyan" "To view the log file: [ less $LOG_LOCATION/${scriptname}.log ]" "$reset"
        echo ""
}

#--------------------------------------------------
#       Determine Installed packaging system
#--------------------------------------------------
if [[ -n $YUM_CMD ]]; then
        yumupdate || abort

elif [[ -n $APT_GET_CMD ]]; then
        aptupdate || abort

#---------------------------------
# If neither Yum or Apt are installed, exit and have user manually install updates on their system.
#---------------------------------
else
        echo "Cannot determine installed packaging system, Please manually update."
        exit 1;
fi