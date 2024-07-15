#!/bin/sh
# Author: Gianni D'Aprile

GREP=`which grep`

ACTION=$1
USER=$2
IP=$3

# Finding path
LOCAL=`dirname $0`;
cd $LOCAL
cd ../
PWD=`pwd`
echo "`date` $0 $1 $2 $3 $4 $5" >> ${PWD}/../logs/active-responses.log

NPFCTL=/sbin/npfctl

if [ ! -x ${NPFCTL} ]; then
	echo "$0: NPF not present."
	echo "$0: NPF not present." >> ${PWD}/openarmor-hids-responses.log
	exit 0;
fi

NPF_ACTIVE=`${NPFCTL} show | grep "filtering:" | ${GREP} -c active`

if [ "x1" != "x${NPF_ACTIVE}" ]; then
	echo "$0: NPF not active."
	echo "$0: NPF not active." >> ${PWD}/openarmor-hids-responses.log
	exit 0;
fi

NPF_openarmor_READY=`${NPFCTL} show | ${GREP} -c "table <openarmor_blacklist>"`

if [ "x1" != "x${NPF_openarmor_READY}" ]; then
	echo "$0: NPF not configured."
	echo "$0: NPF not configured." >> ${PWD}/openarmor-hids-responses.log
	exit 0;
fi

# Checking for an IP
if [ "x${IP}" = "x" ]; then
   echo "$0: <action> <username> <ip>" 
   exit 1;
fi

case "x${ACTION}" in

	# Blocking IP
	xadd)

	${NPFCTL} table openarmor_blacklist add ${IP} >/dev/null 2>&1
	exit 0

	;;

	# Unblocking IP
	xdelete)

	${NPFCTL} table openarmor_blacklist del ${IP} >/dev/null 2>&1
	exit 0

	;;

	# No matching action
	*)

	echo "$0: invalid action: ${ACTION}"
	echo "$0: invalid action: ${ACTION}" >> ${PWD}/openarmor-hids-responses.log
 	exit 1

	;;

esac
