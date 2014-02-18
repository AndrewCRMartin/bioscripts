#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    arff2csv
#   File:       arff2csv.pl
#   
#   Version:    V1.0
#   Date:       29.06.12
#   Function:   Convert ARFF file to CSV format
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2012
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
#
#*************************************************************************
#
#   Usage:
#   ======
#   Converts an ARFF file to CSV format
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   29.06.12  Original
#
#*************************************************************************
use strict;

# Check for -h - help request
UsageDie() if(defined($::h));

my $inData = 0;
my @attributes = ();

while(<>)
{
    chomp;
    s/^\s+//;
    if(/^\@/)
    {
        if(/^\@data/)
        {
            # Print the attributes
            print join(',',@attributes) . "\n";
            $inData = 1;
        }
        elsif(/^\@attribute/)
        {
            my @fields = split;
            push @attributes, $fields[1];
        }
    }
    elsif($inData)
    {
        s/TRUE/1/g;
        s/FALSE/0/g;
        print "$_\n";
    }
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

arff2csv V1.0 (c) 2012, UCL, Dr. Andrew C.R. Martin

Usage: arff2csv [file.arff] > file.csv

       file.arff     - input ARFF file - reads from standard input if
                       not specified
       file.csv      - input CSV file(s) (standard output)

This performs a very simple conversion of an ARFF file to CSV format. It
simply prints the attribute names as the first record and then shows the
ARFF data records. TRUE/FALSE values are converted to 1/0

__EOF

    exit 0;
}
