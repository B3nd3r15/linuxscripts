#/bin/bash

###################################################################
# Script Name: systeminfo.sh
#
# Date Created: 2018-09-01
#
# Description: script that will show various system information.
# original file from oToGamez at www.pro-toolz.net
#
# Args: N/A
#
# Author:B3nd3r15
# Email:
#
# License: GPL-3.0  
# https://github.com/B3nd3r15/linuxscripts/blob/master/LICENSE
###################################################################

      E='echo -e';e='echo -en';trap "R;exit" 2
    ESC=$( $e "\e")
   TPUT(){ $e "\e[${1};${2}H";}
  CLEAR(){ $e "\ec";}
  CIVIS(){ $e "\e[?25l";}
   DRAW(){ $e "\e%@\e(0";}
  WRITE(){ $e "\e(B";}
   MARK(){ $e "\e[7m";}
 UNMARK(){ $e "\e[27m";}
      R(){ CLEAR ;stty sane;$e "\ec\e[37;44m\e[J";};
   HEAD(){ DRAW
           for each in $(seq 1 17);do
           $E "   x                                          x"
           done
           WRITE;MARK;TPUT 1 5
           $E "BASH SELECTION MENU                       ";UNMARK;}
           i=0; CLEAR; CIVIS;NULL=/dev/null
   FOOT(){ MARK;TPUT 17 5
           printf "ENTER - SELECT,NEXT                       ";UNMARK;}
  ARROW(){ read -s -n3 key 2>/dev/null >&2
           if [[ $key = $ESC[A ]];then echo up;fi
           if [[ $key = $ESC[B ]];then echo dn;fi;}
     M0(){ TPUT  4 20; $e "Uptime";}
     M1(){ TPUT  5 20; $e "Login info";}
     M2(){ TPUT  6 20; $e "Last Logins";}
     M3(){ TPUT  7 20; $e "Network";}
     M4(){ TPUT  8 20; $e "Disk";}
     M5(){ TPUT  9 20; $e "Routing";}
     M6(){ TPUT  10 20; $e "Show Running Cron Jobs";}
     M7(){ TPUT  11 20; $e "Update the System";}
     M8(){ TPUT  12 20; $e "Time";}
     M9(){ TPUT  13 20; $e "ABOUT  ";}
     M10(){ TPUT  14 20; $e "EXIT   ";}
      LM=10
   MENU(){ for each in $(seq 0 $LM);do M${each};done;}
    POS(){ if [[ $cur == up ]];then ((i--));fi
           if [[ $cur == dn ]];then ((i++));fi
           if [[ $i -lt 0   ]];then i=$LM;fi
           if [[ $i -gt $LM ]];then i=0;fi;}
REFRESH(){ after=$((i+1)); before=$((i-1))
           if [[ $before -lt 0  ]];then before=$LM;fi
           if [[ $after -gt $LM ]];then after=0;fi
           if [[ $j -lt $i      ]];then UNMARK;M$before;else UNMARK;M$after;fi
           if [[ $after -eq 0 ]] || [ $before -eq $LM ];then
           UNMARK; M$before; M$after;fi;j=$i;UNMARK;M$before;M$after;}
   INIT(){ R;HEAD;FOOT;MENU;}
     SC(){ REFRESH;MARK;$S;$b;cur=`ARROW`;}
     ES(){ MARK;$e "ENTER = main menu ";$b;read;INIT;};INIT
  while [[ "$O" != " " ]]; do case $i in
        0) S=M0;SC;if [[ $cur == "" ]];then R;$e "\n$(uptime                                            )\n";ES;fi;;
        1) S=M1;SC;if [[ $cur == "" ]];then R;$e "\n$(w                                                 )\n";ES;fi;;
        2) S=M2;SC;if [[ $cur == "" ]];then R;$e "\n$(last -a |head -3                                  )\n";ES;fi;;
        3) S=M3;SC;if [[ $cur == "" ]];then R;$e "\n$(ifconfig                                          )\n";ES;fi;;
        4) S=M4;SC;if [[ $cur == "" ]];then R;$e "\n$(df -h                                             )\n";ES;fi;;
        5) S=M5;SC;if [[ $cur == "" ]];then R;$e "\n$(route -n                                          )\n";ES;fi;;
        6) S=M6;SC;if [[ $cur == "" ]];then R;$e "\n$(ps -o pid,sess,cmd afx | egrep "( |/)cron( -f)?$" )\n";ES;fi;;
        7) S=M7;SC;if [[ $cur == "" ]];then R;$e "\n$(sudo apt-get update && sudo apt-get install -y    )\n";ES;fi;;
        8) S=M8;SC;if [[ $cur == "" ]];then R;$e "\n$(date                                              )\n";ES;fi;;
        9) S=M9;SC;if [[ $cur == "" ]];then R;$e "\n$($e by B3nd3r                                      )\n";ES;fi;;
        10) S=M10;SC;if [[ $cur == "" ]];then R;exit 0;fi;;
 esac;POS;done
