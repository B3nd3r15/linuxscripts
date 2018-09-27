#!/bin/bash

###################################################################
# Script Name: welcomescript.sh
#
# Date Created: 2018-09-01
#
# Description: simple script i made that will say your name
#
# Args: N/A
#
# Author:B3nd3r15
# Email:
#
# License: GPL-3.0  
# https://github.com/B3nd3r15/linuxscripts/blob/master/LICENSE
###################################################################

#show the current time
time=$(date +"%T")

#set greeting array
arr[0]="Hey "
arr[1]="How's it going "
arr[2]="Sup "

#randomize the greetings.
rand=$[ $RANDOM % 3 ]
#echo ${arr[$rand]}

#check to see if the argument passed equals Blake or blake
if [ "$1" == "B3nd3r15" ] || [ "$1" == "b3nd3r15" ]
then
echo
#If it does then say HEY.
echo "Hey! My name is B3nd3r15 too!"
      else
      echo
      #otherwise ask who am I talking to.
      echo Who am I talking to?
        #get the users name
        read varname
      echo
      #say it back
      echo ${arr[$rand]} $varname.
fi

echo
#show the PID of this script for debugging purposes. Will remove when final version released.
echo The PID of the script is: $$ and the current time is $time
echo
