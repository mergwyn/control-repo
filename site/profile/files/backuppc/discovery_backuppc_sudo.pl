#!/usr/bin/perl

use lib "/usr/share/backuppc/lib";
use BackupPC::Lib;
use BackupPC::CGI::Lib;
use POSIX;
use JSON;
use Getopt::Long;
use MIME::Base64 qw( decode_base64 );

my $regex = '.*';
my $base64 = 0;

GetOptions(
    "regex=s" => \$regex,
    "base64"  => \$base64
);

$regex = decode_base64($regex) if ($base64);
$regex = qr($regex);

# We need to switch to backuppc UID/GID
my $uid = getuid();
my $gid = getgid();
my (undef,undef,$bkpuid,$bkpgid) = getpwnam('backuppc');
setuid($bkpuid) if ($uid ne $bkpuid);
setgid($bkpgid) if ($gid ne $bkpgid);

my $bpc = BackupPC::Lib->new();
my $hosts = $bpc->HostInfoRead();
my $mainConf = $bpc->ConfigDataRead();

my $json;
@{$json->{data}} = ();
foreach my $host (keys %$hosts){
   next unless ($host =~ m!$regex!);
   my $hostConf = $bpc->ConfigDataRead($host);
   my $conf = { %$mainConf, %$hostConf };
   my $warning = $conf->{EMailNotifyOldBackupDays};
   my $errors = (defined $conf->{MaxXferError}) ? $conf->{MaxXferError}: '0';
   my $status = ($conf->{BackupsDisable} eq '1') ? 'disabled':(($conf->{ZabbixMonitoring} eq '0') ? 'disabled':'enabled');
   push @{$json->{data}},
       {  
           "{#BPCHOST}" => $host,
           "{#BPCNOBACKUPWARNING}" => $warning,
           "{#BPCMAXERROR}" => $errors,
           "{#BPCSTATUS}" => $status,
       };
}
print to_json($json, { ascii => 1, pretty => 1 });
exit(0);
