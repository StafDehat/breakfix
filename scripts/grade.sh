#!/bin/bash

# Colours!
K="\033[0;30m"    # black
R="\033[0;31m"    # red
G="\033[0;32m"    # green
Y="\033[0;33m"    # yellow
B="\033[0;34m"    # blue
P="\033[0;35m"    # purple
C="\033[0;36m"    # cyan
W="\033[0;37m"    # white
EMK="\033[1;30m"
EMR="\033[1;31m"
EMG="\033[1;32m"
EMY="\033[1;33m"
EMB="\033[1;34m"
EMP="\033[1;35m"
EMC="\033[1;36m"
EMW="\033[1;37m"
NORMAL=`tput sgr0 2> /dev/null`


if [ `id -u` -ne 0 ]; then
  echo "Must run this script as root."
  exit 0
fi


SCORE=0

#
# Logrotate
LR1=0
LR2=0
LR3=0
LR4=0
# Make sure erroneous files have been deleted
if [[ -d /var/log/httpd &&
      `ls /var/log/httpd | wc -l` -lt 10 ]]; then
  LR1=1
fi


# Check to ensure existing log entries were preserved
if [[ -e /var/log/httpd/access_log &&
      -e /var/log/httpd/error_log ]]; then
  ACCDATES=`cat /var/log/httpd/access_log | awk '{print $4}' | cut -d: -f1 | sort -u | wc -l`
  ERRDATES=`grep "Feb\|Jan" /var/log/httpd/error_log | awk '{print $3}' | sort -u | wc -l`
  if [[ $ACCDATES -gt 20 && $ERRDATES -gt 30 ]]; then
    LR2=1
  fi
fi

# Ensure apache log entries are chronological
ACCDIFF=1
ERRDIFF=1
if [ -e /var/log/httpd/access_log ]; then
  diff \
    <(cat /var/log/httpd/access_log | awk -F / '$2 ~ /Jan/ {print $1}' | cut -d[ -f2 | sort -n;
      cat /var/log/httpd/access_log | awk -F / '$2 ~ /Feb/ {print $1}' | cut -d[ -f2 | sort -n)\
    <(grep "Jan\|Feb" /var/log/httpd/access_log | awk -F / '{print $1}' | cut -d[ -f2)
  ACCDIFF=$?
fi
if [ -e /var/log/httpd/error_log ]; then
  diff <(cat /var/log/httpd/error_log | awk '$2 ~ /Jan/ {print $3}' | sort -n;
         cat /var/log/httpd/error_log | awk '$2 ~ /Feb/ {print $3}' | sort -n ) \
       <(grep "Jan\|Feb" /var/log/httpd/error_log | awk '{print $3}')
  ERRDIFF=$?
fi
if [[ $LR2 -eq 1 && $ACCDIFF -eq 0 && $ERRDIFF -eq 0 ]]; then
  LR3=1
fi

# Check that logrotate config is fixed
if [ -e /etc/logrotate.d/httpd ]; then
  if [ `egrep '\*\s' /etc/logrotate.d/httpd | egrep -vc '^\s*#'` -eq 0 ]; then
    LR4=1
  fi
fi




echo -n "Erroneous apache logs deleted:        "
if [ $LR1 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi
echo -n "Existing apache logs were preserved:  "
if [ $LR2 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi
echo -n "Apache log entries are chronological: "
if [ $LR3 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi
echo -n "Logrotate http log target corrected:  "
if [ $LR4 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi



#
# HTTP Checks
AP1=0
AP2=0
AP3=0

# Verify apache is running
nc -z localhost 80 &>/dev/null
LIST80=$?
if [[ $LIST80 -eq 0 &&
      `netstat -lpnt | grep httpd | egrep -c ":80\s"` -ge 1 ]]; then
  AP1=1
fi

nc -z localhost 443 &>/dev/null
LIST443=$?
if [[ $LIST443 -eq 0 &&
      `netstat -lpnt | grep httpd | egrep -c ":443\s"` -ge 1 ]]; then
  AP2=1
fi

# Make sure HTTP is getting redirected to HTTPS
if [[ $AP1 -eq 1 && 
      `curl -I -k localhost 2>/dev/null | grep -c "HTTP/1.1 3"` -ge 1 && 
      `curl -I -k localhost 2>/dev/null | grep -c "Location: https://"` -ge 1 ]]; then
  AP3=1
fi

echo
echo -n "Apache listening on 80:               "
if [ $AP1 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi
echo -n "Apache listening on 443:              "
if [ $AP2 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi
echo -n "Redirect all HTTP traffic to HTTPS:   "
if [ $AP3 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi



#
# User37 cronjob
CJ1=0
CJ2=0
CJ3=0
if [[ ! -e /var/spool/cron/user37 ||
      `egrep -v '^\s*#' /var/spool/cron/user37 | grep -c date` -eq 0 ]]; then
  CJ1=1
fi
if [ `find /tmp -user user37 \
        | egrep -c '[0-9]+-[0-9]+-[0-9]+-[0-9]+:[0-9]+:[0-9]+'` -eq 0 ]; then
  CJ2=1
fi
if [[ -e /tmp/2014-02-10-00:25:01.sql &&
      `cat /tmp/2014-02-10-00:25:01.sql | wc -l` -eq 704 ]]; then
  CJ3=1
fi

echo
echo -n "Disable cronjob in user37's crontab:  "
if [ $CJ1 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi

echo -n "Delete timestamp files from /tmp:     "
if [ $CJ2 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi

echo -n "/tmp/2014-02-10-00:25:01.sql exists:  "
if [ $CJ3 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi



#
# MySQL
MY1=0
MY2=0
MY3=0
if [ `mysql -e "show variables like 'log_bin';" | grep -c ON` -gt 0 ]; then
  MY1=1
fi
if [ `mysql -e "show variables like 'log_slow_queries';" | grep -c ON` -gt 0 ]; then
  MY2=1
fi
MASTER=`mysql -e "show slave status\G" | grep Master_Host | awk '{print $2}'`
if [ ! -e /var/lib/mysql/master.info ]; then
  MY3=1
fi

echo
echo -n "MySQL binary logging enabled:         "
if [ $MY1 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi

echo -n "MySQL slow query log enabled:         "
if [ $MY2 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi

echo -n "Server removed from replication:      "
if [ $MY3 -eq 1 ]; then
  SCORE=$(( $SCORE + 1 ))
  echo -e "${EMG}OK$NORMAL"
else
  echo -e "${EMR}MISS$NORMAL"
fi




echo
echo "Score: $SCORE"

