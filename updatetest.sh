#!/bin/bash

#################################################################################################################
#
#       NAME: update.sh
#
#       AUTHOR:  B3nd3r15
#
#       SUPPORT:  None
#
#       DESCRIPTION:  Update Linux Server,enable TCP BBR, and set NTP servers.
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
#    Version      AUTHOR      DATE          COMMENTS
#                 ------      ----          --------
#  VER 0.4.0      B3nd3r      2019/02/27    sent do-release-upgrade to /dev/null and added extra space in output for NTP.
#  VER 0.3.0      B3nd3r      2019/02/25    Created TCPBBR function to configure tcp to use bbr congestion control.
#  VER 0.2.0      B3nd3r      2019/02/18    sent echo commands to /dev/null so it doesn't fill up the screen.
#  VER 0.1.0      B3nd3r      2019/01/23    Initial creation and release.
#
#################################################################################################################

#---------------------------------------------------------------------------
# Get a string equal to the given string repeated the given number of times
# $1 = String to repeat
# $2 = Number of repetitions
#---------------------------------------------------------------------------
getRepeatedString()
{
  #initialize result string
  resultString=""

  #loop for number of repetitions
  for i in {2..71; do
    #append string to result string
    resultString="${resultString}${1}"
  done

  #return result string
  echo ${resultString}
}

#--------------------------
# Global Variables.
#--------------------------
setscriptvariables(){
#-----------------------------------------------
# Pulls the script name without directory paths.
#-----------------------------------------------
scriptname="$(basename "${0}")"

#---------------------------------
# Run as Root.
#---------------------------------
if (( EUID != 0 )); then
        sudo /home/"$USER"/"$scriptname"
        exit
fi

#---------------------------------
# Set log Location.
#---------------------------------
LOG_LOCATION=/var/log
exec > >(tee -ai $LOG_LOCATION/"${scriptname}".log )
exec 2>&1
echo ""

#----------------------------------
# Bash Colors.
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
# Gets OS Version.
#---------------------------------
osver=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)

#---------------------------------
# Gets Yum version.
#---------------------------------
YUM_CMD=$(command -v yum)

#---------------------------------
# Gets Apt version.
#---------------------------------
APT_GET_CMD=$(command -v apt-get)

#---------------------------------
# Chronyd service.
#---------------------------------
SERVICE=chronyd;

#---------------------------------
# Set line hash separator.
#---------------------------------
LINEHASHSEPARATOR=$(getRepeatedString "=" 71)
}

#---------------------------------
# Clear the screen.
#---------------------------------
clear 
echo ""

#---------------------------------
# Timestamp function.
#---------------------------------
timestamp()
{
 date +"%Y-%m-%d %T"
}

