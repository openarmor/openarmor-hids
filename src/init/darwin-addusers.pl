#!/usr/bin/env perl
#######################################
# Name:    openarmor-add-ung.pl
# Desc:    Add openarmor users and groups on OSX using the NetInfo cmds
# Author:  Chuck L.
# License: GPL
###
# for vi: set tabstop=4
#######################################

# Variables and whatnot
my ($debug, $oUid, $oGid, @inUseUids, @inUseGids, $rev, $revDate);
$rev     = '0.2-1';
$revDate = '30-Aug-2006';
$debug   = '0';
$fName   = "/tmp/niusers.tmp";

# Commands
$NILOAD  = "/usr/bin/niload";
$NIRPT   = "/usr/bin/nireport";
$NIUTIL  = "/usr/bin/niutil";
$SORT    = "/usr/bin/sort";
$GREP    = "/usr/bin/grep";
$SUDO    = "/usr/bin/sudo";

# Subroutine calls
findUsersGroups();
createUsersGroups();

sub findUsersGroups {
    @inUseUids = `$NIRPT . /users uid | $GREP "^5[0-9][0-9]" | $SORT -ru`;
    @inUseGids = `$NIRPT . /groups gid | $GREP "^5[0-9][0-9]" | $SORT -ru`;

    foreach (@inUseUids) {
        chomp();
        print "In use UID: $_\n" if $debug;
        if ($oUid < $_) {
            $oUid = $_;
        }
    }
    $oUid++;
    print "Next available UID: $oUid\n" if $debug;

    foreach (@inUseGids) {
        chomp();
        print "In use GID: $_\n" if $debug;
        if ($oGid < $_) {
            $oGid = $_;
        }
    }
    $oGid++;
    print "Next available GID: $oGid\n" if $debug;
} # end sub

sub createUsersGroups {
    print "Sub - UID is: $oUid\n" if $debug;
    print "Sub - GID is: $oGid\n" if $debug;

    my $oUidM = $oUid + 1;
    my $oUidE = $oUid + 2;
    my $oUidR = $oUid + 3;

    $niPid = open (NIFH, "| $SUDO $NILOAD -v group /");
    print "Adding openarmor group\n" if $debug;
    print NIFH "openarmor:*:" . $oGid . ":openarmor,openarmorm,openarmorr\n";
    close (NIFH);

    $fh = open (NITMP, ">$fName") or die "Unable to create temp file: $!\n";

    print "Adding openarmor users\n" if $debug;
    print NITMP "openarmor:*:" . $oUid . ":" . $oGid . "::0:0:openarmor acct:/var/openarmor:/sbin/nologin\n";
    print NITMP "openarmorm:*:" . $oUidM . ":" . $oGid . "::0:0:openarmorm acct:/var/openarmor:/sbin/nologin\n";
    print NITMP "openarmorr:*:" . $oUidR . ":" . $oGid . "::0:0:openarmorr acct:/var/openarmor:/sbin/nologin\n";

    close ($fh);
    $rtnVal = system("$SUDO $NILOAD -v passwd / < $fName");
    print "Return value from syscmd: $rtnVal\n" if $debug;
    unlink ($fName);

} # end sub

