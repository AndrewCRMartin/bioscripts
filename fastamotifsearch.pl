#!/acrm/usr/local/bin/perl -s
#*************************************************************************
#
#   Program:    fastamotifsearch
#   File:       fastamotifsearch.pl
#   
#   Version:    V0.1
#   Date:       13.03.13
#   Function:   search a FASTA file for a sequence pattern of the form
#               SAXSSXA
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2013
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Institute of Structural and Molecular Biology
#               Division of Biosciences
#               University College
#               Gower Street
#               London
#               WC1E 6BT
#   EMail:      andrew@bioinf.org.uk
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
#   Very simple program to find simple regular expression matches in a 
#   FASTA sequence file
#
#*************************************************************************
#
#   Usage:
#   ======
#   fastamotifsearch pattern fastafile
#
#*************************************************************************
#
#   Revision History:
#   =================
#
#*************************************************************************

use strict;

my $pattern = shift @ARGV;
my $file    = shift @ARGV;

open(FILE, $file) || die "Can't read FASTA file: $file";


$pattern =~ s/X/\./g;


while(1)
{
    my ($label, $sequence) = GetFASTASequence();
    last if ($label eq "");

    if($sequence =~ $pattern)
    {
        print "$label\n";
    }
}

$::labelline = "";
sub GetFASTASequence
{
    my($label, $sequence);
    return ("","") if(eof(FILE));
    while(<FILE>)
    {
        chomp;
        if(/^>/)
        {
            if($::labelline ne "")
            {
                $label = $::labelline;
                $::labelline = $_;
                return($label, $sequence);
            }
            else
            {
                $::labelline = $_;
            }
        }
        else
        {
            $sequence .= $_;
            $sequence =~ s/\s//g;
        }
    }
    return($::labelline, $sequence);
}

