#
# openarmor 1.3 .spec file - AGENT
# Fri Aug 17 15:19:40 EDT 2007
#
#
# TODO:
#
# o Safety checks for %clean
#
# o Remove script
#
# o create an RPM_README.txt and put it in the source tree
#
#

Summary: Open Source Host-based Intrusion Detection System (Server)
Name: openarmor-hids-agent-FC7
Version: 1.3
Release: 1
License: GPLv2
Group: Applications/Security
URL: http://www.theopenarmor.org
Packager: Michael Williams (maverick@maverick.org)
Source: http://www.theopenarmor.org/files/openarmor-hids-1.3.tar.gz
Requires: /usr/sbin/useradd, /usr/sbin/groupadd, /usr/sbin/groupdel, /usr/sbin/userdel, /sbin/service, /sbin/chkconfig

%description
openarmor is an Open Source Host-based Intrusion 
Detection System. It performs log analysis, 
integrity checking, Windows registry monitoring, 
rootkit detection, real-time alerting and active 
response.


%prep

%setup -n openarmor-hids-1.3

%build
/bin/cp /usr/local/src/openarmor-RPM/1.3/agent/preloaded-vars.conf ${RPM_BUILD_DIR}/openarmor-hids-1.3/etc/

./install.sh

%clean
rm -rf $RPM_BUILD_ROOT

%pre
################################################################################
# Create openarmor group
#
if ! grep "^openarmor" /etc/group > /dev/null ; then
  /usr/sbin/groupadd --system openarmor
fi


################################################################################
# Create openarmor users
#
for USER in openarmor ; do
  if ! grep "^${USER}" /etc/passwd > /dev/null ; then
    /usr/sbin/useradd --system -d /var/openarmor -s /bin/false -g openarmor ${USER}
  fi
done

%post



################################################################################
# Create openarmor /etc/init.d/openarmor file
#
cat <<EOF > /etc/init.d/openarmor
#!/bin/bash
#
# openarmor Starts openarmor
#
#
# chkconfig: 2345 12 88
# description: openarmor is an open source host based IDS
### BEGIN INIT INFO
# Provides: $openarmor
### END INIT INFO

# Source function library.
. /etc/init.d/functions

[ -f /var/openarmor/bin/openarmor-control ] || exit 0

RETVAL=0

umask 077

case "\$1" in
  start)
        /var/openarmor/bin/openarmor-control start
        ;;
  stop)
        /var/openarmor/bin/openarmor-control stop
        ;;
  status)
        /var/openarmor/bin/openarmor-control status
        ;;
  restart|reload)
        /var/openarmor/bin/openarmor-control restart
        ;;
  *)
        echo "Usage: /var/openarmor/bin/openarmor-control {start|stop|status|restart}"
        exit 1
esac

EOF

/bin/chown root.root /etc/init.d/openarmor
/bin/chmod 755 /etc/init.d/openarmor

################################################################################
# Set configuration so openarmor starts on reboot
#
/sbin/chkconfig --add openarmor
/sbin/chkconfig openarmor on

%postun
# Run service command, make sure openarmor is stopped
/sbin/service openarmor stop

# Run chkconfig, stop openarmor from starting on boot
/sbin/chkconfig openarmor off
/sbin/chkconfig --del openarmor

# Remove init.d file
[ -f /etc/init.d/openarmor ] && rm /etc/init.d/openarmor

# Remove openarmor users
for USER in openarmor openarmorm openarmorr ; do
  if grep "^${USER}" /etc/passwd > /dev/null ; then
    /usr/sbin/userdel -r ${USER}
  fi
done

# Remove openarmor group
if grep "^openarmor" /etc/group > /dev/null ; then
  /usr/sbin/groupdel openarmor
fi


%files
%doc README BUGS CONFIG CONTRIB INSTALL LICENSE

