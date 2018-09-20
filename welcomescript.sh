# This script will say your name

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
if [ "$1" == "Blake" ] || [ "$1" == "blake" ]
then
echo
#If it does then say HEY.
echo "Hey! My name is Blake too!"
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
