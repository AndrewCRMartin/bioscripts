#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    getfasta
#   File:       getfasta.pl
#   
#   Version:    V1.0
#   Date:       25.02.13
#   Function:   
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2005-2013
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
#   V1.0   21.05.08  Original
#   V1.1   25.02.13  Modified to allow multiple codes to be given
#
#*************************************************************************
use strict;

my($fname, $ac, %sprot_tell, $indexfile, $entry, @acs, $tmp_fasta);
my(@omims, $omim, $tmp_mutant, $i, $results);
my($native_p, $resnum_p, $mutant_p);
my($native, $resnum, $mutant);

UsageDie() if(defined($::h));

# Get the SwissProt FASTA index information and connect to it
$fname = shift(@ARGV);
$indexfile = shift(@ARGV);
open(FILE,$fname) || die "Cannot open seq file $fname";
dbmopen %sprot_tell, $indexfile, 0666 || die "Can't dbopen $indexfile";

while($ac = shift(@ARGV))
{
    # Grab a FASTA format entry
    $entry = GetFASTA($ac, \%sprot_tell);
    print "$entry";
}

# Tidy up
dbmclose %sprot_tell;
close FILE;

#*************************************************************************
sub GetFASTA
{
    my($ac, $sprot_tell_p) = @_;
    my($pos, $entry);
    $entry = "";

    if(defined($$sprot_tell_p{$ac}))
    {
        $pos = $$sprot_tell_p{$ac};

        seek(FILE, $pos, 0);
        $entry = "";
        while(<FILE>)
        {
            if((/^>/) && ($entry ne ""))
            {
                last;
            }
            $entry .= $_;
        }
    }
    return $entry;
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

getfasta V1.1 (c) 2005-2013, UCL, Dr. Andrew C.R. Martin

Usage: getfasta.pl fasta_file index_file sprot_code [sprot_code...]
       fasta_file       FASTA file
       index_file       Index created by indexfasta
       sprot_code       SwissProt ID or AC depending on how the index 
                        was created

Extracts one or more sequences from a FASTA file using the specified index

__EOF

    exit 0;
}
