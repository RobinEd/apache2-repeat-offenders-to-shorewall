#!/bin/bash
# v1 27/3/26
#
# todo - thinking about not using shorewall, but fail2ban using `fail2ban-client set jailname banip 123.45.67.89`

# seed the TEMPFILE
# Note if any of these are empty the whole thing won't work :)
TEMPFILE="/home/adm_usr/webserveradmin/blrules.tmp"
MYIP="12.34.56.78"
MYIPv6="0:0:0:0:0:0:0:1"

# check if it exists
if [[ -e "$TEMPFILE" ]];
then
        touch $TEMPFILE
fi

# make sure it's empty
cat /dev/null > $TEMPFILE

# copy original rules in
cat /etc/shorewall/blrules | grep -v "#" | grep -v "$MYIP" | uniq >> $TEMPFILE

# find the nastiest offenders and show values greater than 100
#
# daily command for IPv4
# cat /var/log/apache2/access.log | cut -d' ' -f2 | grep -v :| sort | uniq -c | sort -nr | head -n10 | awk '$1>100'  | cut -b 9-
#
# hourly command for IPv4
# grep -h "\[$(date -d -1hour +'%d/%b/%Y:%H:')" /var/log/apache2/access.log | cut -d' ' -f2 | grep -v : | sort | uniq -c | sort -nr | head -n10 | awk '$1>100' | cut -b 9-
#
# add the new list into the temp files
banlist=`grep -h "\[$(date -d -1hour +'%d/%b/%Y:%H:')" /var/log/apache2/access.log | cut -d' ' -f2 | grep -v : | grep -v "$MYIP" | sort | uniq -c | sort -nr | head -n10 | awk '$1>100' | cut -b 9-`
for ip in $banlist
do
        echo "REJECT    net:$ip all" >> $TEMPFILE
done

# sort the combined new and old blocklists
finallist=`cat $TEMPFILE | grep -v "#" | sort -t : -k 2n`

# empty out the tempfile, seed it again and copy in the sorted list
cat /dev/null > $TEMPFILE
cat /usr/share/shorewall/configfiles/blrules > $TEMPFILE
echo "# NB: high_traffic_to_shorewall.sh has my IPs hardcoded in it - if they change I can lock myself out :)" >> $TEMPFILE
echo "WHITELIST net:$MYIP       all" >> $TEMPFILE
echo "$finallist" >> $TEMPFILE
#cat $TEMPFILE
cp $TEMPFILE /etc/shorewall/blrules

# ===============================  Now we do the same for ipv6 ========================

# empty out the tempfile
cat /dev/null > $TEMPFILE

# copy original rules in
cat /etc/shorewall6/blrules | grep -v "#" | grep -v "$MYIPv6" | uniq >> $TEMPFILE

# hourly command for ipv6, limit set to 100
# grep -h "\[$(date -d -1hour +'%d/%b/%Y:%H:')" /var/log/apache2/access.log | cut -d' ' -f2 | grep -v "\." | sort | uniq -c | sort -nr | head -n10 | awk '$1>100' | cut -b 9-
banlistv6=`grep -h "\[$(date -d -1hour +'%d/%b/%Y:%H:')" /var/log/apache2/access.log | cut -d' ' -f2 | grep -v "\." | grep -v "$MYIPv6" | sort | uniq -c | sort -nr | head -n10 | awk '$1>50' | cut -b 9-`
for ip in $banlistv6
do
        echo "REJECT    net:$ip all" >> $TEMPFILE
done

# sort the combined new and old blocklists
finallistv6=`cat $TEMPFILE | grep -v "#" | sort -t : -k 2n`

# empty out the tempfile, seed it again and copy in the sorted list
cat /dev/null > $TEMPFILE
cat /usr/share/shorewall6/configfiles/blrules > $TEMPFILE
echo "# NB: high_traffic_to_shorewall.sh has my IPs hardcoded in it - if they change I can lock myself out :)" >> $TEMPFILE
echo "WHITELIST net:$MYIPv6     all" >> $TEMPFILE
echo "$finallistv6" >> $TEMPFILE
#cat $TEMPFILE
cp $TEMPFILE /etc/shorewall6/blrules

systemctl reload shorewall
