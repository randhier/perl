#!/usr/bin/perl
#
# ExpandTimemark.pl
# Script works with the log file output of the preflight_check.sh script
# Expands the snapshot resource of the failed VIDs for upgrade to be successful  
#

############################################################
# Main Section
#

#Define file
$upgradelog= "/var/log/upgradecheck.log";

# Check that file does exist
if ( ! -e $upgradelog )
{
   print "$ARGV[0]: File $upgradelog does not exist.";
   exit 10;
}

# Read in the file
open($infile, " < $upgradelog");

# Checks every line
my @lines = <$infile>;
foreach my $line (@lines)
{
   # Get the VID of resource from the log that needs to be expanded
   if ($line =~ m"The snapshot resource ID (\d+) for the device VID (\d+) \(\d+ blks\) is too small for TimeMark conversion.")
   {
     $vidline= "$2";
     # Get snapshot resource status of VID
     @result = `iscon getsnapshotresourcestatus -s 127.0.0.1 -v $vidline`;
     foreach my $isconln (@result)
     {
	# Get rosurce size and used size
	if ($isconln =~ m"Snapshot Resource Size=(\d+) (\w+)")
        {
	    $ressize= "$1";
        }
	if ($isconln =~ m"Used Size=(\d+\.*\d*) (\w+)")
	{
	    $usedsize= "$1";
	    # See if bit is MB, KB or GB
	    $bit= "$2";
	    # If not MB convert
	    if ($bit =~ m"KB")
    	    {
	    	$usedsize= $usedsize / 1024;
	    }
	    if ($bit =~ m"GB")
	    {
		$usedsize= $usedsize * 1024;
	    }
	}
     }
     # Subtract the used size from the total to determine the freed
     $freesize= $ressize - $usedsize; 
     # Get the size needed to expand to 2GB
     $expandsize= 2048 - $freesize;
     # iscon does not except float/decimal numbers. Round up any nuumbers
     use POSIX;
     $expandsize= ceil($expandsize);
     print "VID $vidline resource size is $ressize MB.  $usedsize MB is being used.  There is $freesize MB free, need to expand by $expandsize\n";
     print "iscon expandsnapshotresource -s 127.0.0.1  -v $vidline -m $expandsize\n";
     # Execute expansion
     @expndresult = `iscon expandsnapshotresource -s 127.0.0.1  -v $vidline -m $expandsize`;
     foreach my $expndln (@expndresult)
     {
	print "$expndln\n";
     }	
   }
}

exit 0
