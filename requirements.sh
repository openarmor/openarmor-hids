#!/bin/bash

# Git repository link
OSSEC_REPO="https://github.com/openarmor/openarmor-hids"
PCRE2_URL="https://ftp.pcre.org/pub/pcre/pcre2-10.32.tar.gz"

# Function to install OSSEC on RedHat/Centos/Fedora/Amazon Linux
install_redhat() {
    echo "Installing on RedHat/CentOS/Fedora/Amazon Linux..."
    sudo yum install -y zlib-devel pcre2-devel make gcc sqlite-devel openssl-devel libevent-devel systemd-devel

    # Optional database support
    sudo yum install -y mysql-devel postgresql-devel

    # Clone and install OSSEC
    git clone $OSSEC_REPO
    cd openarmor-hids

    # Choose PCRE2 system or local installation
    read -p "Use system's PCRE2 libraries? (yes/no): " use_system_pcre2
    if [[ "$use_system_pcre2" == "yes" ]]; then
        PCRE2_SYSTEM=yes ./install.sh
    else
        wget $PCRE2_URL -O pcre2-10.32.tar.gz
        tar xzf pcre2-10.32.tar.gz -C src/external
        PCRE2_SYSTEM=no ./install.sh
    fi

    # Choose zlib system or local installation
    read -p "Use system's zlib libraries? (yes/no): " use_system_zlib
    if [[ "$use_system_zlib" == "yes" ]]; then
        ZLIB_SYSTEM=yes ./install.sh
    else
        ZLIB_SYSTEM=no ./install.sh
    fi
}

# Function to install OSSEC on Ubuntu/Debian
install_debian() {
    echo "Installing on Ubuntu/Debian..."
    sudo apt-get update
    sudo apt-get install -y build-essential make zlib1g-dev libpcre2-dev libevent-dev libssl-dev

    # Optional database support
    sudo apt-get install -y mysql-dev postgresql-dev
    sudo apt-get install -y default-libmysqlclient-dev libmariadb-dev-compat libsqlite3-dev

    # Clone and install OSSEC
    git clone $OSSEC_REPO
    cd openarmor-hids

    # Choose PCRE2 system or local installation
    read -p "Use system's PCRE2 libraries? (yes/no): " use_system_pcre2
    if [[ "$use_system_pcre2" == "yes" ]]; then
        PCRE2_SYSTEM=yes ./install.sh
    else
        wget $PCRE2_URL -O pcre2-10.32.tar.gz
        tar xzf pcre2-10.32.tar.gz -C src/external
        PCRE2_SYSTEM=no ./install.sh
    fi

    # Choose zlib system or local installation
    read -p "Use system's zlib libraries? (yes/no): " use_system_zlib
    if [[ "$use_system_zlib" == "yes" ]]; then
        ZLIB_SYSTEM=yes ./install.sh
    else
        ZLIB_SYSTEM=no ./install.sh
    fi
}

# Function to install OSSEC on OpenSuse
install_opensuse() {
    echo "Installing on OpenSuse..."
    sudo zypper install -y zlib-devel pcre2-devel

    # Optional database support
    sudo zypper install -y mysql-devel postgresql-devel

    # Clone and install OSSEC
    git clone $OSSEC_REPO
    cd openarmor-hids

    # Choose PCRE2 system or local installation
    read -p "Use system's PCRE2 libraries? (yes/no): " use_system_pcre2
    if [[ "$use_system_pcre2" == "yes" ]]; then
        PCRE2_SYSTEM=yes ./install.sh
    else
        wget $PCRE2_URL -O pcre2-10.32.tar.gz
        tar xzf pcre2-10.32.tar.gz -C src/external
        PCRE2_SYSTEM=no ./install.sh
    fi

    # Choose zlib system or local installation
    read -p "Use system's zlib libraries? (yes/no): " use_system_zlib
    if [[ "$use_system_zlib" == "yes" ]]; then
        ZLIB_SYSTEM=yes ./install.sh
    else
        ZLIB_SYSTEM=no ./install.sh
    fi
}

# Determine the Linux distribution
if [ -f /etc/redhat-release ]; then
    install_redhat
elif [ -f /etc/debian_version ]; then
    install_debian
elif [ -f /etc/SuSE-release ]; then
    install_opensuse
else
    echo "Unsupported OS"
    exit 1
fi
