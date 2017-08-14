#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    indexfasta
#   File:       indexfasta.pl
#   
#   Version:    V1.5
#   Date:       27.07.13
#   Function:   Index the FASTA dump of SwissProt
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
#   13.06.05 V1.0  Original
#   06.12.06 V1.1  Format of the SwissProt FASTA dump has changed. Code
#                  now checks that some sequences were found and indexed
#   21.05.08 V1.2  Takes -i flag to index on ID rather than AC. Added -h
#   05.06.08 V1.3  Added second allowed AC format
#   30.09.08 V1.4  Title line now contains >sp|ac|id| instead of >ac|id|
#   27.07.13 V1.5  Supports trEMBL as well as SwissProt
#
#*************************************************************************
use strict;
my($fname, %sprot_tell, $indexfile, $key, $pos, $count);

UsageDie() if(defined($::h));

$fname = shift(@ARGV);
$indexfile = shift(@ARGV);

open(FILE,$fname) || die "Cannot open seq file $fname";
dbmopen %sprot_tell, $indexfile, 0666 || die "Can't dbopen $indexfile";

$pos = 0;
$count = 0;
while(<FILE>) {
# 06.12.06 The format of this line changed!!!!
# 05.06.08 Added te second allowed format
#    if(/^>(\w+)\s\(([OPQ][0-9][A-Z0-9][A-Z0-9][A-Z0-9][0-9])\)/)
#    if((/^>([OPQ][0-9][A-Z0-9][A-Z0-9][A-Z0-9][0-9])\|(\w+)\s/) ||
#       (/^>([A-NR-Z][0-9][A-Z][A-Z0-9][A-Z0-9][0-9])\|(\w+)\s/))
# 30.09.08 Format has changed again
# 27.07.13 Added trEMBL (tr rather than sp) support - actually any
#          2 characters
    if((/^>(..\|)?([OPQ][0-9][A-Z0-9][A-Z0-9][A-Z0-9][0-9])\|(\w+)\s/) ||
       (/^>(..\|)?([A-NR-Z][0-9][A-Z][A-Z0-9][A-Z0-9][0-9])\|(\w+)\s/))
    {
        if(defined($::i))
        {
            $key=$3;
        }
        else
        {
            $key=$2;
        }
        $sprot_tell{$key} = $pos;
        $count++;
    }
    $pos = tell(FILE);
}

dbmclose %sprot_tell;
close(FILE);

if($count == 0)
{
    print STDERR <<__EOF;
FATAL ERROR (indexfasta.pl): No sequences were found to index
__EOF
    exit(1);
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

indexfasta V1.4 (c) 2005-2008 UCL, Dr. Andrew C.R. Martin, 

Usage: indexfasta [-h] [-i] infile.faa indexfile.idx
       -h              this help message
       -i              index on ID rather than AC
       infile.faa      A FASTA file as distributed with SwissProt
       indexfile.idx   A DBM hash index file

Creates a DBM hash index for a SwissProt FASTA dump file

__EOF

   exit(0);
}
