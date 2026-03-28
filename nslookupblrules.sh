#!/bin/bash
# just to make sure we are not permabanning something important :)
iplist=`grep REJECT /etc/shorewall/blrules | grep -v "#" | cut -d':' -f2 | cut -d'a' -f1`
for ip in $iplist
do
        nslookup "$ip" | grep name
done