#---------------------------------
# Check kernel version function.
#---------------------------------
kernelversion(){
#--------------------------------------------------------
# Check kernel version to make sure it is 4.9 or higher.
#--------------------------------------------------------
KERNEL_VERSION=$(uname -r | awk 'BEGIN{ FS="."}; 
    { if ($1 < 4) { print "N"; } 
      else if ($1 == 4) { 
          if ($2 < 9) { print "N"; } 
          else { print "Y"; } 
      } 
      else { print "Y"; }
    }')

if [[ "$KERNEL_VERSION" == 'N' ]]; then
    current=$(uname -r)
    echo "Kernel required version is 4.9 your version is $current"
else
echo "Enable TCP BBR"

fi
}

ntpconfig() {
#------------------------------------------------------------------------------------
# The config files for ntp lies in /etc/ntp.conf
# We are changing the Servers time to google's public NTP servers.
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
}

#--------------------------------------------------
# This function enables TCP BBR congestion control.
#--------------------------------------------------
tcpbbr(){
#-------------------------------------------------
# Sysctl file to create for config.
#-------------------------------------------------
SYSCTL_FILE=/etc/sysctl.d/10-tcp-bbr.conf

#-------------------------------------------------
# Variable to check for current BBR Status.
#-------------------------------------------------
BBRSTATUS=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')

#---------------------------------
# TCP BBR Config.
#---------------------------------
        echo ""
        echo -e "$blue" "# TCP BBR Started on $osver on $(timestamp) #" "$reset"
        echo ""

#--------------------------------------------------------
# Check kernel version to make sure it is 4.9 or higher.
#--------------------------------------------------------
 KERNEL_VERSION=$(uname -r | awk 'BEGIN{ FS="."}; 
    { if ($1 < 4) { print "N"; } 
      else if ($1 == 4) { 
          if ($2 < 9) { print "N"; } 
          else { print "Y"; } 
      } 
      else { print "Y"; }
    }')

if [[ "$KERNEL_VERSION" == 'N' ]]; then
    current=$(uname -r)
    echo ""
    echo -e "$red" "$check" Kernel required version is 4.9 or higher, your version is $current "$reset"
else
    echo ""
    echo -e "$green" "$check" Your kernel version is greater than 4.9, directly setting TCP BBR! "$reset"

    if grep -q "tcp_bbr" "/etc/modules-load.d/modules.conf"; then
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
    fi

#-------------------------------------------------
# Display current configuration.
#-------------------------------------------------
    echo ""
    echo -e "$cyan" "$check" Current configuration: "$reset"
    sysctl net.ipv4.tcp_available_congestion_control
    sysctl net.ipv4.tcp_congestion_control

#----------------------------------------------------------------------
# Check BBR Status, if configured don't do anything, if not configure.
#----------------------------------------------------------------------
    if [[ x"${BBRSTATUS}" == x"bbr" ]]; then
        echo ""
        echo -e "$green" "$check" Look at that! BBR is already set up, Go grab a beer! "$reset"
    else

#-------------------------------------------------
# Apply new config.
#-------------------------------------------------
        echo ""
        echo -e "$yellow" "$check" Applying new configuration "$reset"
        #touch $SYSCTL_FILE
        if ! grep -q "net.core.default_qdisc=fq" "$SYSCTL_FILE"; then
            echo "net.core.default_qdisc=fq" >> $SYSCTL_FILE | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        fi
        if ! grep -q "net.ipv4.tcp_congestion_control=bbr" "$SYSCTL_FILE"; then
            echo "net.ipv4.tcp_congestion_control=bbr" >> $SYSCTL_FILE | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        fi

#-------------------------------------------------
# Check if we can apply the config now.
#-------------------------------------------------
        if lsmod | grep -q "tcp_bbr"; then
            sysctl -p $SYSCTL_FILE | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
            echo ""
            echo -e "$green" "$check" BBR is available now. "$reset"
        elif modprobe tcp_bbr; then
            sysctl -p $SYSCTL_FILE | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
            echo -e "$green" "$check" BBR is available now. "$reset"
        else
            echo -e "$red" BBR is not available now, Please reboot to enable BBR. "$reset"
        fi
    fi

fi

#---------------------------------
# End of TCP BBR Config.
#---------------------------------
        echo ""
        echo -e "$blue" "# TCP BBR Complete on $osver on $(timestamp) #" "$reset"
        echo ""
}

#---------------------------------
# Yum Function.
#---------------------------------
yumupdate() {

#---------------------------------
# Update all the things!
#---------------------------------
        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$blue" "# Upgrading $osver on $(timestamp) #" "$reset"
        echo "${LINEHASHSEPARATOR}"
        echo ""

#---------------------------------
# Clean up unused pacakages.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Cleaning Up Yum Packages "$reset"
        yes | sudo yum clean packages | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"
        echo ""
#---------------------------------
# Clean up Yum Metadata.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Cleaning Up Yum Metadata "$reset"
        yes | sudo yum clean metadata | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"
        echo ""
#---------------------------------
# Clean Yum DB Cache.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Cleaning Up Yum DBCache "$reset"
        yes | sudo yum clean dbcache | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"
        echo ""
#---------------------------------
# Clean anything leftover.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Cleaning up Yum Everything "$reset"
        yes | sudo yum clean all | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"
        echo ""
#---------------------------------
# Remove /var/cache/yum file.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Removing /var/cache/yum "$reset"
        yes | sudo rm -rf /var/cache/yum | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"
        echo ""
#---------------------------------
# Update Yum.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Updating Yum "$reset"
        yes | sudo yum update | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"
        echo ""
#---------------------------------
# Install Updates.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Installing Updates "$reset"
        yes | sudo yum upgrade | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"
        echo ""
#---------------------------------
# End of update section.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$blue" "# End of Upgrade on $(timestamp) #" "$reset"
        echo "${LINEHASHSEPARATOR}"
        echo ""

#----------------------------------
# Start disable of Chronyd Service.
#----------------------------------
        if P=$(pgrep $SERVICE); then
                 echo "${LINEHASHSEPARATOR}"
                 echo -e "$red" "$SERVICE" is running, PID is "$P", Disabling chronyd service. "$reset"
                 echo "${LINEHASHSEPARATOR}"
                # Stop the Chronyd Service
                systemctl stop chronyd
                # Disable chronyd so it cannot start if server reboots.
                systemctl disable chronyd
        else
                echo "${LINEHASHSEPARATOR}"
                echo -e "$green" "$check" "$SERVICE" is not running or has been disabled. "$reset"
                echo "${LINEHASHSEPARATOR}"
        fi

#--------------------------------------------------------------------------------------
# Checks to see if NTP is installed. If it is, continues to check if the config file
# is modified if not it will install it and update the config file.
#-------------------------------------------------------------------------------------
        if yum list installed | grep ntp.x86_64 > /dev/null 2>&1; then
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$green" "$check" NTP Successfully Installed "$reset"
                echo "${LINEHASHSEPARATOR}"
        else
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$yellow" "$check" Installing NTP "$reset"
                yes | sudo yum install ntp ntpd | sudo tee -a $LOG_LOCATION/"${scriptname}".log
                echo "${LINEHASHSEPARATOR}"
        fi

#-------------------------------------------------
# Checks to see if the config files need updated.
#-------------------------------------------------
        if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$green" "$check" NTP conf file already updated. "$reset"
                echo "${LINEHASHSEPARATOR}"
        else
                ntpconfig

#-----------------------------------------------------
# Restart, enable, and show the status of the service.
#-----------------------------------------------------
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$green" "$check" Restarting NTP Service "$reset"
                echo "${LINEHASHSEPARATOR}"

                sudo systemctl stop ntpd
                sleep 2
                sudo systemctl start ntpd
                sleep 2
                sudo systemctl enable ntpd
                sleep 2
                sudo systemctl status ntpd

#-----------------------------------------------------------------
# Give ntp service time to start up and talk to time*.google.com.
#-----------------------------------------------------------------
        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$yellow" "$check" Waiting for NTP service to start "$reset"
        echo "${LINEHASHSEPARATOR}"
        sleep 5

        fi
#-------------------------------------------------
# Show NTP servers.
#-------------------------------------------------
        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Showing current NTP Servers "$reset"
        echo "${LINEHASHSEPARATOR}"
        echo ""
        ntpq -p
        echo ""
        ntpstat
        echo ""
}

#---------------------------------
# Apt Function.
#---------------------------------
aptupdate() {

#---------------------------------
# Update all the things!
#---------------------------------
        echo ""
        echo -e "$blue" "# Upgrading $osver on $(timestamp) #" "$reset"
        echo ""

#---------------------------------
# Remove old software.
#---------------------------------
        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Removing Unused Software "$reset"
        yes|sudo apt-get autoremove | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"

#---------------------------------
# Purge config files.
#---------------------------------
        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Purging Leftover Config Files "$reset"
        apt-get purge -y "$(dpkg -l | awk '/^rc/ { print $2 }')" | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"

#---------------------------------
# Update all the repos.
#---------------------------------
        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Updating Repos "$reset"
        yes | sudo apt-get update | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"

#---------------------------------
# Upgrade all the things.
#---------------------------------
        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" Upgrading System "$reset"
        yes | sudo apt-get dist-upgrade | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        echo "${LINEHASHSEPARATOR}"

#---------------------------------
# End of update section.
#---------------------------------
        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$blue" "# End of Upgrade on $(timestamp) #" "$reset"
        echo "${LINEHASHSEPARATOR}"
        echo ""

#---------------------------------
# Ask user if they would like
# to check for new LTS release.
#---------------------------------
        if do-release-upgrade -c >> /dev/null; then
                echo ""
                echo "${LINEHASHSEPARATOR}"
                read -r -t 10 -p "Would you like to install the new LTS release?  " -e -i 'N' input
                yesno=${input:-n}
                echo "${LINEHASHSEPARATOR}"
                echo ""
        case $yesno in
                [Yy]* ) do-release-upgrade;;
                [Nn]* ) echo -e "$yellow" "Skipping Upgrade" "$reset";;
                * ) echo -e "$yellow" "Invalid option, Skipping Upgrade" "$reset";;
                esac
        else
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$green" "No new LTS release available or no action taken." "$reset"
                echo "${LINEHASHSEPARATOR}"
        fi

