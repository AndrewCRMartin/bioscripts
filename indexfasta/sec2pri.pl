#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    sec2pri
#   File:       sec2pri.pl
#   
#   Version:    V1.0
#   Date:       12.04.24
#   Function:   
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
#   V1.0   12.04.24  Original
#
#*************************************************************************
use strict;

my($fname, $ac, %sec_pri, $indexfile, $entry, @acs, $tmp_fasta);
my(@omims, $omim, $tmp_mutant, $i, $results);
my($native_p, $resnum_p, $mutant_p);
my($native, $resnum, $mutant);

UsageDie() if(defined($::h));

# Get the SwissProt FASTA index information and connect to it
$indexfile = shift(@ARGV);

if((! -f "$indexfile.pag") || (! -f "$indexfile.dir"))
{
    die "Index file does not exist: $indexfile";
}
    

dbmopen %sec_pri, $indexfile, 0444 || die "Can't dbopen $indexfile";

while($ac = shift(@ARGV))
{
    # Grab a Primary accession
    $entry = GetPrimary($ac, \%sec_pri);
    print "$ac -> $entry\n";
}

# Tidy up
dbmclose %sec_pri;
close FILE;

#*************************************************************************
sub GetPrimary
{
    my($ac, $sec_pri_p) = @_;
    my $entry = "UNKNOWN";

    if(defined($$sec_pri_p{$ac}))
    {
        $entry = $$sec_pri_p{$ac};
    }
    return $entry;
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

sec2pri V1.0 (c) 2024, Prof. Andrew C.R. Martin

Usage: sec2pri     index_file sprot_code [sprot_code...]
       index_file  Index created by indexfasta
       sprot_code  SwissProt AC

Extracts one or more primary accessions from a secondary (or primary)
accession using an index created by indexsec2pri

__EOF

    exit 0;
}
