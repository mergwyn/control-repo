#!/bin/bash
 
first=1
 
echo  "{"
echo  "	\"data\":["
 
ps --no-headers axo cgroup,comm |
       	egrep -v "11:[a-z]*:/lxc/" |
       	cut -f 2- -d ' ' |
       	sort -u |
while read procname
do
  [[ "$first" = 1 ]]  || echo "	," 
  first=0

  echo "	{"
  echo "		\"{#PROCNAME}\":\"$procname\""
  echo "	}"
done
 
echo "	]"
echo "}"