#----------------------------------------------
# Checks to see if NTP is installed.
# If it is, continues to modify config file,
# if not it will install it.
#----------------------------------------------

        if apt-get -qq install ntp ntpstat; then
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$green" "$check" "NTP Successfully Installed" "$reset"
                echo "${LINEHASHSEPARATOR}"
        else
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$yellow" "Installing NTP" "$reset"
                echo "${LINEHASHSEPARATOR}"
                yes | sudo apt-get install ntp ntpstat | sudo tee -a $LOG_LOCATION/"${scriptname}".log >> /dev/null 2>&1
        fi

#---------------------------------
# Checks to see if the config files need updated.
#---------------------------------
        if grep google.com /etc/ntp.conf > /dev/null 2>&1; then
                echo -e "$green" "$check" NTP config file already updated. "$reset"
        else
                ntpconfig
        fi

#---------------------------------
# Restart the NTP service.
#---------------------------------
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$green" "$check" Restarting NTP Service "$reset"
                echo "${LINEHASHSEPARATOR}"
                echo ""
                sudo systemctl stop ntp
                sleep 2
                sudo systemctl start ntp
                sleep 2
                sudo systemctl enable ntp
                sleep 2
                sudo systemctl status ntp

#----------------------------------------------------------------
# Give ntp service time to start up and talk to time*.google.com.
#----------------------------------------------------------------
                echo ""
                echo "${LINEHASHSEPARATOR}"
                echo -e "$yellow" "$check" Waiting for NTP service to start "$reset"
                echo "${LINEHASHSEPARATOR}"
                sleep 5

