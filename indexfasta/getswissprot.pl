#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    getswissprot
#   File:       getswissprot.pl
#   
#   Version:    V1.0
#   Date:       
#   Function:   
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
#
#*************************************************************************
use strict;

my($fname, $ac, %sprot_tell, $indexfile, $entry, @acs, $tmp_fasta);
my(@omims, $omim, $tmp_mutant, $i, $results);
my($native_p, $resnum_p, $mutant_p);
my($native, $resnum, $mutant);

UsageDie() if(defined($::h));

# Get the SwissProt .dat index information and connect to it
$fname = shift(@ARGV);
$indexfile = shift(@ARGV);
open(FILE,$fname) || die "Cannot open seq file $fname";
dbmopen %sprot_tell, $indexfile, 0666 || die "Can't dbopen $indexfile";

$ac = shift(@ARGV);
$ac = "\U$ac";

if(defined($::f))
{
    # Grab a FASTA format entry
    $entry = GetFASTA($ac, \%sprot_tell);
}
else
{
    $entry = GetSwissProt($ac, \%sprot_tell);
}
print "$entry";

# Tidy up
dbmclose %sprot_tell;
close FILE;


#*************************************************************************
sub GetSwissProt
{
    my($ac, $sprot_tell_p) = @_;
    my($pos, $entry);
    $entry = "";

    if(defined($$sprot_tell_p{$ac}))
    {
        $pos = $$sprot_tell_p{$ac};

        seek(FILE, $pos, 0);
        while(<FILE>)
        {
            $entry .= $_;
            if(/^\/\//)
            {
                last;
            }
        }
    }
    return $entry;
}

#*************************************************************************
sub GetFASTA
{
    my($key, $sprot_tell_p) = @_;
    my($pos, $entry);
    my $ac = "";
    my $id = "";
    my $seq = "";
    $entry = "";

    if(defined($$sprot_tell_p{$key}))
    {
        $pos = $$sprot_tell_p{$key};

        seek(FILE, $pos, 0);
        while(<FILE>)
        {
            if(/^ID\s+(\S+_\S+)\s+/)
            {
                $id = $1;
            }
            elsif(($ac eq "") && (/^AC\s+(.*?);/))
            {
                $ac = $1;
            }
            elsif(/^\s+(.*)/)
            {
                $seq .= $1 . "\n";
            }
            elsif(/^\/\//)
            {
                last;
            }
        }
        $entry = ">sp|$ac|$id\n$seq";
    }

    return $entry;
}


#*************************************************************************
sub UsageDie
{
    print <<__EOF;

getswissprot V1.0 (c) 2010, UCL, Dr. Andrew C.R. Martin

Usage: getswissprot.pl [-f] swissprot_file index_file sprot_code
       -f               FASTA output rather than SwissProt data
       swissprot_file   SwissProt file
       index_file       Index created by indexswissprot
       sprot_code       SwissProt ID or AC

Extracts a sequence from a SwissProt file using the specified index

__EOF

    exit 0;
}
