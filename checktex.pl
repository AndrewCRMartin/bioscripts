#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    checktex
#   File:       checktex.pl
#   
#   Version:    V1.2
#   Date:       03.07.24
#   Function:   Check \ref and \label in LaTeX file
#   
#   Copyright:  (c) Univ. Reading and Prof. Andrew C.R. Martin, 2003,2024
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
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0  28.07.03 Original
#   V1.1  25.05.18 Escaped curly brackets in regexes
#   V1.2  03.07.24 Added -o and -sf options. Added use strict!
#
#*************************************************************************
use strict;

UsageDie() if defined($::h);

# First pass through the file to read labels
# ------------------------------------------
open(IN, $ARGV[0]) || die "Can't open file $ARGV[0]\n";
my $linenumber   = 1;
my $inSubFigure  = 0;
my %labels       = ();
my %sfLabels     = ();
my @labelarray   = ();
my @sfLabelarray = ();
while(<IN>)
{
    chomp;
    if(/\\begin\{subfigure\}/)
    {
        $inSubFigure = 1;
    }
    if(/\\end\{subfigure\}/)
    {
        $inSubFigure = 0;
    }
    
    while(/\\label\{(.*?)\}(.*)/) # If the string contains \label{...}
    {
        my $label = $1;
        my $rest  = $2;
        if(defined($labels{$label}))
        {
            print "Label used more than once: $label\n";
            printf "   Was first used on line %d; reused on line %d\n",
                $labels{$label}, $linenumber;
        }
        elsif(defined($sfLabels{$label}))
        {
            print "SubFigure label used more than once: $label\n";
            printf "   Was first used on line %d; reused on line %d\n",
                $sfLabels{$label}, $linenumber;
        }
        else
        {
            # Store the linenumber of the first (only) label occurrence
            # and also push the labels onto an array so that we have
            # them in order of occurrence
            if(defined($::sf) && $inSubFigure)
            {
                $sfLabels{$label} = $linenumber;
                push @sfLabelarray, $label;
            }
            else
            {
                $labels{$label} = $linenumber;
                push @labelarray, $label;
            }
        }
        $_ = $rest;
    }
    $linenumber++;
}
close IN;

# Second pass through the file to read references to labels
# Also reports references to undefined labels
# ---------------------------------------------------------
open(IN, $ARGV[0]) || die "Can't open file $ARGV[0]\n";
$linenumber = 1;
my %refs    = ();
while(<IN>)
{
    chomp;
    while(/\\ref\{(.*?)\}(.*)/) # If the string contains \ref{...}
    {
        my $label = $1;
        my $rest  = $2;
        if(!defined($labels{$label}) &&
           !defined($sfLabels{$label}))
        {
            print "Label was referenced on line $linenumber, but not defined: $label\n";
        }
        $refs{$label} = $linenumber if(!defined($refs{$label}));
        $_ = $rest;
    }
    $linenumber++;
}
close IN;

# Now see if any labels were not referenced
# -----------------------------------------
foreach my $label (keys %labels)
{
    if(!defined($refs{$label}))
    {
        printf "Label was defined on line %d, but not referenced: %s\n",
            $labels{$label}, $label;
    }
}

# Now see if any labels are referenced out of order
# -------------------------------------------------
# First create an array of the first reference to each label in the
# order in which the labels appeared
if(!defined($::o))
{
    my @refarray = ();
    foreach my $label (@labelarray)
    {
        if(defined($refs{$label}))
        {
            push @refarray, $refs{$label};
        }
        else
        {
            push @refarray, 0;
        }
    }
    # Now work through the array and check that every following item
    # is a larger number
    for(my $i=0; $i<$#refarray; $i++)
    {
        if($refarray[$i])
        {
            for(my $j=$i+1; $j<=$#refarray; $j++)
            {
                if($refarray[$j])
                {
                    if($refarray[$j] < $refarray[$i])
                    {
                        print  "Labels referenced out of order:\n";
                        printf "   Label %s appears before %s, but %s is referenced first\n",
                            $labelarray[$i], $labelarray[$j], $labelarray[$j];
                        printf "         %s appears on line %d and is first referenced on line %d\n",
                            $labelarray[$i], $labels{$labelarray[$i]}, $refarray[$i];  
                        printf "         %s appears on line %d and is first referenced on line %d\n",
                            $labelarray[$j], $labels{$labelarray[$j]}, $refarray[$j];
                    }
                }
            }
        }
    }
}

# Third pass checks balanced environments and curly brackets
# ----------------------------------------------------------
open(IN, $ARGV[0]) || die "Can't open file $ARGV[0]\n";

my $line   = 0;
my $bra    = 0;
my @envs   = ();
my @starts = ();
while(<IN>)
{
    $line++;
    $bra += CountChar($_, '{') if(/\{/);
    $bra -= CountChar($_, '}') if(/\}/);
    
    my @words = split(/\\/);
    foreach my $word (@words)
    {
        if($word =~ /begin\{(.*?)\}/)
        {
            my $env = $1;
            push @envs, $env;
            push @starts, $line;
        }
        if($word =~ /end\{(.*?)\}/)
        {
            my $env = $1;
            my $theenv = pop @envs;
            my $start  = pop @starts;
            if($env ne $theenv)
            {
                print "\\begin{$theenv} at line $start closed by \\end{$env} at line $line\n";
                goto EXIT;
            }
        }
    }
}
close IN;

EXIT:
if($bra > 0)
{
    printf "Curly brackets were unbalanced - there were $bra too many { brackets\n";
}
elsif($bra < 0)
{
    $bra *= (-1);
    printf "Curly brackets were unbalanced - there were $bra too many } brackets\n";
}

#*************************************************************************
sub CountChar
{
    my($line, $bra) = @_;
    my(@chars, $char, $count);
    @chars = split(//,$line);
    $count = 0;
    foreach $char (@chars)
    {
        $count++ if($char eq $bra);
    }
    return($count);
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

CheckTexRef V1.2
(c) The University of Reading / Prof. Andrew C.R. Martin, 2003-2024

Usage: checktexref [-o] file.tex
       -o  Do not check out of order references
       -sf Do not check unreferenced labels for sub-figures

Reads a LaTeX file and checks the use of \\ref and \\label commands.
Reports references to non-existent labels, labels without corresponding
references and out-of-sequence references (i.e. labels which are first
referenced in a different order from which they appear).

Note that the program reads only one LaTeX source file, so \\include
and \\input are not honoured. If you reference a label appearing in
another LaTeX file (or a label appears which is referenced in a
different file), then these will be reported as errors.

__EOF

    exit 0;
}
