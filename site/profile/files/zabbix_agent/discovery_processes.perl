#!/usr/bin/perl
 
$first = 1;
 
print "{\n";
print "\t\"data\":[\n\n";
 
#for (`ps --no-headers axo comm,euser | egrep -v '1[0-9][0-9][0-9]*\$' | awk 'NF{--NF};1' | sort | uniq -c`) {
for (`ps --no-headers axo comm,cgroup | egrep -v "11:[a-z]*:/lxc/" | cut -b 1-15 | sort | uniq -c`) {
  my ($procname) = m/^\s*[0-9]+ (\S+)/;

  print "\t,\n" if not $first;
  $first = 0;

  print "\t{\n";
  print "\t\t\"{#PROCNAME}\":\"$procname\"\n";
  print "\t}\n";
  }
 
print "\n\t]\n";
print "}\n";
