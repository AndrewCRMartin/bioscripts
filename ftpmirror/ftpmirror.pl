#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    ftpmirror
#   File:       ftpmirror.pl
#   
#   Version:    V1.8
#   Date:       07.10.21
#   Function:   Mirror an FTP site dealing with compressing and 
#               uncompressing if needed
#   
#   Copyright:  (c) Prof. Andrew C. R. Martin 2010-2021
#   Author:     Prof. Andrew C. R. Martin
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
# ftpmirror [-debug] [-h] [-quiet] [-forcedelete] config_file
#
# Note debug can be set to -debug=2 of -debug=3 to get more debugging info
#
# Configuration file consists of
# Field 1: Source URL
# Field 2: Destination directory (may be also be a file) 
# Flags: recurse     - recurse into lower directories
#        decompress  - decompress remote compressed files
#        compress    - compress remote uncompressed files
#        file        - this is a single file not a directory
#        wget        - use wget for big directories
#        retry=n     - number of wget retries (Default is 1. A value of 0
#                      will keep trying indefintely)
#        noclean     - do not clean up files that have gone away on the
#                      remote machine
#        fast        - just checks if files have appeared/disappeared
#                      rather than checking the date-stamps on the files
#        forcedelete - normally won't delete anything if number of entries
#                      has reduced by >50% - this forces it to do so
#                      (can also be on the command line)
#
#*************************************************************************
#
#   Revision History:
#   =================
#
#   V1.0   24.08.10   Original   By: ACRM
#   V1.1   09.09.10   Fixed a bug in cleanup when fast mode is used
#   V1.2   04.11.10   Added regex matching
#   V1.3   28.03.14   Checks that something is found in the remote
#                     directory and doesn't do the cleanup if there
#                     wasn't anything (e.g. the URL failed)
#   V1.4   19.05.14   No no longer deletes files if >50% have gone. Added
#                     -forcedelete or FORCEDELETE option to change this
#                     behaviour
#   V1.5   05.11.14   Uses system installed Perl and uses TryUse() to
#                     issue a sensible error message if LWP::Simple
#                     isn't installed
#   V1.6   10.02.16   Fixed problems with using LWP::Simple
#                     Now deals with symbolic links in FTP directories
#                     with LWP::Simple
#   V1.7   28.06.21   Now only uses mirror() if the file exists already
#   V1.8   07.10.21   Now uses wget for everything if that option is
#                     given rather than just for the file list
#
#*************************************************************************
use strict;
if(!TryUse("LWP::Simple"))
{
    print STDERR "You must install the LWP package to use this script\n";
    exit 1;
}
else                            # 10.02.16
{
    use LWP::Simple;
}


#*************************************************************************
# Main code
#
# 19.08.10  Original   By: ACRM
# 24.08.10  Added $fast
# 04.11.10  Added $regex and $exclregex
# 19.05.14  Added $forcedelete
if(defined($::h))
{
    Usage();
    exit 0;
}

$|=1; # Turn on auto-flushing

