#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    arff2snns
#   File:       arff2snns.pl
#   
#   Version:    V1.0
#   Date:       14.06.21
#   Function:   Convert ARFF file to SNNS .pat format
#   
#   Copyright:  (c) Prof. Andrew C. R. Martin, UCL, 2021
#   Author:     Prof. Andrew C. R. Martin
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
#   Converts an ARFF file to SNNS .pat format
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   14.06.21  Original
#
#*************************************************************************
use strict;

my $input = "";
# Check for -h - help request
UsageDie() if(defined($::h));

my $inData = 0;
my @data   = ();

while(<>)
{
    chomp;
    s/^\s+//;
    if(length)
    {
        if(/\@relation/)
        {
        }
        elsif(/\@attribute/)
        {
            my @fields = split;
            
            if(BadAttributes($fields[2]))
            {
                print STDERR "\nThe current version does not handle non-Boolean class attributes:\n";
                print STDERR "   $_\n\n";
                exit 1;
            }
        }
        elsif(/\@data/)
        {
            $inData = 1;
        }
        elsif($inData)
        {
            if(/\?/)
            {
                printf STDERR "\nLine containing undefined values skipped\n";
                printf STDERR "   $_\n";
            }
            else
            {
                my $dataLine = ConvertLine($_);
                push @data, "$dataLine";
            }
        }
    }
}

PrintSNNSHeader(\@data);
PrintData(\@data);


#*************************************************************************
sub PrintData
{
    my($aData) = @_;
    
    my $count = 1;
    foreach my $datum (@$aData)
    {
        my @fields = split(/\s+/,$datum);
        my $out    = pop(@fields);
        
        print "# Input line $count\n";
        print "@fields\n";
        print "# Output\n";
        print "$out\n";
        $count++;
    }
}


#*************************************************************************
sub BadAttributes
{
    my($field) = @_;
    
    $field =~ s/numeric//i; # Remove numeric
    $field =~ s/\,//g;      # Remove commas
    $field =~ s/\{//;       # Remove {
    $field =~ s/\}//;       # Remove }
    $field =~ s/TRUE//i;    # Remove TRUE
    $field =~ s/FALSE//i;   # Remove FALSE
    
    return(1) if(length($field));

    return(0);
}


#*************************************************************************
sub ConvertLine
{
    my($line) = @_;
    $line =~ s/FALSE/0/g;
    $line =~ s/TRUE/1/g;
    $line =~ s/\,/ /g;

    return($line);
}


#*************************************************************************
sub PrintSNNSHeader
{
    my($aData) = @_;

    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @days   = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    
    my $dateString = localtime();
    my @fields = split(/\s+/, @$aData[0]);

    print "SNNS pattern definition file V3.2\n";
    print "generated at $dateString\n";
    print "\n";
    print "\n";
    print "\n";
    printf("No. of patterns : %d\n", scalar(@$aData));
    printf("No. of input units : %d\n", scalar(@fields) - 1);
    print "No. of output units : 1\n";
    print "\n";
}


#*************************************************************************
sub UsageDie
{
    print <<__EOF;

arff2snns V1.0 (c) UCL, Prof. Andrew C.R. Martin

  Usage: arff2snns [input.arff] > snns.pat

This is a very simple program to convert Weka ARFF files to SNNS .pat 
pattern files. If no input file is specified, it reads from standard
input.

Limitations:
 - It can only handle numeric and Boolean attributes (including for 
   outputs)
 - It can only handle a single output which must be the last field in the
   .arff file

__EOF

    exit 0;
}
