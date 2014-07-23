#! /usr/bin/perl
# fix.pl
# Randhier Ramlachan
#

$ReplicaName = "ETL-805-08";
$ReplicaIP = "192.168.17.27";
$ReplicaUser = "root";
$ReplicaPass = "IPStor101";

# Get all vid from iscli command into an array
open (my $file, '>data.txt');
my @listall = `iscli getvdevlist -s 127.0.0.1`;
my @list;
#Reads the array line by line and enters into another array reach until the Replica Resources section
foreach my $line (@listall)
{
	if ($line =~ m"Replica Resources:") {
		last;
	}
	# My attempt to not use the column map command but to match and get all the items at once FAILURE
	#if ($line =~ m"(\w+) (\d+) (\d+) (\w+) (\w+) ETL-805-08:(\d+)") {
	#print "$line";
	#}
	# Get the sixth column of the line
	my @reptrue = map {(split)[5]} split /\n/, $line;
	# If the sixth column is equal to the replica server proceed
	if (@reptrue[0] =~ m"$ReplicaName:(\d+)") {
		# Get the Primary VID and name
		my @PvidArr = map {(split)[1]} split /\n/, $line;
		my @PvidNameArr = map {(split)[0]} split /\n/, $line;
		$Pvid = @PvidArr[0];
		$PvidName = @PvidNameArr[0];
		$repVID = $1;
		# There are issues if you try to recreate the rep right after promote so a rescan is best, this is done after removing all replica
		# Get the snapshot status and if it returns failed then proceed to remove rep and sra then recreate rep to original Target VID
		$output =`iscli getsnapshotresourcestatus -s 127.0.0.1 -v $Pvid`;
		if ($output =~ m"Failed to get TimeMark information|Virtual device is not loaded") {
		#print "$output\n";
		# print the VIDs to a file for use after rescan.
		print $file "$Pvid=$repVID\n";
		print ("Name:",$PvidName," PVID:",$Pvid," RepVID:",$repVID,"\n");
		system ("iscli promotereplica -s 127.0.0.1 -v @Pvid -U $ReplicaUser -P $ReplicaPass");
		sleep (5);
		system ("iscli deletesnapshotresource -s 127.0.0.1 -v @Pvid");
		sleep (5);
		}
	}
	
};
# Close file rescan the system and open file again
close ($file);
system ("iscli rescandevices -s 127.0.0.1 -t");
open (my $file, 'data.txt');
# Go through file for the Primary Vdev and the Replica Vdev then recreate the replication
my @ArrFile = <$file>;
foreach my $line (@ArrFile)
{
	if ($line =~ m"(\d+)=(\d+)"){
	system ("iscli createreplication -s 127.0.0.1 -v $1 -o -ss 7 -S $ReplicaIP -U $ReplicaUser -P $ReplicaPass -V $2");
	sleep (5);
	}
}