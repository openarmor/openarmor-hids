#!/bin/sh
# Init functions for the openarmor HIDS
# Author: Daniel B. Cid <daniel.cid@gmail.com>

UN=${NUNAME};

runInit()
{
    echo ""
    echo ""
    # Checking if it is a Redhat system.
    if [ -r "/etc/redhat-release" ]; then
        if [ -d /etc/rc.d/init.d ]; then
            echo " - ${systemis} Redhat Linux."
            echo " - ${modifiedinit}"
            cp -pr ./src/init/openarmor-hids-rh.init /etc/rc.d/init.d/openarmor
            chmod 555 /etc/rc.d/init.d/openarmor
            chown root:openarmor /etc/rc.d/init.d/openarmor
            /sbin/chkconfig --add openarmor > /dev/null 2>&1
            return 0;
        fi
    fi
    # Checking for Gentoo
    if [ -r "/etc/gentoo-release" ]; then
        echo " - ${systemis} Gentoo Linux."
        echo " - ${modifiedinit}"
        cp -pr ./src/init/openarmor-hids-gentoo.init /etc/init.d/openarmor
        chmod 555 /etc/init.d/openarmor
        chown root:openarmor /etc/init.d/openarmor
        rc-update add openarmor default
        return 0;
    fi

    # Suse
    if [ -r "/etc/SuSE-release" ]; then
        echo " - ${systemis} Suse Linux."
        echo " - ${modifiedinit}"

        cp -pr ./src/init/openarmor-hids-suse.init  /etc/init.d/openarmor
        chmod 555 /etc/init.d/openarmor
        chown root:openarmor /etc/init.d/openarmor

        /sbin/chkconfig --add openarmor > /dev/null 2>&1
        return 0;
    fi

    # Checking for slackware (by Jack S. Lai)
    if [ -r "/etc/slackware-version" ]; then
        echo " - ${systemis} Slackware Linux."
        echo " - ${modifiedinit}"
        cp -pr ./src/init/openarmor-hids.init /etc/rc.d/rc.openarmor
        chmod 555 /etc/rc.d/rc.openarmor
        chown root:openarmor /etc/rc.d/rc.openarmor

        grep openarmor /etc/rc.d/rc.local > /dev/null 2>&1
        if [ $? != 0 ]; then
            echo "if [ -x /etc/rc.d/rc.openarmor ]; then" >> /etc/rc.d/rc.local
            echo "      /etc/rc.d/rc.openarmor start" >>/etc/rc.d/rc.local
            echo "fi" >>/etc/rc.d/rc.local
        fi

        return 0;
    fi

    # Darwin init script (by Lorenzo Costanzia di Costigliole <mummie@tin.it>)
    if [ "X${NUNAME}" = "XDarwin" ]; then
        # Generating darwin init script.

        echo " - ${systemis} Darwin."
        echo " - ${modifiedinit}"
        sh ./src/init/darwin-init.sh
        return 0;
    fi

    if [ "X${UN}" = "XSunOS" ]; then
        echo " - ${systemis} Solaris (SunOS)."
        echo " - ${modifiedinit}"
        cp -pr ./src/init/openarmor-hids-solaris.init /etc/init.d/openarmor
        chmod 755 /etc/init.d/openarmor
        ln -s /etc/init.d/openarmor /etc/rc2.d/S97openarmor
        ln -s /etc/init.d/openarmor /etc/rc3.d/S97openarmor
        return 0;
    fi

    if [ "X${UN}" = "XAIX" ]; then
        echo " - ${systemis} AIX."
        echo " - ${modifiedinit}"
        cp -pr ./src/init/openarmor-hids-aix.init /etc/rc.d/init.d/openarmor
        chmod 755 /etc/rc.d/init.d/openarmor
        ln -s /etc/rc.d/init.d/openarmor /etc/rc.d/rc2.d/S97openarmor
        ln -s /etc/rc.d/init.d/openarmor /etc/rc.d/rc3.d/S97openarmor
        return 0;
    fi

    if [ "X${UN}" = "XOpenBSD" -o "X${UN}" = "XNetBSD" -o "X${UN}" = "XFreeBSD" -o "X${UN}" = "XDragonFly" ]; then
        # Checking for the presence of openarmor-control on rc.local
        grep openarmor-control /etc/rc.local > /dev/null 2>&1
        if [ $? != 0 ]; then
            echo "echo \"${starting}\"" >> /etc/rc.local
            echo "${INSTALLDIR}/bin/openarmor-control start" >> /etc/rc.local
        fi
        echo " - ${systemis} ${NUNAME}."
        echo " - ${modifiedinit}"
        return 0;
    elif [ "X${NUNAME}" = "XLinux" ]; then
        if [ -e "/etc/rc.d/rc.local" ]; then
            echo " - ${systemis} Linux."
            echo " - ${modifiedinit}"

            grep openarmor-control /etc/rc.d/rc.local > /dev/null 2>&1
            if [ $? != 0 ]; then
                echo "echo \"${starting}\"" >> /etc/rc.d/rc.local
                echo "${INSTALLDIR}/bin/openarmor-control start" >> /etc/rc.d/rc.local
            fi
            return 0;
        elif [ -d "/etc/rc.d/init.d" ]; then
            echo " - ${systemis} Linux (SysV)."
            echo " - ${modifiedinit}"
            cp -pr ./src/init/openarmor-hids.init  /etc/rc.d/init.d/openarmor
            chmod 555 /etc/rc.d/init.d/openarmor
            chown root:openarmor /etc/rc.d/init.d/openarmor
            return 0;
        # Taken from Stephen Bunn openarmor howto.
        elif [ -d "/etc/init.d" -a -f "/usr/sbin/update-rc.d" ]; then
            echo " - ${systemis} Debian (Ubuntu or derivative)."
            echo " - ${modifiedinit}"
            cp -pr ./src/init/openarmor-hids-debian.init  /etc/init.d/openarmor
            chmod +x /etc/init.d/openarmor
            chmod go-w /etc/init.d/openarmor
            chown root:openarmor /etc/init.d/openarmor
            update-rc.d openarmor defaults > /dev/null 2>&1
            return 0;
        elif [ -e "/etc/alpine-release" ]; then
            echo " - ${systemis} Alpine Linux."
            echo " - ${modifiedinit}"
            cp -pr ./src/init/openarmor-hids-alpine.init /etc/init.d/openarmor
            chmod +x /etc/init.d/openarmor
            chmod go-w /etc/init.d/openarmor
            chown root:openarmor /etc/init.d/openarmor
            return 0;
        else
            echo " - ${noboot}"
        fi
    else
        echo " - ${noboot}"
    fi

    return 1;
}

