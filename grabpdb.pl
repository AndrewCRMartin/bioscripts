#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    grabpdb
#   File:       grabpdb.pl
#   
#   Version:    V1.1
#   Date:       01.07.13
#   Function:   Grab a PDB file from the PDB archive
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
#   V1.0   28.02.13  Original
#   V1.1   01.07.13  Added file-based compression
#
#*************************************************************************
use LWP::UserAgent;
use strict;

#*************************************************************************
$::URLtemplate = "ftp://ftp.ebi.ac.uk/pub/databases/pdb/data/structures/all/pdb/pdb%s.ent.gz";
$::OutTemplate = "pdb%s.ent";
$::LowerCase   = 1;
$::zcat        = "zcat";
$::gunzip      = "gunzip";
#*************************************************************************

UsageDie() if(defined($::h) || (scalar(@ARGV) == 0));

# Grab PDB code from command line
my $pdb = shift @ARGV;

# Create the URL and output filename
my $url = CreateURL($pdb);
my $file = CreateFilename($pdb, $::z, @ARGV);

# Grab the file
print "Grabbing: $url\n" if(defined($::v) || defined($::d));
my ($ok, $data) = GetFile($url);
if(!$ok)
{
    print STDERR "$data\n";
    print STDERR "URL: $url\n";
    exit 1;
}

# Uncompress unless -z specified
$data = Uncompress($data) unless(defined($::z));

if(!WriteData($data, $file))
{
    print STDERR "Can't write file: $file\n";
    exit 1;
}


#*************************************************************************
# Writes the data to the specified file. If the filename is '-' or 
# 'stdout', then it writes to standard output
#
# 28.02.13 Original   By: ACRM
sub WriteData
{
    my($data, $file) = @_;

    print STDERR "Writing data file: $file\n" if(defined($::d));

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
# otherwise builds a filename from the PDB code and the global template.
# If the $compressed flag is set then ".gz" is added to the filename
#
# 28.02.13 Original   By: ACRM
sub CreateFilename
{
    my($pdb, $compressed, @args) = @_;

    if(scalar(@args))
    {
        return($args[0]);
    }

    my $fileName = sprintf($::OutTemplate, $pdb);
    if($compressed)
    {
        $fileName .= ".gz";
    }

    print STDERR "Output filename: $fileName\n" if(defined($::d));

    return($fileName);
}


#*************************************************************************
# Creates a URL from the PDB code and the global URL template
#
# 28.02.13 Original   By: ACRM
sub CreateURL
{
    my($pdb) = @_;
    $pdb = "\L$pdb" if($::LowerCase);
    my $url = sprintf($::URLtemplate, $pdb);
    return($url);
}

#*************************************************************************
# Uncompresses a compressed datafile using the command specified in the
# global $::gunzip variable. Input is the compressed data and output is the
# uncompressed data. This version makes use of a temporary file since
# pipes seem unreliable with larger files.
#
# 01.07.13 Original   By: ACRM
sub Uncompress
{
    my($inData) = @_;
    my $outData = "";
    my $tfile  = "/tmp/grabpdb_$$" . time;
    my $tfileZ = $tfile . ".gz";

    print STDERR "Starting decompression\n" if(defined($::d));

    if(open(my $fh, ">$tfileZ"))
    {
        print $fh $inData;
        close $fh;
        `cd /tmp; $::gunzip $tfileZ`;
        if(open(my $fh, "$tfile"))
        {
            my @fileContent = <$fh>;
            $outData = join('', @fileContent);
            printf STDERR "Decompressed data contains %d lines\n", scalar(@fileContent) if(defined($::d));
        }
        else
        {
            print STDERR "Can't open temporary file for reading ($tfile). Data not uncompressed\n";
            $outData = $inData
        }
    }
    else
    {
        print STDERR "Can't open temporary file for writing ($tfileZ). Data not uncompressed\n";
        $outData = $inData
    }

    unlink $tfileZ;
    unlink $tfile;

    return($outData);
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
# 28.02.13 Original   By: ACRM
sub UsageDie
{
    my $autoname = sprintf($::OutTemplate, "XXXX");
    print <<__EOF;

grabpdb V1.1 (c) Dr. Andrew C.R. Martin, UCL
Usage: grabpdb [-z][-v][-d] pdbcode [filename|-|stdout]
       -z             Keep the file compressed
       -v             Verbose
       -d             Debug mode (prints more information)
       pdbcode        PDB code to grab (upper or lower case)
       filename       Output file to write (default to $autoname)
       - (or stdout)  Output to standard output

Grabs a PDB file from an FTP site and writes it to a local file or to
standard output. By default, remote files are decompressed.

__EOF

    exit 0;
}
