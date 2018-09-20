#!/bin/bash

#This will restart wordpress.

#Logfile Location.
LOGFILE=/home/beaton0506/log/restartwordpress.log

#Make whole script output to log.
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$LOGFILE 2>&1


#start log.
echo
echo "$(date -u) : Starting Restart"

#Stop apache2.
echo "Stopping apache2."
sudo systemctl stop apache2
echo

#Wait 2 seconds before stopping mysql.
sleep 2

#Stop mysql.
echo "Stopping mysql."
sudo systemctl stop mysqld
echo

#Wait 2 seconds before starting mysql.
sleep 2

#Start mysql.
echo "Starting mysql."
sudo systemctl start mysqld
echo

#Wait 2 seconds before starting apache.
sleep 2

#Start apache2. 
echo "Starting apache2."
sudo systemctl start apache2
echo

#Finished Log

echo "$(date "+%m%d%Y %T") : Finished"
echo
