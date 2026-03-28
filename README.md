I was being hammered by bots and so decided to throw all traffic that came at me too much into a firewall. Fail2ban, mod-qos and mod-security2 were not catching these entries but they were killing php-fpm / apache2

I am using shorewall, so these entries are put into iptables, not nft.

The main script high_traffic_to_shorewall.sh assumes:
- you have a combined_vhost access log in /var/log/apache2/access.log
- you want to filter anything more than 100 hits in the last hour (awk '$1>100')
- there are only 10 ip addresses playing badly (head -n10)

You can tweak those values sd you like.
Fill in the variables at the top and set it up to run once an hour in crontab

7 * * * *      root    /path/to/script/high_traffic_to_shorewall.sh

You will also find a command you can run once a day to get the worst offenders for the day, so you can uncomment that and only run it once a day if you don't want to refresh your shorewall every hour.

Because this puts the IP addresses in /etc/shorewall/blrules, the IPs are banned pretty permanently. It is quite easy to put them in a fail2ban jail instead using something like

fail2ban-client set jailname banip $ip

in the for loop at the bottom and getting rid of all the stuff. Maybe I will do that some time (feel free to put a version of that in here :))
I have included a small script nslookupblrules.sh to verify quickly if any of the IPs in the block list are important or trash.
So far, all I have collected is pretty much trash, so I am quite happy to leave these IPs banned permanently.
