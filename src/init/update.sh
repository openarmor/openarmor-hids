#!/bin/sh
# Shell script update functions for the openarmor HIDS
# Author: Daniel B. Cid <daniel.cid@gmail.com>

FALSE="false"
TRUE="true"

isUpdate()
{
    ls -la ${openarmor_INIT} > /dev/null 2>&1
    if [ $? = 0 ]; then
        . ${openarmor_INIT}
        if [ "X$DIRECTORY" = "X" ]; then
            echo "# ($FUNCNAME) ERROR: The variable DIRECTORY wasn't set" 1>&2
            echo "${FALSE}"
            return 1;
        fi
        ls -la $DIRECTORY > /dev/null 2>&1
        if [ $? = 0 ]; then
            echo "${TRUE}"
            return 0;
        fi
    fi
    echo "${FALSE}"
    return 1;
}

doUpdatecleanup()
{
    . ${openarmor_INIT}

    if [ "X$DIRECTORY" = "X" ]; then
        echo "# ($FUNCNAME) ERROR: The variable DIRECTORY wasn't set." 1>&2
        echo "${FALSE}"
        return 1;
    fi

    # Checking if the directory is valid.
    _dir_pattern_update="^/[-a-zA-Z0-9/\.-]{3,128}$"
    echo $DIRECTORY | grep -E "$_dir_pattern_update" > /dev/null 2>&1
    if [ ! $? = 0 ]; then
        echo "# ($FUNCNAME) ERROR: directory name ($DIRECTORY) doesn't match the pattern $_dir_pattern_update" 1>&2
        echo "${FALSE}"
        return 1;
    fi
}

getPreinstalled()
{
    . ${openarmor_INIT}

    # agent
    cat $DIRECTORY/etc/openarmor.conf | grep "<client>" > /dev/null 2>&1
    if [ $? = 0 ]; then
        echo "agent"
        return 0;
    fi

    cat $DIRECTORY/etc/openarmor.conf | grep "<remote>" > /dev/null 2>&1
    if [ $? = 0 ]; then
        echo "server"
        return 0;
    fi

    echo "local"
    return 0;
}

getPreinstalledDir()
{
    . ${openarmor_INIT}
    echo "$DIRECTORY"
    return 0;
}

UpdateStartopenarmor()
{
   . ${openarmor_INIT}

   $DIRECTORY/bin/openarmor-control start
}

UpdateStopopenarmor()
{
   . ${openarmor_INIT}

   $DIRECTORY/bin/openarmor-control stop

   # We also need to remove all syscheck queue file (format changed)
   if [ "X$VERSION" = "X0.9-3" ]; then
        rm -f $DIRECTORY/queue/syscheck/* > /dev/null 2>&1
        rm -f $DIRECTORY/queue/agent-info/* > /dev/null 2>&1
   fi
   rm -f $DIRECTORY/queue/syscheck/.* > /dev/null 2>&1
}

UpdateopenarmorRules()
{
    . ${openarmor_INIT}

    openarmor_CONF_FILE="$DIRECTORY/etc/openarmor.conf"

    # Backing up the old config
    cp -pr ${openarmor_CONF_FILE} "${openarmor_CONF_FILE}.$$.bak"

    # Getting rid of old rules entries
    grep -Ev "</*rules>|<include>|<list>|<decoder>|<decoder_dir|<rule_dir>|rules global entry" ${openarmor_CONF_FILE} > "${openarmor_CONF_FILE}.$$.tmp"

    # Customer decoder, decoder_dir, rule_dir are carried over during upgrade
    grep -E '<decoder>|<decoder_dir|<rule_dir>' ${openarmor_CONF_FILE} | grep -v '<!--' >> "${openarmor_CONF_FILE}.$$.tmp2"

    # Check for custom files that may have been added in <rules> element
    for i in `grep -E '<include>|<list>' ${openarmor_CONF_FILE} | grep -v '<!--'`
    do
      grep "$i" ${RULES_TEMPLATE}>/dev/null || echo "    $i" >> "${openarmor_CONF_FILE}.$$.tmp2"
    done

    # Putting everything back together
    cat "${openarmor_CONF_FILE}.$$.tmp" > ${openarmor_CONF_FILE}
    rm "${openarmor_CONF_FILE}.$$.tmp"
    echo "" >> ${openarmor_CONF_FILE}
    echo "<openarmor_config>  <!-- rules global entry -->" >> ${openarmor_CONF_FILE}
    grep -v '</rules>' ${RULES_TEMPLATE} >> ${openarmor_CONF_FILE}
    cat "${openarmor_CONF_FILE}.$$.tmp2" >> ${openarmor_CONF_FILE}
    echo "</rules>" >> ${openarmor_CONF_FILE}
    echo "</openarmor_config>  <!-- rules global entry -->" >> ${openarmor_CONF_FILE}
    rm "${openarmor_CONF_FILE}.$$.tmp2"
}

