#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    indexsec2pri
#   File:       indexsec2pri.pl
#   
#   Version:    V1.0
#   Date:       12.04.24
#   Function:   Index the SwissProt data file to create a secondary ->
#               primary accession map
#   
#   Copyright:  (c) Prof. Andrew C. R. Martin 2024
#   Author:     Prof. Andrew C. R. Martin
#   EMail:      andrew@bioinf.org.uk
#   Web:        http://www.bioinf.org.uk/
#               
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#*************************************************************************
#
#   Usage:
#   ======
#
#*************************************************************************
#
#   Revision History:
#   =================
#   12.04.24 V1.0  Original
#
#*************************************************************************
use strict;
my($fname, %sec_pri, $indexfile, $key, $ac);
my $count = 0;
UsageDie() if(defined($::h));

$fname     = shift(@ARGV);
$indexfile = shift(@ARGV);

open(FILE,$fname) || die "Cannot open seq file $fname";
dbmopen %sec_pri, $indexfile, 0666 || die "Can't dbopen $indexfile";
$|=1;

while(<FILE>)
{
    if(/^ID\s+/)
    {
        $ac = "";
    }
    elsif(/^AC\s+(.*)/)
    {
        $ac .= " " . $1;
        print "." if(!(++$count % 100));
    }
    elsif(/^\/\//)
    {
        $ac =~ s/\s//g;
        my @acs = split(/;/, $ac);
        my $priAC = $acs[0];
        
        foreach $ac (@acs)
        {
            if(defined($sec_pri{$ac}))
            {
                $sec_pri{$ac} .= " $priAC";
            }
            else
            {
                $sec_pri{$ac} = $priAC;
            }
        }
    }
}
print "\nIndex complete\n";

dbmclose %sec_pri;
close(FILE);

if($count == 0)
{
    print STDERR <<__EOF;
FATAL ERROR (indexsecpri): No accessions were found to index
__EOF
    exit(1);
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

indexsecpri V1.0 (c) 2014 Prof. Andrew C.R. Martin, 

Usage: indexsecpri [-h] [-q] infile.dat indexfile.idx
       -h              this help message
       infile.dat      A SwissProt .dat file 
       indexfile.idx   A DBM hash index file

Creates a DBM hash index for a SwissProt .dat file mapping secondary
accessions to the primary accession.

__EOF

   exit(0);
}
