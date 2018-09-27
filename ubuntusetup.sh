#!/bin/bash

###################################################################
# Script Name: ubuntusetup.sh
#
# Date Created: 2018-09-01
#
# Description: This script will be a growing script as I use it to 
# install apps. This will be good for setting up new machines with
# the default apps I use. Make sure you run update.sh first to 
# update the server.
#
# Args: N/A
#
# Author:B3nd3r15
# Email:
#
# License: GPL-3.0  
# https://github.com/B3nd3r15/linuxscripts/blob/master/LICENSE
###################################################################


date=$(date)

# ask for password up-front.
sudo -v

#Backup ~/.bashrc
cp -p ~/.bashrc ~/.bashrc.bak

#Add script to show what packages need server reboot to ~/.bashrc

printf '
#shows which packages require the server to be rebooted
echo
if [ ! -f /var/run/reboot-required ]
then
echo "No packages requre reboot. Have a nice day :)"
else
package=$(cat /var/run/reboot-required.pkgs)
echo "[*** Hello $USER, your must reboot your machine because of the following package(s): $package ***]"
echo
fi
' >> ~/.bashrc

#Enable partner repositories

echo ""
echo "################################################################################"
echo "######## Enabling Partner Repos on $date #########"
echo "################################################################################"
echo ""

sudo sed -i.bak "/^# deb .*partner/ s/^# //" /etc/apt/sources.list
sudo apt-get update

echo ""
echo "################################################################################"
echo "######## End of Enabling Parter Repos on $date #########"
echo "################################################################################"
echo ""

#Download and install GetDeb and PlayDeb

echo ""
echo "################################################################################"
echo "######## Installing GetDeb and PlayDeb on $date #########"
echo "################################################################################"
echo ""

echo "Adding Getdeb Archive Key"
wget -q -O- http://archive.getdeb.net/getdeb-archive.key | sudo apt-key add -

echo "Downloading GetDeb and PlayDeb" &&
wget http://archive.getdeb.net/install_deb/getdeb-repository_0.1-1~getdeb1_all.deb http://archive.getdeb.net/install_deb/playdeb_0.3-1~getdeb1_all.deb &&

echo "Installing GetDeb" &&
sudo dpkg -i getdeb-repository_0.1-1~getdeb1_all.deb &&

echo "Installing PlayDeb" &&
sudo dpkg -i playdeb_0.3-1~getdeb1_all.deb &&

echo "Deleting Downloads" &&
rm -f getdeb-repository_0.1-1~getdeb1_all.deb &&
rm -f playdeb_0.3-1~getdeb1_all.deb

echo ""
echo "################################################################################"
echo "######## End of GetDeb and PlayDeb Install on $date #####"
echo "################################################################################"
echo ""

#Adding Personal Package Archives

echo ""
echo "################################################################################"
echo "######## Adding Personal Package Archives on $date ######"
echo "################################################################################"
echo ""

#VLC Repo
sudo add-apt-repository -y ppa:videolan/stable-daily

#Gimp Repo
sudo add-apt-repository -y ppa:otto-kesselgulasch/gimp

#Full Gnome Desktop Environment
sudo add-apt-repository -y ppa:gnome3-team/gnome3

#Java 8 Repo
sudo add-apt-repository -y ppa:webupd8team/java

#PPA Manager
sudo add-apt-repository -y ppa:webupd8team/y-ppa-manager

#LibDVSCSS Pepos
echo 'deb http://download.videolan.org/pub/debian/stable/ /' | sudo tee -a /etc/apt/sources.list.d/libdvdcss.list &&
echo 'deb-src http://download.videolan.org/pub/debian/stable/ /' | sudo tee -a /etc/apt/sources.list.d/libdvdcss.list &&
wget -O - http://download.videolan.org/pub/debian/videolan-apt.asc|sudo apt-key add -

#Sublime Text 3
#Install the GPG Key and use stable channel
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add - &&
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

#Cairo Dock Repo
sudo add-apt-repository ppa:cairo-dock-team/ppa


echo ""
echo "######################################################################################"
echo "######## End of Adding Personal Package Archives on $date #####"
echo "######################################################################################"
echo ""

#Checking for updates/upgrades.

echo ""
echo "################################################################################"
echo "######## Checking for Updates/Upgrades on $date #########"
echo "################################################################################"
echo ""

sudo apt-get update && sudo apt-get upgrade -y

echo ""
echo "#####################################################################################"
echo "######## End of Checking for Updates/Upgrades on $date #######"
echo "#####################################################################################"
echo ""

#Installing essential packages/libraries.

echo ""
echo "################################################################################"
echo "######## Installing Essentials on $date #################"
echo "################################################################################"
echo ""

sudo apt-get install synaptic vlc gimp gimp-data gimp-plugin-registry gimp-data-extras y-ppa-manager bleachbit oracle-java8-installer unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack arj cabextract file-roller mencoder flac faac faad sox ffmpeg2theora libmpeg2-4 uudeview mpeg3-utils mpegdemux liba52-dev mpeg2dec vorbis-tools id3v2 mpg321 mpg123 icedax lame libmad0 libjpeg-progs libdvdcss2 libdvdread4 libdvdnav4 ubuntu-restricted-extras ubuntu-wallpapers* apt-transport-https sublime-text libgconf-2-4 libappindicator1 


echo ""
echo "################################################################################"
echo "######## End of Installing Essentials on $date ##########"
echo "################################################################################"
echo ""

#Installing Google Chrome

echo ""
echo "################################################################################"
echo "######## Installing Google Chrome on $date ##############"
echo "################################################################################"
echo ""

#Add GPG Key
#wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

#Set Repo
#echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list

#Install Package
#sudo apt-get update && sudo apt-get install google-chrome-stable -y

#Try to automate install
if [[ $(getconf LONG_BIT) = "64" ]]
then
    echo "64bit Detected" &&
    echo "Installing Google Chrome" &&
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
    sudo dpkg -i google-chrome-stable_current_amd64.deb &&
    rm -f google-chrome-stable_current_amd64.deb
else
    echo "32bit Detected" &&
    echo "Installing Google Chrome" &&
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_i386.deb &&
    sudo dpkg -i google-chrome-stable_current_i386.deb &&
    rm -f google-chrome-stable_current_i386.deb
fi

echo ""
echo "################################################################################"
echo "######## End of Google Chrome Install on $date ##########"
echo "################################################################################"
echo ""

#Installing Discord.

echo ""
echo "################################################################################"
echo "######## Installing Discord on $date ####################"
echo "################################################################################"
echo ""

wget -O discord-0.0.2.deb https://dl.discordapp.net/apps/linux/0.0.2/discord-0.0.2.deb &&
sudo dpkg -i discord-0.0.2.deb &&
rm -f discord-0.0.2.deb

echo ""
echo "################################################################################"
echo "######## End of Discord Install on $date ################"
echo "################################################################################"
echo ""

#Cleanup

echo ""
echo "################################################################################"
echo "######## Begin Clean Up on $date ########################"
echo "################################################################################"
echo ""

sudo apt-get -f install &&

sudo apt-get autoremove &&

sudo apt-get -y autoclean &&

sudo apt-get -y clean

echo ""
echo "################################################################################"
echo "######## End of Clean Up on $date #######################"
echo "################################################################################"
echo ""

