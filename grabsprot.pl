#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    grabsprot
#   File:       grabsprot.pl
#   
#   Version:    V1.1
#   Date:       05.02.14
#   Function:   Grab a UniProt file from the UniProt website
#   
#   Copyright:  (c) Dr. Andrew C. R. Martin, UCL, 2013-2014
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
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   20.12.13  Original
#   V1.1   05.02.14  Changed -d option to use for DNA downloads
#                    and -debug for debugging
#
#*************************************************************************
use LWP::UserAgent;
use strict;

#*************************************************************************
$::URLUPtemplate = "http://www.uniprot.org/uniprot/%s.%s";
$::URLDNAtemplate = "http://www.ebi.ac.uk/ena/data/view/%s&display=%s";
$::OutTemplate = "%s.%s";
#*************************************************************************

UsageDie() if(defined($::h) || (scalar(@ARGV) == 0));

# Grab accession code from command line
my $ac = shift @ARGV;
my $outFile = "";
my $data;

if(defined($::d))
{
    # First grab the SwissProt entry in txt format
    my $url = CreateURL($::URLUPtemplate, $ac, "txt");

    # Grab the SwissProt file
    print "Grabbing: $url\n" if(defined($::v) || defined($::debug));
    my $ok;
    ($ok, $data) = GetFile($url);
    if(!$ok)
    {
        print STDERR "$data\n";
        print STDERR "URL: $url\n";
        exit 1;
    }

    # Find the DNA cross reference
    my $dnaAccession = FindDNAAccession($data);
    if($dnaAccession eq "")
    {
        print STDERR "Unable to find EMBL cross-reference\n";
        exit 1;
    }

    if(defined($::v))
    {
        print "Identified DNA accession as: $dnaAccession\n";
    }

    # Build the URL to obtain the DNA data
    my $type = ((defined($::f))?"fasta":"text");
    $url = CreateURL($::URLDNAtemplate, $dnaAccession, $type);

    # Build the output filename
    my $outType = ((defined($::f))?"dna.fasta":"dna.txt");
    $outFile = CreateFilename($ac, $outType, @ARGV);

    # Grab the EMBL file
    print "Grabbing: $url\n" if(defined($::v) || defined($::debug));
    ($ok, $data) = GetFile($url);
    if(!$ok)
    {
        print STDERR "$data\n";
        print STDERR "URL: $url\n";
        exit 1;
    }
}
else
{
    my $type = ((defined($::f))?"fasta":"txt");

    # Create the URL and output filename
    my $url = CreateURL($::URLUPtemplate, $ac, $type);
    $outFile = CreateFilename($ac, $type, @ARGV);

    # Grab the file
    print "Grabbing: $url\n" if(defined($::v) || defined($::debug));
    my $ok;
    ($ok, $data) = GetFile($url);
    if(!$ok)
    {
        print STDERR "$data\n";
        print STDERR "URL: $url\n";
        exit 1;
    }
}

if(!WriteData($data, $outFile))
{
    print STDERR "Can't write file: $outFile\n";
    exit 1;
}


#*************************************************************************
sub FindDNAAccession
{
    my($data) = @_;

    my @lines = split(/\n/, $data);

    # Look for an EMBL mRNA entry
    foreach my $line (@lines)
    {
        if($line =~ /^DR\s+EMBL;\s+(.*?);.*mRNA/)
        {
            return($1);
        }
    }

    # Look for an EMBL mRNA entry
    foreach my $line (@lines)
    {
        if($line =~ /^DR\s+EMBL;\s+(.*?);\s+(.*?);.*Genomic_DNA/)
        {
            my $ac = $2;
            $ac =~ s/\..*//;
            return($ac);
        }
    }

    return("");
}

#*************************************************************************
# Writes the data to the specified file. If the filename is '-' or 
# 'stdout', then it writes to standard output
#
# 28.02.13 Original   By: ACRM
sub WriteData
{
    my($data, $file) = @_;

    print STDERR "Writing data file: $file\n" if(defined($::debug));

    if(($file eq "-") || ($file eq "stdout"))
    {
        print $data;
    }
    else
    {
        if(open(FILE, ">$file"))
        {
            print FILE $data;
            close FILE;
        }
        else
        {
            return 0;
        }
    }
    return(1);
}


#*************************************************************************
# Generates a filename from the command line if one was specified, 
# otherwise builds a filename from the accession and type using the global
# template.
#
# 20.12.13 Original   By: ACRM
sub CreateFilename
{
    my($ac, $type, @args) = @_;

    if(scalar(@args))
    {
        return($args[0]);
    }

    my $fileName = sprintf($::OutTemplate, $ac, $type);

    print STDERR "Output filename: $fileName\n" if(defined($::debug));

    return($fileName);
}


#*************************************************************************
# Creates a URL from the accession code and the global URL template
#
# 20.12.13 Original   By: ACRM
# 05.02.14 Takes $template as a parameter
sub CreateURL
{
    my($template, $ac, $type) = @_;
    $ac = "\U$ac";
    my $url = sprintf($template, $ac, $type);
    return($url);
}

#*************************************************************************
# Grabs a file using the LWP package
# Returns two values: success (TRUE/FALSE) and the data (content if all 
# was OK, otherwise the error message)
#
# 28.02.13 Original   By: ACRM
sub GetFile
{
    my ($url) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("grabpdb/0.1 ");
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    # Check the outcome of the response
    if ($res->is_success) 
    {
        return(1, $res->content);
    }

    return(0, $res->status_line);
}


#*************************************************************************
# Prints a usage message and exits
#
# 20.12.13 Original   By: ACRM
sub UsageDie
{
    my $autoname = sprintf($::OutTemplate, "XXXX", "type");
    print <<__EOF;

grabsprot V1.1 (c) 2013-2014, Dr. Andrew C.R. Martin, UCL

Usage: grabsprot [-f][-d][-v][-debug] accode [filename|-|stdout]
       -f             Grab FASTA format rather than full data file
       -d             Grab DNA data from EMBL-ENA
       -v             Verbose
       -debug         Debug mode (prints more information)
       accode         Accession (or identifier) code to grab 
                      (upper or lower case)
       filename       Output file to write (default to $autoname)
       - (or stdout)  Output to standard output

Grabs a UniProt file from the UniProt web site and writes it to a local file 
or to standard output. If the -d option is given, then the program 
initially grabs the UniProt entry, looks up the cross-reference to EMBL-ENA
and grabs the first appropriate (spliced) DNA for the sequence.

__EOF

    exit 0;
}
