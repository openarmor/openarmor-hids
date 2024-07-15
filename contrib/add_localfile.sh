#!/bin/sh
# Add a localfile to openarmor.
# by Daniel B. Cid - dcid ( at ) theopenarmor.org

FILE=$1
FORMAT=$2

if [ "X$FILE" = "X" ]; then
    echo "$0: <filename> [<format>]"
    exit 1;
fi

if [ "X$FORMAT" = "X" ]; then
    FORMAT="syslog"
fi

# Checking if file is already configured
grep "$FILE" /var/openarmor/etc/openarmor.conf > /dev/null 2>&1
if [ $? = 0 ]; then
    echo "$0: File $FILE already configured at openarmor."
    exit 1;
fi

# Checking if file exist
ls -la $FILE > /dev/null 2>&1
if [ ! $? = 0 ]; then
    echo "$0: File $FILE does not exist."
    exit 1;
fi     
    
echo "
<openarmor_config>
  <localfile>
    <log_format>$FORMAT</log_format>
    <location>$FILE</location>
  </localfile>
</openarmor_config>  
" >> /var/openarmor/etc/openarmor.conf

echo "$0: File $FILE added.";
exit 0;            
