#!/usr/bin/env bash
#title           : shadow.sh
#description     : This script will take two arguments, first one is for shadow file (format should be identical to /etc/shadow file)
#                  and the last one is user_list (which can be separated by comma or newline EX: user1, user2).
#author          : Md. Noman
#date            : 10-Sep-2017
#version         : 0.3
#usage           : ./shadow.sh shadow user_list
#Command to collect user names from passwd file:  cut -d ":" -f1 /etc/passwd | sed -n  '/first_user/,$p' > user_list   # Please check the list before executing the script
#==============================================================================================================================================================

usage="./shadow.sh shadow user_list"
RED='\033[0;31m'
GREEN_U='\033[4;32m'
GREEN='\033[0;32m'
#Reset colour
NC='\033[0m'

#Check positional parameter
[ $# -lt 2 ] && echo "Encrypted password and list of usernames' files are mandatory" && echo -e "${RED}Script usage:$NC $usage" && exit 1
[ $# -gt 2 ] && echo "Only two positional parameters are allowed"  && echo -e "${RED}Script usage:$NC $usage" && exit 1

#Argument names are fixed, so that we can avoid some extra checking
[ $1 != "shadow" ] && echo "First argument name (Shadow file) should be shadow" && exit 1
[ $2 != "user_list" ] && echo "Second argument name (User names file) should be user_list" && exit 1

#check given shadow file or user_list file is available or not
[ ! -r "$1" ] ||  [ ! -f "$1" ] && echo "!!!No File named \"$1\" is found or check your permission" && exit 1
[ ! -r "$2" ] ||  [ ! -f "$2" ] && echo "!!!No File named \"$2\" is found or check your permission" && exit 1

#Make a backup of existing shadow file
cp -p /etc/shadow /etc/shadow.$(date +"%F").bk

for u_name in `sed "s/, */ /g" $2`;do
        #if user name is in given shadow file then proceed, else print name not found and skip
        if result=`grep "^$u_name:\\\\$" $1`;then
                #if user name is in /etc/shadow then proceed, if not then print messege and skip
                if grep -q "^$u_name:" /etc/shadow;then
                        #Set shadow only if it is not already set
                        if ! grep -q "^$u_name:\\$" /etc/shadow;then
                                shadow_pass=$(echo $result | cut -d":" -f2)
                                sed -i  "s>\(^$u_name:\)\([^:]*\)\(.*\)>\1$shadow_pass\3>" /etc/shadow
                        fi
                else
                        echo -e "User name $RED $u_name $NC is not found"
                fi
        else
                echo  -e "User name $RED$u_name $NC is not found in your given shadow file or password is not there"
        fi
done

cmp -s /etc/shadow /etc/shadow.$(date +"%F").bk && echo -e "${GREEN}Shadow Files is already updated${NC}" || (printf "Following Lines are Updated\n${GREEN_U}Update${NC}\t\t\t\t\t\t\t\t\t | ${GREEN_U}Original${NC}\n";sdiff -s -w $(tput cols) /etc/shadow /etc/shadow.$(date +"%F").bk)
