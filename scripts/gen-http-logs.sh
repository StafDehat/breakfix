#!/bin/bash

rm -f /var/log/httpd/*
service httpd restart
date -s "2014-01-01"
for x in `seq -w 1 40`; do
  COUNT=$(( $RANDOM % 10 + 1 ))
  echo "Generating $COUNT entries on `date`"
  for y in `seq 1 $COUNT`; do
    curl localhost &>/dev/null
  done
  date -s "tomorrow"
  logrotate -f /etc/logrotate.conf
done


