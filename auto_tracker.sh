#!/bin/bash
list=`wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt|awk NF|sed ":a;N;s/\n/,/g;ta"`
if [ -z "`grep "bt-tracker" /data/aria2/aria2.conf`" ]; then
    sed -i '$a bt-tracker='${list} /data/aria2/aria2.conf
    echo add......
else
    sed -i "s@bt-tracker.*@bt-tracker=$list@g" /data/aria2/aria2.conf
    echo update......
fi
sh /data/aria2/aria2.sh restart