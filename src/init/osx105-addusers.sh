#! /bin/bash
# By Spransy, Derek" <DSPRANS () emory ! edu> and Charlie Scott

#####
# This checks for an error and exits with a custom message
# Returns zero on success
# $1 is the message
# $2 is the error code

if [[ ! -f "/usr/bin/dscl" ]]
  then
  echo "Error, I have no dscl, dying here";
  exit
fi

DSCL="/usr/bin/dscl";

function check_errm
{
   if  [[ ${?} != "0" ]]
      then
      echo "${1}";
      exit ${2};
      fi
}

# get unique id numbers (uid, gid) that are greater than 100
unset -v i new_uid new_gid idvar;
declare -i new_uid=0 new_gid=0 i=100 idvar=0;
while [[ $idvar -eq 0 ]]; do
   i=$[i+1]
   j=$[i+1]
   k=$[i+2]
   if [[ -z "$(/usr/bin/dscl . -search /Users uid ${i})" ]] && [[ -z "$(/usr/bin/dscl . -search /Groups gid ${i})" ]] && \
      [[ -z "$(/usr/bin/dscl . -search /Users uid ${j})" ]] && [[ -z "$(/usr/bin/dscl . -search /Groups gid ${j})" ]] && \
      [[ -z "$(/usr/bin/dscl . -search /Users uid ${k})" ]] && [[ -z "$(/usr/bin/dscl . -search /Groups gid ${k})" ]];
      then
      new_uid=$i
      new_gid=$i
      idvar=1
      #break
   fi
done

echo "UIDs available are:";
echo ${new_uid}
echo ${j}
echo ${k}

# Verify that the uid and gid exist and match
if [[ $new_uid -eq 0 ]] || [[ $new_gid -eq 0 ]];
   then
   echo "Getting unique id numbers (uid, gid) failed!";
   exit 1;
   fi
if [[ ${new_uid} != ${new_gid} ]]
   then
   echo "I failed to find matching free uid and gid!";
   exit 5;
   fi


# Creating the groups.
sudo ${DSCL} localhost -create /Local/Default/Groups/openarmor
check_errm "Error creating group openarmor" "67"
sudo ${DSCL} localhost -createprop /Local/Default/Groups/openarmor PrimaryGroupID ${new_gid}
sudo ${DSCL} localhost -createprop /Local/Default/Groups/openarmor RealName openarmor
sudo ${DSCL} localhost -createprop /Local/Default/Groups/openarmor RecordName openarmor
sudo ${DSCL} localhost -createprop /Local/Default/Groups/openarmor RecordType: dsRecTypeStandard:Groups
sudo ${DSCL} localhost -createprop /Local/Default/Groups/openarmor Password "*"


# Creating the users.

if [[ $(dscl . -read /Users/openarmorm) ]]
   then
   echo "openarmorm already exists";
else
   sudo ${DSCL} localhost -create /Local/Default/Users/openarmorm
   check_errm "Error creating user openarmorm" "87"
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorm RecordName openarmorm
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorm RealName "openarmormacct"
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorm NFSHomeDirectory /var/openarmor
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorm UniqueID ${j}
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorm PrimaryGroupID ${new_gid}
   sudo ${DSCL} localhost -append /Local/Default/Groups/openarmor GroupMembership openarmorm
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorm Password "*"
fi

if [[ $(dscl . -read /Users/openarmorr) ]]
   then
   echo "openarmorr already exists";
else
   sudo ${DSCL} localhost -create /Local/Default/Users/openarmorr
   check_errm "Error creating user openarmorr" "97"
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorr RecordName openarmorr
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorr RealName "openarmorracct"
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorr NFSHomeDirectory /var/openarmor
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorr UniqueID ${k}
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorr PrimaryGroupID ${new_gid}
   sudo ${DSCL} localhost -append /Local/Default/Groups/openarmor GroupMembership openarmorr
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmorr Password "*"
fi

if [[ $(dscl . -read /Users/openarmor) ]]
   then
   echo "openarmor already exists";
else
   sudo ${DSCL} localhost -create /Local/Default/Users/openarmor
   check_errm "Error creating user openarmor" "77"
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmor RecordName openarmor
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmor RealName "openarmoracct"
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmor NFSHomeDirectory /var/openarmor
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmor UniqueID ${new_uid}
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmor PrimaryGroupID ${new_gid}
   sudo ${DSCL} localhost -append /Local/Default/Groups/openarmor GroupMembership openarmor
   sudo ${DSCL} localhost -createprop /Local/Default/Users/openarmor Password "*"
fi

