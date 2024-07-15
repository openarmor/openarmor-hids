#!/bin/sh
# Darwin init script.
# by Lorenzo Costanzia di Costigliole <mummie@tin.it>

mkdir -p /Library/StartupItems/openarmor
cat <<EOF >/Library/StartupItems/openarmor/StartupParameters.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://
www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
       <key>Description</key>
       <string>openarmor Host-based Intrusion Detection System</string>
       <key>Messages</key>
       <dict>
               <key>start</key>
               <string>Starting openarmor</string>
               <key>stop</key>
               <string>Stopping openarmor</string>
       </dict>
       <key>Provides</key>
       <array>
               <string>openarmor</string>
       </array>
       <key>Requires</key>
       <array>
               <string>IPFilter</string>
       </array>
</dict>
</plist>
EOF

cat <<EOF >/Library/StartupItems/openarmor/openarmor
#!/bin/sh

. /etc/rc.common
. /etc/openarmor-init.conf
if [ "X\${DIRECTORY}" = "X" ]; then
    DIRECTORY="/var/openarmor"
fi


StartService ()
{
        \${DIRECTORY}/bin/openarmor-control start
}

StopService ()
{
        \${DIRECTORY}/bin/openarmor-control stop
}

RestartService ()
{
        \${DIRECTORY}/bin/openarmor-control restart
}

RunService "\$1"
EOF
chmod 755 /Library/StartupItems/openarmor
chmod 644 /Library/StartupItems/openarmor/StartupParameters.plist
chmod 755 /Library/StartupItems/openarmor/openarmor
