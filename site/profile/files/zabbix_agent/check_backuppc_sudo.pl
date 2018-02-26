#!/usr/bin/perl

use lib "/usr/share/backuppc/lib";
use BackupPC::Lib;
use BackupPC::CGI::Lib;
use POSIX;
use JSON;

# We need to switch to backuppc UID/GID
my $uid = getuid();
my $gid = getgid();
my (undef,undef,$bkpuid,$bkpgid) = getpwnam('backuppc');
setuid($bkpuid) if ($uid ne $bkpuid);
setgid($bkpgid) if ($gid ne $bkpgid);

my $host = $ARGV[0];
my $what = $ARGV[1];

my $bpc = BackupPC::Lib->new();
my @backups = $bpc->BackupInfoRead($host);
my $mainConf = $bpc->ConfigDataRead();
my $hostConf = $bpc->ConfigDataRead($host);
my $conf = { %$mainConf, %$hostConf };
my $fullCnt = $incrCnt = 0;
my $fullAge = $incrAge = $lastAge = -1;
my $lastXferErrors = 0;
my $maxErrors = 0;

for ( my $i = 0 ; $i < @backups ; $i++ ) {
    if ( $backups[$i]{type} eq "full" ) {
        $fullCnt++;
        if ( $fullAge < 0 || $backups[$i]{startTime} > $fullAge ) {
            $fullAge  = $backups[$i]{startTime};
            $fullSize = $backups[$i]{size};
            $fullDur  = $backups[$i]{endTime} - $backups[$i]{startTime};
        }
    }
    else {
        $incrCnt++;
        if ( $incrAge < 0 || $backups[$i]{startTime} > $incrAge ) {
            $incrAge = $backups[$i]{startTime};
        }
    }
}
if ( $fullAge > $incrAge && $fullAge >= 0 )  {
    $lastAge = $fullAge;
}
else {
    $lastAge = $incrAge;
}
if ( $lastAge < 0 ) {
    $lastAge = "";
}
else {
    $lastAge = sprintf("%.1f", (time - $lastAge) / (24 * 3600));
}
$lastXferErrors = $backups[@backups-1]{xferErrs} if ( @backups );
$maxErrors = $conf->{MaxXferError} if (defined $conf->{MaxXferError});

if ($what eq 'errors'){
    print $lastXferErrors;
}
elsif ($what eq 'max_errors'){
    print $maxErrors;
}
elsif ($what eq 'age'){
    print $lastAge;
}
elsif ($what eq 'size'){
    print $fullSize;
}
elsif ($what eq 'duration'){
    print $fullDur;
}
elsif ($what eq 'notify'){
    print $conf->{EMailNotifyOldBackupDays};
}
else{
  print<<"EOF";

Usage: $0 <host> [errors|age|size|duration|notify|max_errors]

EOF
}
exit(0);
