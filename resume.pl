#! /usr/bin/perl
# resume.pl
# Randhier Ramlachan
#

$ReplicaName = "ETL-805-08";
$ReplicaIP = "192.168.17.27";
$ReplicaUser = "root";
$ReplicaPass = "IPStor101";

open (my $file, '<data.backup1');
my @lines = <$file>;

foreach my $line (@lines)
{
#print $line;
	if ($line =~ m"(\d+)=(\d+)") {
		$Pvid = $1;
		$repVID = $2;
		$output =`iscli getsnapshotresourcestatus -s 127.0.0.1 -v $Pvid`;
		if ($output =~ m"Failed to get TimeMark information|Virtual device is not loaded") {
			print "VID $Pvid snap not loaded \n";
			$timemark =`iscli getvdevlist -s 127.0.0.1 -l -v $Pvid`;
			if ($timemark =~ m"TimeMark=Enabled") {
				print "Disable timemark from $Pvid\n";
				system ("iscli disabletimemark -s 127.0.0.1 -v $Pvid");
				sleep (5);
			}
			print "Deleting snapshot resource from $Pvid\n";
			system ("iscli deletesnapshotresource -s 127.0.0.1 -v $Pvid");
			sleep (10);
			$vidstatus = `iscli getvdevlist -s 127.0.0.1 -l -v $Pvid`;
			if ($vidstatus =~ m"State=on") {
				print "$Pvid is online \n";
				system ("iscli rescandevices -s 127.0.0.1 -t");
			} else {
					print "$pvid is not online, perforiming a rescan\n";
					system ("iscli rescandevices -s 127.0.0.1 -t");
			}
			print "Create replication for $Pvid to $repVID\n";
			system ("iscli createreplication -s 127.0.0.1 -v $Pvid -o -ss 7 -S $ReplicaIP -U $ReplicaUser -P $ReplicaPass -V $repVID -I \"07-15-2014 01:00\" -i 24H");
			sleep (15);
		}

	}
}

close ($file);