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
#   V1.2  03.07.24 Added -o option
#
#*************************************************************************

UsageDie() if defined($h);

# First pass through the file to read labels
# ------------------------------------------
open(IN, $ARGV[0]) || die "Can't open file $ARGV[0]\n";
$linenumber = 1;
while(<IN>)
{
   chomp;
   while(/\\label\{(.*?)\}(.*)/) # If the string contains \label{...}
   {
      $label = $1;
      if(defined($labels{$label}))
      {
         print "Label used more than once: $label\n";
         printf "   Was first used on line %d; reused on line %d\n",
            $labels{$label}, $linenumber;
      }
      else
      {
         # Store the linenumber of the first (only) label occurrence
         # and also push the labels onto an array so that we have
         # them in order of occurrence
         $labels{$label} = $linenumber;
         push @labelarray, $label;
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
while(<IN>)
{
   chomp;
   while(/\\ref\{(.*?)\}(.*)/) # If the string contains \ref{...}
   {
      $label = $1;
      $rest  = $2;
      if(!defined($labels{$label}))
      {
         print "Label was referenced on line $linenumber, but not defined: $label\n";
      }
      $refs{$label} = $linenumber if(!defined($refs{$label}));
      $_ = $2;
   }
   $linenumber++;
}
close IN;

# Now see if any labels were not referenced
# -----------------------------------------
foreach $label (keys %labels)
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
    foreach $label (@labelarray)
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
    for($i=0; $i<$#refarray; $i++)
    {
        if($refarray[$i])
        {
            for($j=$i+1; $j<=$#refarray; $j++)
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

$line = 0;
while(<IN>)
{
    $line++;
    $bra += CountChar($_, '{') if(/\{/);
    $bra -= CountChar($_, '}') if(/\}/);

    @words = split(/\\/);
    foreach $word (@words)
    {
        if($word =~ /begin\{(.*?)\}/)
        {
            $env = $1;
            push @envs, $env;
            push @starts, $line;
        }
        if($word =~ /end\{(.*?)\}/)
        {
            $env = $1;
            $theenv = pop @envs;
            $start  = pop @starts;
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
       -o Do not check out of order references

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
