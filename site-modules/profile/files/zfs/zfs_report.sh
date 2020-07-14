#!/bin/sh
 
echo "ZFS listing:"
/sbin/zfs list
echo
 
echo "ZFS compression ratio:"
/sbin/zfs get compressratio | /bin/grep -v @
echo
 
echo "ZFS ARC (Adaptive Replacement Cache):"
/bin/cat /proc/spl/kstat/zfs/arcstats | /bin/grep "^c " | awk '{print "ZFS ARC mem: " ($3/1024/1024/1024) " GB"}'
hits=`/bin/cat /proc/spl/kstat/zfs/arcstats | grep "^hits" | awk '{print $3}' `
misses=`/bin/cat /proc/spl/kstat/zfs/arcstats | grep "^misses" | awk '{print $3}' `
echo $hits $misses | sed 'N;s/\n/ /g' | awk '{ print "ZFS ARC hitratio: " $1/($1+$2)*100 "%" }'
echo
 
echo "ZPool Status:"
/sbin/zpool status
echo 
 
echo "ZPool iostat:"
/sbin/zpool iostat -v
echo
 
# not needed on vmware
#echo "Drive ID:"
#for i in `/sbin/zpool status | /usr/bin/sed -n "s/[^a-z]\{1,\}\([a-z]\{2,3\}[0-9]\{1,\}\).\{1,\}/\1/g p"`;
#do
#       echo -n "  $i:  "
#       /usr/local/sbin/smartctl -i /dev/$i | /usr/bin/sed -n -e '5,7p' | /usr/bin/sed -e 's/^.\{1,\}:[^0-9A-Za-z]\{1,\}//g' | /usr/bin/sed -n -e 'N;s/\n/ (/;N;s/\n/) - S:/;p'
#done
#echo 
# 
#echo "Drive health:"
#for i in `/sbin/zpool status | /usr/bin/sed -n "s/[^a-z]\{1,\}\([a-z]\{2,3\}[0-9]\{1,\}\).\{1,\}/\1/g p"`;
#do
#           echo -n "  $i:      "
#               /usr/local/sbin/smartctl -H /dev/$i | /usr/bin/grep -Eo "result: .+"
#done
#echo
# 
#echo "Drive temperature:"
#for i in `/sbin/zpool status | /usr/bin/sed -n "s/[^a-z]\{1,\}\([a-z]\{2,3\}[0-9]\{1,\}\).\{1,\}/\1/g p"`;
#do
#           echo -n "  $i:      "
#               /usr/local/sbin/smartctl -l scttempsts /dev/$i | /usr/bin/sed -n -e "9p" | /usr/bin/grep -Eo "[0-9?]+ Celsius"
#done
#echo
 
echo "ZFS snapshots:"
/sbin/zfs list -t snapshot | /usr/bin/awk 'BEGIN { LAST = "a"} { match($0,"^.+@"); NEXT = substr($0,0,RLENGTH); if (LAST != NEXT) {print ""; LAST = NEXT;}; print $0; }'
echo
