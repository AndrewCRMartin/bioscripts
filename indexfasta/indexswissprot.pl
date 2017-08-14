#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    indexfasta
#   File:       indexfasta.pl
#   
#   Version:    V1.4
#   Date:       30.09.08
#   Function:   Index the SwissProt data file
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2010
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
#               martin@biochem.ucl.ac.uk
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
#   26.01.10 V1.0  Original
#
#*************************************************************************
use strict;
my($fname, %sprot_tell, $indexfile, $key, $pos, $count, $id, $start_pos, $ac);

UsageDie() if(defined($::h));

$fname = shift(@ARGV);
$indexfile = shift(@ARGV);

open(FILE,$fname) || die "Cannot open seq file $fname";
dbmopen %sprot_tell, $indexfile, 0666 || die "Can't dbopen $indexfile";

$pos = 0;
$start_pos = 0;
$count = 0;
while(<FILE>) {
    if(/^ID\s+(\S+_\S+)\s+/)
    {
        $id = $1;
        $start_pos = $pos;
        $count++;
        $ac = "";
    }
    elsif(/^AC\s+(.*)/)
    {
        $ac .= " " . $1;
    }
    elsif(/^\/\//)
    {
        if(defined($sprot_tell{$id}) && !defined($::q))
        {
            print "Warning: ID $id found multiple times\n";
        }
        $sprot_tell{$id} = $start_pos;
        $ac =~ s/\s//g;
        my @acs = split(/;/, $ac);
        foreach $ac (@acs)
        {
            if(defined($sprot_tell{$ac}) && !defined($::q))
            {
                print "Warning: AC $ac found multiple times\n";
            }
            $sprot_tell{$ac} = $start_pos;
        }
    }
    $pos = tell(FILE);
}

dbmclose %sprot_tell;
close(FILE);

if($count == 0)
{
    print STDERR <<__EOF;
FATAL ERROR (indexswissprot.pl): No sequences were found to index
__EOF
    exit(1);
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

indexswissprot V1.0 (c) 2010 UCL, Dr. Andrew C.R. Martin, 

Usage: indexswissprot [-h] [-q] infile.dat indexfile.idx
       -h              this help message
       -q              Quiet - doesn't report multiple entries
       infile.dat      A SwissProt .dat file 
       indexfile.idx   A DBM hash index file

Creates a DBM hash index for a SwissProt .dat file based on ID and AC

__EOF

   exit(0);
}
