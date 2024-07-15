## openarmor-agent SELinux module

SELinux module provides additional security protection for openarmor application

## Installation

1. Run semodule -i openarmor_agent.pp.bz2 on a running SELinux installation
2. Run restorecon -R /var/openarmor
3. Restart openarmor agent via systemd/init/etc
4. Check if it get right context ( ps -AZ )

You should do chcon manually if your put openarmor installation in different place, see .fc file for details

## Configuration

Nothing to configure :)

## Bug reports & contribution

Contact: ivan.agarkov@gmail.com
