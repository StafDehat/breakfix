#!/bin/bash


# Confirm this is CentOS/RHEL 6.x


# Record the DIR in which this repo exists
GITROOT=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd && cd $OLDPWD)
echo $GITROOT
exit

# Install pre-reqs
yum -y install \
httpd \
git

# Clone the breakfix repo
#git clone https://github.com/stafdehat/breakfix
# Assume this repo was already cloned, since this script is within the repo

# Install broken logrotate config


