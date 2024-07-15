#!/bin/sh
# openarmor-control        This shell script takes care of starting
#                      or stopping openarmor-hids
# Author: Daniel B. Cid <daniel.cid@gmail.com>

# Getting where we are installed
LOCAL=`dirname $0`;
cd ${LOCAL}
PWD=`pwd`
DIR=`dirname $PWD`;
PLIST=${DIR}/bin/.process_list;

###  Do not modify below here ###

# Getting additional processes
ls -la ${PLIST} > /dev/null 2>&1
if [ $? = 0 ]; then
. ${PLIST};
fi

NAME="openarmor HIDS"
VERSION="v3.8.0"

[ -f /etc/openarmor-init.conf ] && . /etc/openarmor-init.conf;

DAEMONS="openarmor-monitord openarmor-logcollector openarmor-remoted openarmor-syscheckd openarmor-analysisd openarmor-maild openarmor-execd ${DB_DAEMON} ${CSYSLOG_DAEMON} ${AGENTLESS_DAEMON}"

## Locking for the start/stop
LOCK="${DIR}/var/start-script-lock"
LOCK_PID="${LOCK}/pid"

# This number should be more than enough (even if it is
# started multiple times together). It will try for up
# to 10 attempts (or 10 seconds) to execute.
MAX_ITERATION="10"

checkpid()
{
    for i in ${DAEMONS}; do
        for j in `cat ${DIR}/var/run/${i}*.pid 2>/dev/null`; do
            ps -p $j |grep openarmor >/dev/null 2>&1
            if [ ! $? = 0 ]; then
                echo "Deleting PID file '${DIR}/var/run/${i}-${j}.pid' not used..."
                rm ${DIR}/var/run/${i}-${j}.pid
            fi
        done
    done
}

lock()
{
    i=0;

    # Providing a lock.
    while [ 1 ]; do
        mkdir ${LOCK} > /dev/null 2>&1
        MSL=$?
        if [ "${MSL}" = "0" ]; then
            # Lock acquired (setting the pid)
            echo "$$" > ${LOCK_PID}
            return;
        fi

        # Waiting 1 second before trying again
        sleep 1;
        i=`expr $i + 1`;

        # If PID is not present, speed things a bit.
        kill -0 `cat ${LOCK_PID}` >/dev/null 2>&1
        if [ ! $? = 0 ]; then
            # Pid is not present.
            i=`expr $i + 1`;
        fi

        # We tried 10 times to acquire the lock.
        if [ "$i" = "${MAX_ITERATION}" ]; then
            # Unlocking and executing
            unlock;
            mkdir ${LOCK} > /dev/null 2>&1
            echo "$$" > ${LOCK_PID}
            return;
        fi
    done
}

unlock()
{
    rm -rf ${LOCK}
}

help()
{
    # Help message
    echo ""
    echo "Usage: $0 {start|stop|reload|restart|status|enable|disable}";
    exit 1;
}

# Enables additional daemons
enable()
{
    if [ "X$2" = "X" ]; then
        echo ""
        echo "Enable options: database, client-syslog, agentless, debug"
        echo "Usage: $0 enable [database|client-syslog|agentless|debug]"
        exit 1;
    fi

    if [ "X$2" = "Xdatabase" ]; then
        echo "DB_DAEMON=openarmor-dbd" >> ${PLIST};
    elif [ "X$2" = "Xclient-syslog" ]; then
        echo "CSYSLOG_DAEMON=openarmor-csyslogd" >> ${PLIST};
    elif [ "X$2" = "Xagentless" ]; then
        echo "AGENTLESS_DAEMON=openarmor-agentlessd" >> ${PLIST};
    elif [ "X$2" = "Xdebug" ]; then
        echo "DEBUG_CLI=\"-d\"" >> ${PLIST};
    else
        echo ""
        echo "Invalid enable option."
        echo ""
        echo "Enable options: database, client-syslog, agentless, debug"
        echo "Usage: $0 enable [database|client-syslog|agentless|debug]"
        exit 1;
    fi
}

# Disables additional daemons
disable()
{
    if [ "X$2" = "X" ]; then
        echo ""
        echo "Disable options: database, client-syslog, agentless, debug"
        echo "Usage: $0 disable [database|client-syslog|agentless|debug]"
        exit 1;
    fi

    if [ "X$2" = "Xdatabase" ]; then
        echo "DB_DAEMON=\"\"" >> ${PLIST};
    elif [ "X$2" = "Xclient-syslog" ]; then
        echo "CSYSLOG_DAEMON=\"\"" >> ${PLIST};
    elif [ "X$2" = "Xagentless" ]; then
        echo "AGENTLESS_DAEMON=\"\"" >> ${PLIST};
    elif [ "X$2" = "Xdebug" ]; then
        echo "DEBUG_CLI=\"\"" >> ${PLIST};
    else
        echo ""
        echo "Invalid disable option."
        echo ""
        echo "Disable options: database, client-syslog, agentless, debug"
        echo "Usage: $0 disable [database|client-syslog|agentless|debug]"
        exit 1;
    fi
}

