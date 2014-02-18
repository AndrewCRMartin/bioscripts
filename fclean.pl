#!/usr/bin/perl
#*************************************************************************
#
#   Program:    fclean
#   File:       fclean.perl
#   
#   Version:    V1.4
#   Date:       17.12.09
#   Function:   Clean out derivative files from running LaTeX
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 1997-2009
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
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
#   V1.0  24.09.97 Original
#   V1.1  06.02.98 Added fff files
#   V1.2  29.07.98 Added toc files and A response to delete all files
#   V1.3  24.11.03 Added ind,ilg,idx files
#   V1.4  17.12.09 Added spl files
#
#*************************************************************************

# Set the list of extensions to be removed here
@extlist = ("dvi","aux","log","bbl","blg","lot","lof","ttt","lll","ps","fff","toc","ind","ilg","idx","spl");

# Builds list of files to be considered from what was given on the 
# command line
$files = "";
while($fnm = shift(@ARGV))
{
    # If an extension is specified
    $temp = $fnm;
    $temp =~ s/\///g;
    if($temp =~ /[\s\S]+\.[\s\S]+/)
    {
        $files .= "$fnm ";
    }
    else # Ne extension, add .tex
    {
        $files .= $fnm . ".tex ";
    }
}

# Obtains the list of files actually present
if($files eq "")
{
    $dir = `ls *.tex`;
}
else
{
    $dir = `ls $files`;
}
@texfiles = split(/\n/,$dir);

$delete_all = 0;

# For each of these files
foreach $texfile (@texfiles)
{
    if($texfile =~ /\.tex$/) # Ignore anything which wasn't .tex
    {
        $stem = $texfile;
        $stem =~ s/\.tex//;
        
        # Substitute each of the extensions which we are wishing
        # to clean
        foreach $ext (@extlist)
        {
            $file = $stem . ".$ext";

            # If the file exists, see if we wish to remove it
            if( -e $file)
            {
                if($delete_all)
                {
                    unlink $file;
                }
                else
                {
                    print "fclean: remove `$file'? (y/n/a)[n] ";
                    $resp = <>;
                    $resp =~ tr/a-z/A-Z/;
                    $resp = substr($resp,0,1);

                    if($resp eq "A")
                    {
                        $delete_all = 1;
                        $resp = "Y";
                    }

                    if($resp eq "Y")
                    {
                        unlink $file;
                    }
                    elsif($resp eq "Q")
                    {
                        exit 1;
                    }
                }
            }
        }
    }
}

exit 0;


