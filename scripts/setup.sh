#!/bin/bash


# Confirm this is CentOS/RHEL 6.x

# Install pre-reqs
yum -y install \
httpd \
git

# Clone the breakfix repo
git clone https://github.com/stafdehat/breakfix

# Download broken logrotate config