%dir /var/openarmor/
%attr(550, root, openarmor) /var/openarmor/
%dir /var/openarmor/var
%attr(550, root, openarmor) /var/openarmor/var
%dir /var/openarmor/var/run
%attr(770, root, openarmor) /var/openarmor/var/run
%dir /var/openarmor/active-response
%attr(550, root, openarmor) /var/openarmor/active-response
%dir /var/openarmor/active-response/bin
%attr(550, root, openarmor) /var/openarmor/active-response/bin
/var/openarmor/active-response/bin/route-null.sh
%attr(755, root, openarmor) /var/openarmor/active-response/bin/route-null.sh
/var/openarmor/active-response/bin/host-deny.sh
%attr(755, root, openarmor) /var/openarmor/active-response/bin/host-deny.sh
/var/openarmor/active-response/bin/firewall-drop.sh
%attr(755, root, openarmor) /var/openarmor/active-response/bin/firewall-drop.sh
%dir /var/openarmor/active-response/bin/firewalls
%attr(755, root, openarmor) /var/openarmor/active-response/bin/firewalls
/var/openarmor/active-response/bin/firewalls/pf.sh
/var/openarmor/active-response/bin/firewalls/ipfw.sh
/var/openarmor/active-response/bin/firewalls/ipfw_mac.sh
/var/openarmor/active-response/bin/disable-account.sh
%attr(755, root, openarmor) /var/openarmor/active-response/bin/disable-account.sh
%dir /var/openarmor/bin
%attr(550, root, openarmor) /var/openarmor/bin
/var/openarmor/bin/openarmor-agentd
%attr(550, root, openarmor) /var/openarmor/bin/openarmor-agentd
/var/openarmor/bin/openarmor-logcollector
%attr(550, root, openarmor) /var/openarmor/bin/openarmor-logcollector
/var/openarmor/bin/openarmor-control
%attr(550, root, openarmor) /var/openarmor/bin/openarmor-control
/var/openarmor/bin/openarmor-syscheckd
%attr(550, root, openarmor) /var/openarmor/bin/openarmor-syscheckd
/var/openarmor/bin/manage_agents
%attr(550, root, openarmor) /var/openarmor/bin/manage_agents
/var/openarmor/bin/openarmor-execd
%attr(550, root, openarmor) /var/openarmor/bin/openarmor-execd
%dir /var/openarmor/etc
%attr(550, root, openarmor) /var/openarmor/etc
/var/openarmor/etc/internal_options.conf
%attr(440, root, openarmor) /var/openarmor/etc/internal_options.conf
/var/openarmor/etc/localtime
%attr(644, root, root) /var/openarmor/etc/localtime
%dir /var/openarmor/etc/shared
%attr(770, root, openarmor) /var/openarmor/etc/shared
/var/openarmor/etc/shared/win_malware_rcl.txt
%attr(770, openarmor, openarmor) /var/openarmor/etc/shared/win_malware_rcl.txt
/var/openarmor/etc/shared/win_applications_rcl.txt
%attr(770, openarmor, openarmor) /var/openarmor/etc/shared/win_applications_rcl.txt
/var/openarmor/etc/shared/win_audit_rcl.txt
%attr(770, openarmor, openarmor) /var/openarmor/etc/shared/win_audit_rcl.txt
/var/openarmor/etc/shared/rootkit_files.txt
%attr(770, osse, openarmor) /var/openarmor/etc/shared/rootkit_files.txt
/var/openarmor/etc/shared/rootkit_trojans.txt
%attr(770, openarmor, openarmor) /var/openarmor/etc/shared/rootkit_trojans.txt
/var/openarmor/etc/openarmor.conf
%attr(440, root, openarmor) /var/openarmor/etc/openarmor.conf
%dir /var/openarmor/logs
%attr(750, openarmor, openarmor) /var/openarmor/logs
/var/openarmor/logs/openarmor.log
%attr(664, openarmor, openarmor) /var/openarmor/logs/openarmor.log
%dir /var/openarmor/queue
%attr(550, root, openarmor) /var/openarmor/queue
%dir /var/openarmor/queue/rids
%attr(775, root, openarmor) /var/openarmor/queue/rids
%dir /var/openarmor/queue/alerts
%attr(550, root, openarmor) /var/openarmor/queue/alerts
%dir /var/openarmor/queue/syscheck
%attr(550, root, openarmor) /var/openarmor/queue/syscheck
%dir /var/openarmor/queue/openarmor
%attr(770, openarmor, openarmor) /var/openarmor/queue/openarmor