# Read the config file
while(<>)
{
    chomp;
    s/^\s+//;                   # Remove leading spaces

    # If it's not a comment of blank line
    if(length && !/^\#/)
    {
        # Parse the line from the config file
        my($url, $destination, $recurse, $compress, $file, $wget, 
           $retry, $noclean, $fast, $regex, $exclregex, $fd) = 
               ParseConfigLine($_);

        my $forcedelete = ((defined($::forcedelete) || $fd)?1:0);

        if(defined($::debug))
        {
            # Print results of parsing
            print "URL:         $url\n";
            print "DESTINATION: $destination\n";
            print "RECURSE:     $recurse\n";
            print "COMPRESS:    $compress\n";
            print "FILEONLY:    $file\n";
            print "USE-WGET:    $wget\n";
            print "NUM-RETRIES: $retry\n";
            print "NOCLEAN:     $noclean\n";
            print "FAST:        $fast\n";
            print "REGEX:       $regex\n";
            print "EXCL:        $exclregex\n";
            print "FORCEDELETE: $forcedelete";
            if(defined($::forcedelete))
            {
                print " (from command line)\n";
            }
            else
            {
                print "\n";
            }
        }

        if(!$::quiet && $fast)
        {
            print "Warning: Using fast mode. Modified files will not ";
            print "be detected!\n";
        }

        # Now actually process the line
        HandleRequest($url, $destination, $recurse, $compress, $file, 
                      $wget, $retry, $noclean, $fast, $regex, $exclregex,
                      $forcedelete);
    }
}

#*************************************************************************
# Does the actual work of processing a mirror request
#
# 19.08.10  Original   By: ACRM
# 24.08.10  Added $fast
# 09.09.10  Added @fullfilelist as it was trying to delete all non-new
#           files in fast mode
# 04.11.10  Added $regex and $exclregex
# 19.05.14  Added $forcedelete parameter
# 10.02.16  Added parentheses on LWP::Simple get() call
#           Added handling of links
sub HandleRequest
{
    my($url, $destination, $recurse, $compress, $fileonly, $wget, 
       $retry, $noclean, $fast, $regex, $exclregex, $forcedelete) = @_;

    my($nfiles, $ndirs, $nlinks);

    print "Handling $url\n" if(!defined($::quiet));

    if($fileonly)               # It's a file
    {
        my $dirname  = GetDirectory($destination);
        my $filename = GetFilename($destination);
        if($filename eq "")
        {
            $filename = GetFilename($url);
            if($filename eq "")
            {
                die "No filename specified - both URL and DESTINATION are directories";
            }
        }
        CreateDirIfNeeded($dirname);
        MirrorCompressFile($url, $dirname, $filename, $compress, $wget, $retry);
    }
    else                        # It's a directory
    {
        my $remotedir;
        my (@files, @dirs, @linkNames, @linkTargets, @fullfilelist);

        CreateDirIfNeeded($destination);

        if($wget)
        {
            # Using wget, we grab the directory to a temporary file...
            my $tfile = "/tmp/ftpmirror_$$.lis";
            my $options = "--quiet";
            if(defined($::debug))
            {
                print "Getting file list using wget to $tfile\n";
                $options = "";
            }
            `wget $options --output-document=$tfile --tries=$retry --waitretry=60 $url`;
            # ...and extract list of files and directories it contains
            ($nfiles, $ndirs) = ParseWgetFile($tfile, \@files, \@dirs);
            unlink $tfile if($::debug < 4);

            if(defined($::debug))
            {
                print "Parsed $tfile\n";
                printf "%s $tfile\n", (defined($::debug) && ($::debug < 4))?"Removed":"Retained";
                print "Found $nfiles remote files and $ndirs remote directories\n";
            }

            # Make a copy of the full file list so that we know what 
            # files should be in the directory if we are using fast mode 
            # and trimming the list of files to be copied
            @fullfilelist = @files;

            # If $fast is set, then trim the filelist down to just those 
            # that aren't there already
            if($fast)
            {
                if(defined($::debug))
                {
                    print "Fast mode set - trimming file list\n";
                }
                @files = TrimFileList($destination, $compress, @files);
            }
        }
        else
        {
            # Just use the LWP::Simple method to grab the directory...
            # 10.02.16 Added parentheses
            $remotedir = get($url);
            # ...and extract list of files and directories it contains
            ($nfiles, $ndirs, $nlinks) = 
                ParseRemoteDir($remotedir, \@files, \@dirs, 
                               \@linkNames, \@linkTargets);

            # Make a copy of the full file list so that we know what 
            # files should be in the directory if we are using fast mode 
            # and trimming the list of files to be copied
            @fullfilelist = @files;
        }

        
        # Run through the files listed in the remote directory, 
        # grabbing them
        my $count = 0;
        foreach my $filename (@files)
        {
            my $fullurl = BuildName($url,$filename,0);

            if(($regex eq "") || ($filename =~ /$regex/)) # 04.11.10
            {
                # 04.11.10
                if(($exclregex eq "") || (!($fullurl =~ /$exclregex/))) 
                {
                    if(!defined($::quiet))
                    {
                        print "Getting $fullurl...";
                    }
                    # Grabs a file and handles compression as required
                    MirrorCompressFile($fullurl, $destination, 
                                       $filename, $compress, $wget, $retry);
                    if(($::debug > 1) && ($count++ > 10))
                    {
                        print "exited after 10 files\n";
                        last;
                    }
                    if(!defined($::quiet))
                    {
                        print "done\n";
                    }
                }
                else
                {
                    if($::verbose)
                    {
                        print "Skipped file which matches EXCL regex: $fullurl\n";
                    }
                }
            }
            else
            {
                if($::verbose)
                {
                    print "Skipped file which does not match REGEX: $fullurl\n";
                }
            }
        }

        # 10.02.16 Create any links
        for(my $linkcount=0; $linkcount<$nlinks; $linkcount++)
        {
            my $linkName   = $linkNames[$linkcount];
            my $linkTarget = $linkTargets[$linkcount];
            print STDERR "Creating symbolic link: $linkName -> $linkTarget\n" if(defined($::verbose));

            my $exe = "(cd $destination; rm -f $linkName)";
            `$exe`;
            $exe = "(cd $destination; ln -sf $linkTarget $linkName)";
            `$exe`;
        }

        # 28.03.14 Added check that the dir contains something
        if(($nfiles == 0) && ($ndirs == 0))
        {
            printf STDERR "No files or directories found in URL: $url\n";
            printf STDERR "   ...not performing cleanup\n";
        }
        else
        {
            # Clean up any local files that have gone away on the remote 
            # machine
            CleanDirectory($destination, \@fullfilelist, \@dirs, 
                           $compress, $noclean, $forcedelete);
        }

        # If recursion is switched on then recursively handle each of 
        # sub-directories contained in this directory
        if($recurse)
        {
            foreach my $dir (@dirs)
            {
                HandleRequest(BuildName($url,$dir,1), 
                              BuildName($destination,$dir,0), 
                              1, # Recurse
                              $compress, 
                              0, # Fileonly
                              $wget, $retry, $noclean, $fast, 
                              $regex, $exclregex, $forcedelete);
            }
        }
    }
}

#*************************************************************************
# Removes local files that have gone away on the remote machine. Note that
# if no files or directories are found on the remote machine then nothing
# is removed. This is for safety as it is most likely to result from a
# network failure.
#
# 19.08.10  Original   By: ACRM
# 24.08.10  $noclean passed in here so it can report files that should
#           have been removed
# 19.05.14  Added check on directory shrinking by 50% and $forcedelete 
#           parameter
sub CleanDirectory
{
    my($destination, $pFiles, $pDirs, $compress, 
       $noclean, $forcedelete) = @_;
    my(%fileHash, %dirHash);

    # For debugging print the 1st 10 entries from the lists of remote 
    # files and directories
    if($::debug > 2)
    {
        for(my $i=0; $i<10 && $i<@$pFiles; $i++)
        {
            print "RemoteFile: $$pFiles[$i]\n";
        }
        for(my $i=0; $i<10 && $i<@$pDirs; $i++)
        {
            print "RemoteDir:  $$pDirs[$i]\n";
        }
    }

    # If we have found *something* on the remote server
    if(@$pFiles || @$pDirs)
    {
        # 19.05.14 Check number of remote files and directories
        my $nRemoteFilesAndDirs = scalar(@$pFiles) + scalar(@$pDirs);

        # Create a hash of the file and directory lists for fast lookups
        foreach my $file (@$pFiles)
        {
            $fileHash{$file} = 1;
        }
        foreach my $dir (@$pDirs)
        {
            $dirHash{$dir} = 1;
        }
        
        # Get the local list of files/dirs and run through them seeing if 
        # they are listed in the hash of remote files/dirs
        opendir(DIR, $destination) || 
            die "Can't read directory: $destination";
        my @files = grep !/^\./, readdir(DIR);

        # 19.05.14 Check number of local files and directories
        my $nLocalFilesAndDirs = scalar(@files);

        # 19.05.14 If remote total is <50% of local total, something has
        # probably gone wrong, so exit unless FORCEDELETE has been set
        if(($nRemoteFilesAndDirs < ($nLocalFilesAndDirs / 2)) &&
           !$forcedelete)
        {
            print "Remote directory has shrunk be > 50%, not deleting files\n";
            print "   Use FORCEDELETE or -forcedelete option to override\n";
            return;
        }
            
        foreach my $file (@files)
        {
            my $filename = BuildName($destination, $file, 0);
            if( -d $filename )  # It's a directory so check the dir hash
            {
                if(!defined($dirHash{$file}))
                {
                    if($noclean)
                    {
                        if(!defined($::quiet))
                        {
                            print "Directory should be removed: $filename\n";
                        }
                    }
                    else
                    {
                        if(!defined($::quiet))
                        {
                            print "Removing directory: $filename\n";
                        }
                        `\rm -rf $filename`;
                    }
                }
            }
            else                # It's a file so check the file hash
            {
                # If we are using compression we have to change the file 
                # name
                if($compress == 1)
                {
                    # We have saved it compressed while original was not 
                    # so we remove the .gz extension from the filename 
                    # we have
                    $file =~ s/\.gz$//;
                }
                elsif($compress == (-1))
                {
                    # We have saved it uncompressed while original was 
                    # compressed so we add the .gz extension to the 
                    # filename we have
                    $file .= ".gz";
                }

                if(!defined($fileHash{$file}))
                {
                    if($noclean)
                    {
                        if(!defined($::quiet))
                        {
                            print "File should be removed: $filename\n";
                        }
                    }
                    else
                    {
                        if(!defined($::quiet))
                        {
                            print "Removing file: $filename\n";
                        }
                        unlink $filename;
                    }
                }
            }
        }
    }
}


#*************************************************************************
# Parse the file list grabbed using LWP::Simple and extract arrays of 
# files and directories
#
# 19.08.10  Original   By: ACRM
# 28.03.13  Returns count of files and directories
# 10.02.15  Added handling of links
sub ParseRemoteDir
{
    my($remotedir, $pFiles, $pDirs, $pLinkNames, $pLinkTargets) = @_;
    my @lines = split(/\n/, $remotedir);
    foreach my $line (@lines)
    {
        my @fields = split(/\s+/, $line);
        my $filename = $fields[$#fields];
        if($line =~ /^d/)
        {
            push @$pDirs, $filename;
        }
        elsif($line =~ /^l/)
        {
            push @$pLinkTargets, $filename;
            $filename = $fields[$#fields-2];
            push @$pLinkNames, $filename;
        }
        else
        {
            push @$pFiles, $filename;
        }
    }

    return(scalar(@$pFiles), scalar(@$pDirs), scalar(@$pLinkTargets));
}

#*************************************************************************
# Actually do the work of mirroring a file locally. Also handles 
# compression if required
#
# 19.08.10  Original   By: ACRM
# 07.10.21  Added wget and retry parameters. Now uses wget if that
#           option is specified
sub MirrorCompressFile
{
    my($url, $dirname, $filename, $compress, $wget, $retry) = @_;

    # Construct the complete filename
    my $fullfile = BuildName($dirname,$filename,0);

    # If we are compressing, add the .gz extension, or if uncompressing 
    # remove it. Construct a complete filename for this new file
    my $finalfilename = $filename;
    if($compress == 1)
    {
        if(!($finalfilename =~ /.gz$/))
        {
            $finalfilename .= ".gz";
        }
    }
    elsif($compress == (-1))
    {
        $finalfilename =~ s/.gz$//;
    }
    my $fullfinalfile = BuildName($dirname,$finalfilename,0);

    # If the file exists already check the date on it and grab the remote
    # version if it is newer.
    if(-e $fullfinalfile)
    {
        # Grab the meta-data header from the remote file to get the timestamp
        # [0] text/ftp-dir-listing | text/xml-external-parsed-entity
        # [1] size
        # [2] age
        my @headvals = head($url);
        my $remotetime = $headvals[2];
        # and for the local file
        my @stats = stat($fullfinalfile);
        my $mtime = $stats[9];

        # If remote is more recent, grab it and deal with compression
        if($remotetime > $mtime)
        {
            print "Updating $url\n" if(!defined($::quiet));
            if($wget)
            {
                `(cd $dirname; wget --quiet --timestamping --tries=$retry --waitretry=60 $url)`;
            }
            else
            {
                mirror($url, BuildName($dirname,$filename,0));
            }
            DoCompression($dirname, $filename, $compress);
        }
	else
	{
            print "Already got $url\n" if(!defined($::quiet));
	}
    }
    else                        # Doesn't exist, just grab it
    {
        if($wget)
        {
            `(cd $dirname; wget --quiet --timestamping --tries=$retry --waitretry=60 $url)`;
        }
        else
        {
            getstore($url, BuildName($dirname,$filename,0));
        }
        DoCompression($dirname, $filename, $compress);
    }
}

#*************************************************************************
# Handle compression/uncompression if necessary
#
# 19.08.10  Original   By: ACRM
sub DoCompression
{
    my($dirname, $filename, $compress) = @_;
    if($compress == 1)
    {
        `cd $dirname; gzip -f $filename`;
    }
    elsif($compress == (-1))
    {
        `cd $dirname; gunzip -f $filename`;
    }
}

#*************************************************************************
# Tests if a directory exists and, if not, create it
#
# 19.08.10  Original   By: ACRM
sub CreateDirIfNeeded
{
    my($path) = @_;
    $path =~ s/\/$//;           # Strip trailing slash
    if(! -e $path)
    {
        `mkdir -p $path`;
    }
}

#*************************************************************************
# Given a full path and filename, extract the filename
#
# 19.08.10  Original   By: ACRM
sub GetFilename
{
    my($path) = @_;
    # Strip from beginning to the final /
    $path =~ s/.*\///;
    return($path);
}

#*************************************************************************
# Given a full path and filename, extract the path (directory)
#
# 19.08.10  Original   By: ACRM
sub GetDirectory
{
    my($path) = @_;
    # Strip from the final / to the end
    $path =~ m/(.*)\//;
    $path = $1;
    return($path);
}

#*************************************************************************
# Given a path and a filename, construct a complete path/filename. 
# Optionally adds a slash on the end for directories
#
# 19.08.10  Original   By: ACRM
sub BuildName
{
    my($dir, $file, $addslash) = @_;
    $dir =~ s/\/+$//;
    if($addslash)
    {
        $file =~ s/\/+$//;
        $file .= "/";
    }
    return("$dir/$file");
}

#*************************************************************************
# Parse a line from the config file
#
# 19.08.10  Original   By: ACRM
# 24.08.10  Added FAST
# 04.11.10  Added REGEX and EXCL
# 19.05.14  Added FORCEDELETE
sub ParseConfigLine
{
    my($line)     = @_;

    my $recurse   = 0;
    my $compress  = 0;
    my $file      = 0;
    my $wget      = 0;
    my $retry     = 1;
    my $noclean   = 0;
    my $fast      = 0;
    my $regex     = "";
    my $exclregex = "";
    my $fd        = 0;

    # Extract fields from configuration line
    my @fields = split(/\s+/, $line);
    # Extract the input URL and output directory
    my $url = shift @fields;
    my $destination = shift @fields;

    # Check flags set in remaining fields
    foreach my $field (@fields)
    {
        if($field =~ /^RECURSE$/i)
        {
            if($file)
            {
                die "Config line can't specify RECURSE and FILE";
            }
            $recurse = 1;
        }
        elsif ($field =~ /^DECOMPRESS$/i)
        {
            if($compress != 0)
            {
                die "Config line can't specify COMPRESS and DECOMPRESS";
            }
            $compress = -1;
        }
        elsif ($field =~ /^COMPRESS$/i)
        {
            if($compress != 0)
            {
                die "Config line can't specify COMPRESS and DECOMPRESS";
            }
            $compress = 1;
        }
        elsif ($field =~ /^FILE$/i)
        {
            if($recurse)
            {
                die "Config line can't specify RECURSE and FILE";
            }
            $file = 1;
        }
        elsif ($field =~ /^WGET$/i)
        {
            $wget = 1;
        }
        elsif ($field =~ /RETRY=(.*)/i)
        {
            $retry = $1;
        }
        elsif ($field =~ /REGEX=(.*)/i)
        {
            $regex = $1;
        }
        elsif ($field =~ /EXCL=(.*)/i)
        {
            $exclregex = $1;
        }
        elsif ($field =~ /^NOCLEAN$/i)
        {
            $noclean = 1;
        }
        elsif ($field =~ /^FAST$/i)
        {
            $fast = 1;
        }
        elsif ($field =~ /^FORCEDELETE$/i)
        {
            $fd = 1;
        }
    }
    return($url, $destination, $recurse, $compress, $file, $wget, 
           $retry, $noclean, $fast, $regex, $exclregex, $fd);
}
    
#*************************************************************************
# Parse the file list grabbed using wget and extract arrays of files and 
# directories
#
# 19.08.10  Original   By: ACRM
# 28.03.14  Added check on count of files and directories and return these
sub ParseWgetFile
{
    my($filename, $pFiles, $pDirs) = @_;

    open(FILE, $filename) || die "Can't read $filename";
    while(<FILE>)
    {
        if(/<a href=".*?">(.*?)<\/a>/)
        {
            my $file = $1;
            if($file =~ /\/$/)  # Ends with a / so is a directory
            {
                $file =~ s/\/$//;
                push @$pDirs, $file;
            }
            else                # Otherwise it's a file
            {
                push @$pFiles, $file;
            }
        }
    }
    close FILE;

    return(scalar(@$pFiles), scalar(@$pDirs));
}

#*************************************************************************
# Used in FAST mode to remove files from the list to be downloaded
# that are already present. Note that this will not check for changes
# in the files, so should not be used for sites where the file content
# is dynamic
#
# 24.08.10  Original   By: ACRM
sub TrimFileList
{
    my($destination, $compress, @infiles) = @_;
    my @outfiles = ();
    my @localfiles = ();
    my %localfilelist;

    # Get the list of files present in the destination directory
    opendir(DIR, $destination) || 
        die "Can't read directory: $destination";
    @localfiles = grep !/^\./, readdir(DIR);
    closedir DIR;

    # Convert the list of local filenames into a hash for faster lookups
    # At the same time, we add/remove .gz if compressing
    if($compress == 1)
    {
        # We have saved it compressed while original was not 
        # so we remove the .gz extension from the filename 
        # we have locally
        foreach my $file (@localfiles)
        {
            $file =~ s/\.gz$//;
            $localfilelist{$file} = 1;
        }
    }
    elsif($compress == (-1))
    {
        # We have saved it uncompressed while original was 
        # compressed so we add the .gz extension to the 
        # filename we have locally
        foreach my $file (@localfiles)
        {
            $file .= ".gz";
            $localfilelist{$file} = 1;
        }
    }
    else
    {
        foreach my $file (@localfiles)
        {
            $localfilelist{$file} = 1;
        }
    }

    # Now run through the list of files we are dealing with and remove
    # them if they are already in our set of local files
    foreach my $file (@infiles)
    {
        if(!defined($localfilelist{$file}))
        {
            push @outfiles, $file;
        }
    }

    # Return the list of files that were on the remote server but not
    # stored locally
    return(@outfiles);
}

#*************************************************************************
# Tries to load a module
#
# 05.11.14  Original   By: ACRM
sub TryUse
{
    my($module) = @_;
    eval("use $module");
    if($@) 
    {
        #print "\$@ = $@\n";
        return(0);
    } 
    return(1);
}

#*************************************************************************
# Prints a usage message
#
# 19.08.10  Original   By: ACRM
# 09.09.10  V1.1
# 04.11.10  V1.2
# 28.03.14  V1.3
# 19.05.14  V1.4
# 05.11.14  V1.5
# 28.06.21  V1.7
# 07.10.21  V1.8
sub Usage
{
    print <<__EOF;

ftpmirror V1.8 (c) 2010-2021, Prof. Andrew C.R Martin

Usage: ftpmirror [-debug[=n]] [-quiet] [-verbose] [-forcedelete] config_file
       -debug       Turn on debugging information
                    Setting to -debug=2 restricts downloading a maximum 
                    of 10 files from each directory
                    Setting to -debug=3 turns on additional information
                    about remote files which controls cleaning of local files
                    that have gone away
                    Setting to -debug=4 also keeps the initial directory 
                    listing file
       -quiet       Prints no information about files being downloaded
                    or removed
       -verbose     Print the names of files skipped through not matching
                    REGEX or from matching EXCL
       -forcedelete Normally will not delete files if >50% have gone away.
                    This overrides that (as does FORCEDELETE config option)

The configuration file consists of two required fields followed by
optional flags which may be specified in any order:

Field 1: Source URL
Field 2: Destination directory (may be also be a file) 
Flags:   recurse     - recurse into lower directories
         decompress  - decompress remote compressed files
         compress    - compress remote uncompressed files
         file        - this is a single file not a directory
         wget        - use wget for big directories
         retry=n     - number of wget retries (Default is 1).
                       A value of 0 will keep trying indefintely.
         noclean     - do not clean up files that have gone away on the
                       remote machine
         forcedelete - Normally cleanup will not delete files if >50% 
                       have gone away (as this is usually some sort of
                       error). This overrides that behaviour (as does
                       the -forcedelete command line option). Use with
                       caution unless you know that the contents of the
                       remote directory is very dynamic!
         fast        - just checks if files have appeared/disappeared
                       rather than checking the date-stamps on the files
         regex=r     - only downloads files if the filename (excluding 
                       the path) matches the specified Perl regular 
                       expression
         excl=r      - skip files if the full URL filename path matches
                       the specified Perl regular expression. This
                       overrides matching with regex=

ftpmirror is a simple program for mirroring remote FTP sites, but
which allows remote uncompressed files to be compressed locally and
vice versa. By default it uses the Perl LWP package for retrieving
file lists etc, but these seem to have problems with very large
directories. In those cases, giving the 'wget' option will make the
script use wget to retireve these large directory lists.  The
configuration file can contain multiple lines to mirror multiple
sites.

__EOF
}
