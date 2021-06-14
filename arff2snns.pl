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
                printf STDERR "\nLine containing underfined values skipped\n";
                printf STDERR "   $_\n";
            }
            else
            {
                s/FALSE/0/g;
                s/TRUE/1/g;
                s/\,/ /g;
                push @data, "$_";
            }
        }
    }
}

my @fields = split(/\s+/, @data[0]);

print "SNNS pattern definition file V3.2\n";
print "generated at Wed Oct 14 11:46:48 2009\n";
print "\n";
print "\n";
print "\n";
printf("No. of patterns : %d\n", scalar(@data));
printf("No. of input units : %d\n", scalar(@fields) - 1);
print "No. of output units : 1\n";
print "\n";

my $count = 1;
foreach my $datum (@data)
{
    my @fields = split(/\s+/,$datum);
    my $out    = pop(@fields);
    
    print "# Input line $count\n";
    print "@fields\n";
    print "# output line $count\n";
    print "$out\n";
    $count++;
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