#---------------------------------
# Show NTP servers.
#---------------------------------
        echo "${LINEHASHSEPARATOR}"
        echo -e "$green" "$check" "Showing current NTP Servers" "$reset"
        echo "${LINEHASHSEPARATOR}"
        echo ""
        ntpq -p
        echo ""
        ntpstat
        echo ""

}

main(){

#--------------------------------------------------
# Set Sript Variables.
#--------------------------------------------------
setscriptvariables

#--------------------------------------------------
# Determine Installed packaging system.
#--------------------------------------------------
if [[ -n ${YUM_CMD} ]]; then
        yumupdate
        tcpbbr

        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$cyan" To view the log file: [ less $LOG_LOCATION/"${scriptname}".log ] "$reset"
        echo "${LINEHASHSEPARATOR}"
        echo ""

elif [[ -n $APT_GET_CMD ]]; then
        aptupdate
        tcpbbr

        echo ""
        echo "${LINEHASHSEPARATOR}"
        echo -e "$cyan" To view the log file: [ less $LOG_LOCATION/"${scriptname}".log ] "$reset"
        echo "${LINEHASHSEPARATOR}"
        echo ""

#-----------------------------------------------------------------------------------------------------
# If neither Yum or Apt are installed, exit and have user manually install updates on their system.
#-----------------------------------------------------------------------------------------------------
else
        echo "${LINEHASHSEPARATOR}"
        echo "Cannot determine installed packaging system, Please manually update."
        echo "${LINEHASHSEPARATOR}"
        exit 1;
fi

}

#call main function
main "${@}"