status()
{
    RETVAL=0
    for i in ${DAEMONS}; do
        ## If openarmor-maild is disabled, don't try to start it.
        if [ X"$i" = "Xopenarmor-maild" ]; then
            grep "<email_notification>no<" ${DIR}/etc/openarmor.conf >/dev/null 2>&1
            if [ $? = 0 ]; then
                continue
            fi
        fi

        pstatus ${i};
        if [ $? = 0 ]; then
            echo "${i} not running..."
            RETVAL=1
        else
            echo "${i} is running..."
        fi
    done
    exit $RETVAL
}

testconfig()
{
    # We first loop to check the config.
    for i in ${SDAEMONS}; do
        ${DIR}/bin/${i} -t ${DEBUG_CLI};
        if [ $? != 0 ]; then
            echo "${i}: Configuration error. Exiting"
            unlock;
            exit 1;
        fi
    done
}

# Start function
start()
{
    SDAEMONS="${DB_DAEMON} ${CSYSLOG_DAEMON} ${AGENTLESS_DAEMON} openarmor-maild openarmor-execd openarmor-analysisd openarmor-logcollector openarmor-remoted openarmor-syscheckd openarmor-monitord"

    echo "Starting $NAME $VERSION..."
    echo | ${DIR}/bin/openarmor-logtest > /dev/null 2>&1;
    if [ ! $? = 0 ]; then
        echo "openarmor analysisd: Testing rules failed. Configuration error. Exiting."
        exit 1;
    fi
    lock;
    checkpid;

    # We actually start them now.
    for i in ${SDAEMONS}; do

        ## If openarmor-maild is disabled, don't try to start it.
        if [ X"$i" = "Xopenarmor-maild" ]; then
             grep "<email_notification>no<" ${DIR}/etc/openarmor.conf >/dev/null 2>&1
             if [ $? = 0 ]; then
                 continue
             fi
        fi

        pstatus ${i};
        if [ $? = 0 ]; then
            ${DIR}/bin/${i} ${DEBUG_CLI};
            if [ $? != 0 ]; then
                echo "${i} did not start correctly.";
                unlock;
                exit 1;
            fi

            echo "Started ${i}..."
        else
            echo "${i} already running..."
        fi
    done

    # After we start we give 2 seconds for the daemons
    # to internally create their PID files.
    sleep 2;
    unlock;
    echo "Completed."
}

pstatus()
{
    pfile=$1;

    # pfile must be set
    if [ "X${pfile}" = "X" ]; then
        return 0;
    fi

    ls ${DIR}/var/run/${pfile}*.pid > /dev/null 2>&1
    if [ $? = 0 ]; then
        for j in `cat ${DIR}/var/run/${pfile}*.pid 2>/dev/null`; do
            ps -p $j |grep openarmor >/dev/null 2>&1
            if [ ! $? = 0 ]; then
                echo "${pfile}: Process $j not used by openarmor, removing .."
                rm -f ${DIR}/var/run/${pfile}-$j.pid
                continue;
            fi

            kill -0 $j > /dev/null 2>&1
            if [ $? = 0 ]; then
                return 1;
            fi
        done
    fi

    return 0;
}

stopa()
{
    lock;
    checkpid;
    for i in ${DAEMONS}; do
        pstatus ${i};
        if [ $? = 1 ]; then
            echo "Killing ${i} .. ";

            kill `cat ${DIR}/var/run/${i}*.pid`;
        else
            echo "${i} not running ..";
        fi
        rm -f ${DIR}/var/run/${i}*.pid
    done

    unlock;
    echo "$NAME $VERSION Stopped"
}

### MAIN HERE ###

case "$1" in
start)
    testconfig
    start
    ;;
stop)
    stopa
    ;;
restart)
    testconfig
    stopa
    sleep 1;
    start
    ;;
reload)
    DAEMONS="openarmor-monitord openarmor-logcollector openarmor-remoted openarmor-syscheckd openarmor-analysisd openarmor-maild ${DB_DAEMON} ${CSYSLOG_DAEMON} ${AGENTLESS_DAEMON}"
    stopa
    start
    ;;
status)
    status
    ;;
help)
    help
    ;;
enable)
    enable $1 $2;
    ;;
disable)
    disable $1 $2;
    ;;
*)
    help
esac

