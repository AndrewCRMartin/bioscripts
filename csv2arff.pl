#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    csv2arff
#   File:       csv2arff.pl
#   
#   Version:    V1.7
#   Date:       12.04.21
#   Function:   Convert CSV file to ARFF format
#   
#   Copyright:  (c) Prof. Andrew C. R. Martin, UCL, 2012-2021
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
#   Converts a CSV file to ARFF format
#
#*************************************************************************
#
#   Revision History:
#   =================
#   V1.0   26.06.12  Original
#   V1.1   29.10.12  Added -write=file, -norm=file and -relax
#                    -write=file     saves the ranges used for normalization
#                                    with -norm in a file
#                    -norm=file      reads the ranges from the file instead
#                                    of working them out from the data
#                    -relax          allows normalized values outside 0...1
#                                    when the actual data are outside the
#                                    range specified in a file read with
#                                    -norm=file
#   V1.2   29.11.12  Added -id=field, -idfile=file, -iddiscard=file By: NSAN
#                    -id=field       name of field to be used as id
#                                    with -norm in a file
#                    -idfile=file    used with -id to save records with IDs in
#                                    another ARFF file
#                    -iddiscard=file used with -id to save discarded IDs
#   V1.3   19.11.13  Added -minus and reads DOS files properly
#   V1.3.1 04.02.14  Improved usage message
#   V1.4   05.10.15  Added -skip to skip records with missing valued
#                    - the default is now to substitute a ? for missing 
#                    values
#   V1.5   15.10.19  Added -over to allow oversampling
#   V1.6   16.10.19  Fixed problem with generating headers with -skip
#                    Fixed output on oversampling
#   V1.7   12.04.21  Input file reader removes return characters for
#                    reading Windows files
#
#*************************************************************************
use strict;

my $input = "";
# Check for -h - help request
UsageDie() if(defined($::h));

# Check for user-specified dataset title
$::title = "CSV_data" if(!defined($::title));


# If we have -inputs=a,b,c on the command line, get inputs from there
# otherwise get the filename that lists the inputs and obtain from there
if(defined($::inputs))
{
    @::inputFields = split(/,/, $::inputs);
}
else
{
    $input  = shift(@ARGV);
    @::inputFields = ReadInputFields($input);
}

# 09.01.13 Added error checks  By: ACRM
if(!defined($::id) && (defined($::idfile) || defined($::iddiscard)))
{
    print STDERR "Error (csv2arff): You must specify -id to use -idfile or -iddiscard\n";
    exit 1;
}
if(!defined($::limit) && (defined($::discard) || defined($::iddiscard)))
{
    print STDERR "Error (csv2arff): You must specify -limit to use -discard or -iddiscard\n";
    exit 1;
}
# 15.10.19 Added error check   By: ACRM
if(!defined($::limit) && (defined($::over)))
{
    print STDERR "Error (csv2arff): You must specify -limit to use -over\n";
    exit 1;
}

# 29.11.12 If we have -id and -idfile, then open the idfile file to By: NSAN
if(defined($::id) && defined($::idfile))
{
    if(!open(IDFILE, ">$::idfile"))
    {
        print STDERR "Error (csv2arff): Unable to open discard file for writing: $::idfile\n";
        exit 1;
    }
}

# 29.11.12 -id and -iddiscard added
# If we have -limit and -discard (-id and -idfile), 
# then open the discard file to store records rejected by -limit By: NSAN
if(defined($::limit) && defined($::discard))
{
    if(!open(DISCARDFILE, ">$::discard"))
    {
        print STDERR "Error (csv2arff): Unable to open discard file for writing: $::discard\n";
        exit 1;
    }
    if(defined($::id) && defined($::iddiscard))
    {
        if(!open(IDDISCARDFILE, ">$::iddiscard"))
        {
            print STDERR "Error (csv2arff): Unable to open ID discard file for writing: $::iddiscard\n";
            exit 1;
        }
    }
}

# Set up the output normalized range (for use with -norm)
my $outMinVal = 0;
my $outMaxVal = 1;
if(defined($::minus))
{
    $outMinVal = -1;
    $outMaxVal = 1;
}

# Get the output field from the command line
my $output = shift(@ARGV);

# Read the data
my ($ndata, %data) = ReadCSV();

# Identify redundant attributes (if -auto defined)
%::redundantFields = FindRedundantFields($ndata, %data);
# Normalize data (if -norm defined)
NormalizeData($ndata, $output, $outMinVal, $outMaxVal, %data);
# Limit the maximum count of any output class (if -limit defined)
@::rejectRecords = LimitData($ndata, $output, $::limit, %data);
# If -limit and -over
@::overSample = OversampleData($ndata, $output, $::limit, %data, $::over);
# Create array of allowed output classes changing * to _other_
@::allowedClasses = (defined($::class))?split(/\,/,$::class):();
foreach my $ac (@::allowedClasses){$ac = "_other_" if ($ac eq "*");}

# Write the results
WriteARFF($output, $ndata, $::title, %data);
WriteOverSampledARFF($output, $ndata, $::title, %data);

# 29.11.12 Close the idfile file if we have one By: NSAN
if(defined($::id) && defined($::idfile))
{
    close IDFILE;
}

# 29.11.12 Close the discard file if we have one  By: NSAN
if(defined($::limit) && defined($::discard))
{
    close DISCARDFILE;

    if(defined($::id) && defined($::iddiscard))
    {
        close IDDISCARDFILE;
    }
}

#*************************************************************************
# 29.10.12 Original   By: ACRM
sub ReadNormRanges
{
    my ($file) = @_;
    my %ranges = ();
    
    if(open(RANGEFILE, $file))
    {
        while(<RANGEFILE>)
        {
            chomp;
            my ($attribute, $minVal, $maxVal) = split;
            $ranges{$attribute}[0] = $minVal;
            $ranges{$attribute}[1] = $maxVal;
        }
        close RANGEFILE;
    }
    else
    {
        print STDERR "Error (csv2arff): Unable to read normalization file: '$file'\n";
        exit 1;
    }

    return(%ranges);
}

#*************************************************************************
# 26.06.12 Original   By: ACRM
# 29.10.12 Added code to read ranges from a file
# 19.11.13 Added code to allow output range to be specified
sub NormalizeData
{
    my($ndata, $output, $outMinVal, $outMaxVal, %data) = @_;
    my %ranges = ();
    
    if(defined($::norm))
    {
        print STDERR "Normalizing data..." if(defined($::v));
        
        # If -norm has been called with a filename, read the ranges
        # from this file
        if($::norm ne 1)
        {
            # Check that -write hasn't also been specified
            if(defined($::write))
            {
                UsageDie();
            }
            
            %ranges = ReadNormRanges($::norm);
        }
        else # We are calculating ranges, see if we need to write them
        {
            if(defined($::write))
            {
                if(!open(RANGEFILE, ">$::write"))
                {
                    print STDERR "Error (csv2arff): Can't open file specified with -write for writing: $::write\n";
                    exit 1;
                }
            }
        }

        # Step through the attribues checking if they are ones that we
        # say are of interest
        foreach my $attrib (keys %data)
        {
            if(inArray($attrib, @::inputFields))
            {
                my ($minVal, $maxVal);
                my $nan;
                
                if($::norm == 1)
                {
                    # Now go through all the values finding a minimum and max
                    # If we find something that isn't a number then jump out
                    $minVal = $data{$attrib}[0];
                    $maxVal = $data{$attrib}[0];
                    $nan    = 0;
                    for(my $i=0; $i<$ndata; $i++)
                    {              
                        my $value = $data{$attrib}[$i];
                        if(!IsValidNumber($value) && ($value ne ""))
                        {
                            $nan = 1;
                            last;
                        }
                        
                        if($value < $minVal)
                        {
                            $minVal = $value;
                        }
                        elsif($value > $maxVal)
                        {
                            $maxVal = $value;
                        }
                    }
                    if(defined($::write))
                    {
                        print RANGEFILE "$attrib $minVal $maxVal\n";
                    }
                }
                else
                {
                    # Get the min and max values as defined in a file

                    # If either min or max is invalid or the range is 
                    # zero, then set the not-a-number flag
                    if(defined($ranges{$attrib}[0]))
                    {
                        $minVal = $ranges{$attrib}[0];
                        $maxVal = $ranges{$attrib}[1];
                        if((!IsValidNumber($minVal) && ($minVal ne "")) ||
                           (!IsValidNumber($maxVal) && ($maxVal ne "")) ||
                           ($minVal == $maxVal))
                        {
                            $nan = 1;
                        }
                    }
                    else
                    {
                        $nan = 1;
                    }
                }


                # If we only had valid numbers, then normalize to range 0-1
                if(!$nan)
                {
                    my $range    = $maxVal - $minVal;
                    my $outRange = $outMaxVal - $outMinVal;

                    for(my $i=0; $i<$ndata; $i++)
                    {              
                        my $value = $data{$attrib}[$i];
                        if($value ne "")
                        {
                            if($range > 0)
                            {
                                # Out = outMin + (outRange * ((in - inMin)/inRange))
                                my $newval = $outMinVal + ($outRange * ($value - $minVal) / $range);
                                # When ranges have been read from a file,
                                # the normalized number might be outside
                                # the 0...1 range. Unless -relax is 
                                # specified, this forces the range to 
                                # be 0...1
                                if(!defined($::relax))
                                {
                                    if($newval > $outMaxVal)
                                    {
                                        $newval = $outMaxVal;
                                    }
                                    elsif($newval < $outMinVal)
                                    {
                                        $newval = $outMinVal;
                                    }
                                }
                                $data{$attrib}[$i] = $newval;
                            }
                        }
                    }
                }
            }
        }
        if(defined($::write))
        {
            close RANGEFILE;
        }
        print STDERR "done\n" if(defined($::v));
    }
}

#*************************************************************************
sub LimitData
{
    my($ndata, $output, $limit, %data) = @_;
    my @reject = ();
    
    if(defined($::limit))
    {
        print STDERR "Limiting dataset size..." if(defined($::v));
        my %classCounts = ();
        # Count how many of each output class there is
        for(my $i=0; $i<$ndata; $i++)
        {
            my $class = $data{$output}[$i];
            if(defined($classCounts{$class}))
            {
                $classCounts{$class}++;
            }
            else
            {
                $classCounts{$class}=1;
            }
        }

        # Start off assuming we reject everything
        for (my $i=0; $i<$ndata; $i++)
        {
            $reject[$i] = 1;
        }

        # Step through the data, randomly marking for keeping if this
        # class has too many items, or definitely for keeping if there
        # aren't enough.
        my %kept = ();
        foreach my $class (keys %classCounts)
        {
            # Initialize counter of how many examples have been kept
            if(!defined($kept{$class}))
            {
                $kept{$class} = 0;
            }
            # While we haven't got enough examples in this class
            while(($kept{$class} < $::limit) &&
                  ($kept{$class} <= $classCounts{$class}))
            {
                # Run though the data looking for examples of this class
                for(my $i=0; $i<$ndata; $i++)
                {
                    # See if it's the class of interest
                    my $thisClass = $data{$output}[$i];
                    if($thisClass eq $class)
                    {
                        # If we have too many of this class...
                        my $count = $classCounts{$thisClass};
                        if($count > $::limit)
                        {
                            # If it's currently marked for rejection
                            if($reject[$i])
                            {
                                # Based on random number we can choose to keep it
                                my $rnum = Random($count);
                                if($rnum < $limit)
                                {
                                    $reject[$i] = 0;
                                    # Update the number kept - if it's now enough
                                    # jump out of the loop
                                    $kept{$class}++;
                                    if($kept{$class} >= $::limit)
                                    {
                                        last;
                                    }
                                }
                            }
                        }
                        else        # Not enough of this class so keep automatically
                        {
                            $reject[$i] = 0;
                            $kept{$class}++;
                        }
                    }
                }
            }
        }
        print STDERR "done\n" if(defined($::v));
    }
    return(@reject);
}

#*************************************************************************
sub Random
{
    my($limit) = @_;
    return(int(rand($limit)));
}


#*************************************************************************
sub FindRedundantFields
{
    my($ndata, %data) = @_;

    my %redundantFields = ();
    my $nRedundant = 0;

    if(defined($::auto))
    {
        print STDERR "Finding redundant attributes..." if(defined($::v));

        # Step through the attribues checking if they are ones that we
        # say are of interest
        foreach my $attrib (keys %data)
        {
            if(inArray($attrib, @::inputFields))
            {
                # Now check if it's redundant - i.e. all values are the
                # same
                # Store them in a hash
                my %values = ();
                for(my $i=0; $i<$ndata; $i++)
                {
                    $values{$data{$attrib}[$i]} = 1;
                }
                # If the hash has only one key then the column is redundant
                if(int(keys %values) == 1)
                {
                    $redundantFields{$attrib} = 1;
                    $nRedundant++;
                }
            }
        }

        print STDERR "done\n" if(defined($::v));

        if($nRedundant)
        {
            if($nRedundant > 1)
            {
                print STDERR "The following redundant attributes were discarded:\n";
            }
            else
            {
                print STDERR "The following redundant attribute was discarded:\n";
            }
            foreach my $attrib (keys %redundantFields)
            {
                print STDERR "   $attrib\n";
            }
        }
    }

    return(%redundantFields);
}

#*************************************************************************
# 29.11.12 Call to PrintLineId() added  By: NSAN
sub WriteARFF
{
    my ($output, $nData, $title, %data) = @_;

    my @attributes = ();
    my @isBoolean  = ();

    if(!inArray($output, (keys %data)))
    {
        print STDERR "Error (csv2arff): Specified output field ($output) does not exist\n";
        exit 1;
    }

    print STDERR "Writing ARFF file..." if(defined($::v));
    # First write the ARFF header
    $title =~ s/\s/\_/g;
    PrintLine(3, "\@relation $title\n\n");

    # Print valid input attributes
    foreach my $key (sort keys %data)
    {
        if(inArray($key, @::inputFields) && !defined($::redundantFields{$key}))
        {
            # Determine input attribute type
            my ($attribType, $boolean) = FindAttribType(0, @{$data{$key}});
            PrintLine(3, "\@attribute $key $attribType\n");
            push @attributes, $key;
            push @isBoolean,  $boolean;
        }
    }

    # Determine output attribute type
    my ($attribType, $boolean) = FindAttribType(1, @{$data{$output}});
    PrintLine(3, "\@attribute $output $attribType\n\n");
    my $outIsBoolean = $boolean;

    # Now write the actual data
    PrintLine(3, "\@data\n");
    for(my $i=0; $i<$nData; $i++)
    {
        my $outputString = "";
        my $valid  = 1;

        # Input attributes
        my $attribCount = 0;
        foreach my $attrib (@attributes)
        {
            my $datum = $data{$attrib}[$i];
            
            if(($datum eq "")||($datum eq '?')) # Check the line is complete
            {
                if(defined($::skip))
                {
                    $valid = 0;
                    last;
                }
                else
                {
                    $datum = '?';
                }
            }
            else
            {   # Convert to Boolean if needed
                if(!defined($::ni) && $isBoolean[$attribCount])
                {
                    $datum = (($datum == 1)?"TRUE":"FALSE");
                }
            }

            # Append to the output string
            $outputString .= $datum . ",";
            $attribCount++;
        }

        # Output value
        my $datum = $data{$output}[$i];
        if(int(@::allowedClasses))
        {
            if(!inArray($datum, @::allowedClasses))
            {
                if(inArray("_other_", @::allowedClasses))
                {
                    $datum = "_other_";
                }
                else
                {
                    $valid = 0;
                }
            }
        }

        # If this is an allowed output attribute (or we weren't checking)
        if($valid)
        {
            if($datum eq "")
            {
                $valid = 0;
            }
            else
            {
                # Convert to Boolean if needed
                if(!defined($::no) && $outIsBoolean)
                {
                    $datum = (($datum == 1)?"TRUE":"FALSE");
                }
                # Append to the output string
                $outputString .= $datum . "\n";
            }
        }
 
        # Print results if valid
        if($valid)
        {
            # If we are not limiting the output data or this is a record that
            # has not been rejected
            # 29.11.12  Added calls to PrintLineId() to print IDs before to
            # a separate file with each entry $i as $data{$::id}[$i]  By: NSAN
            if(defined($::limit))
            {
                if(!$::rejectRecords[$i])
                {
                    PrintLine(1, $outputString); 
                    PrintLineId(1,  $data{$::id}[$i].",".$outputString);
                }
                else
                {
                    PrintLine(2, $outputString);
                    PrintLineId(2, $data{$::id}[$i].",".$outputString);
                }
            }
            else
            {
                PrintLine(1, $outputString);
                PrintLineId(1,  $data{$::id}[$i].",".$outputString);
            }
        }

    }
    print STDERR "done\n" if(defined($::v));

}

#*************************************************************************
sub PrintLine
{
    my($destination, $content) = @_;
    if($destination&1)
    {
        print $content;
    }
    if(defined($::limit) && defined($::discard) && ($destination&2))
    {
        print DISCARDFILE $content;
    }
}

#*************************************************************************
# 29.11.12 Print IDs before each entry  By: NSAN
# 09.01.13 Corrections to logic in checking whether to print  By: ACRM
sub PrintLineId
{
    my($destination, $content) = @_;

    if(defined($::id))
    {
        if(($destination&1) && defined($::idfile))
        {
            print IDFILE $content;
        }
        if(defined($::limit) && defined($::iddiscard) && ($destination&2))
        {
            print IDDISCARDFILE $content;
        }
    }
}

#*************************************************************************
sub IsValidNumber
{
    my($value) = @_;

    if($value =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
    {
        return(1);
    }
    return(0);
}

#*************************************************************************
sub FindAttribType
{
    my ($isOutputAttrib, @data) = @_;
    my %values;

    # Store the observed values in a hash
    foreach my $datum (@data)
    {
        if((($datum ne '') && ($datum ne '?')) ||
           !defined($::skip))
        {
            $values{$datum} = 1;
        }
    }

    # See if any of the observed values is non-numeric
    my $numeric = 1;
    foreach my $value (keys %values)
    {
        # Test if it's a valid number
        if(!IsValidNumber($value) && ($value ne ""))
        {
            $numeric = 0;
            last;
        }
    }

    # If there is a non-numeric value then build the list of strings
    if(!$numeric)
    {
        my $retString = "";
        # If it's the output and we have defined some allowed classes
        if($isOutputAttrib && int(@::allowedClasses))
        {
            foreach my $value (@::allowedClasses)
            {
                if($retString eq "")
                {                
                    $retString = "{";
                }
                else
                {
                    $retString .= ",";
                }
                $retString .= $value;
            }
            $retString .= "}";
        }
        else
        {
            foreach my $value (sort keys %values)
            {
                if($retString eq "")
                {                
                    $retString = "{";
                }
                else
                {
                    $retString .= ",";
                }
                $retString .= $value;
            }
            $retString .= "}";
        }

        # If it's boolean but only TRUE or FALSE is seen, change to both
        if(($retString eq "{TRUE}") || ($retString eq "{FALSE}"))
        {
            $retString = "{TRUE,FALSE}";
        }
        if(($retString eq "{true}") || ($retString eq "{false}"))
        {
            $retString = "{true,false}";
        }

        # If there is only one value, add a dummy one
        if(!$retString =~ /\,/)
        {
            $retString =~ s/\}/\,_dummy_\}/;
        }

        return($retString, 0);
    }
    else # It's numeric, but if the only values are 1 and 0 (or 1 and -1) then it's boolean
    {
        my @valArray = (keys %values);
        if(int(@valArray) == 2)
        {
            if(((($valArray[0] == 0) || ($valArray[0] == (-1))) && ($valArray[1] == 1)) ||
               ((($valArray[1] == 0) || ($valArray[1] == (-1))) && ($valArray[0] == 1)))
            {
                # If it's the output and we haven't defined -no
                # or it's an input and we haven't defined -ni
                if(($isOutputAttrib  && !defined($::no)) ||
                   (!$isOutputAttrib && !defined($::ni)))
                {
                    return("{TRUE,FALSE}", 1);
                }
            }
        }
        elsif(int(@valArray) == 1)
        {
            if(($valArray[0] == 0) || ($valArray[0] == 1))
            {
                # If it's the output and we haven't defined -no
                # or it's an input and we haven't defined -ni
                if(($isOutputAttrib  && !defined($::no)) ||
                   (!$isOutputAttrib && !defined($::ni)))
                {
                    return("{TRUE,FALSE}", 1);
                }
            }
        }
    }

    return("numeric", 0);
}


#*************************************************************************
sub inArray
{
    my($element, @TheArray) = @_;
    if (grep {$_ eq $element} @TheArray) 
    {
        return(1);
    }
    return(0);
}

#*************************************************************************
sub ReadCSV
{
    print STDERR "Reading data..." if(defined($::v));
    $_ = <>;
    chomp;
    s/\r//g;                    # 19.11.13 Deal with DOS files 
    my @fieldNames = split(/\s*\,\s*/);
    my $nFields = int(@fieldNames);
    
    # Remove whitespace from field names
    foreach my $fieldName (@fieldNames)
    {
        $fieldName =~ s/\s/\_/g;
    }

    my $count = 0;
    while(<>)
    {
        chomp;
        s/^\s+//;
        s/\r//;                 # 19.11.13 Deal with DOS files 
        if(length)
        {
            my @fields = split(/\s*\,\s*/);
            if(int(@fields) != $nFields)
            {
                print STDERR "Row discarded as it contained the wrong number of fields:\n   $_\n";
            }
            else
            {
                for(my $fieldNum=0; $fieldNum<int(@fields); $fieldNum++)
                {
                    $data{$fieldNames[$fieldNum]}[$count] = $fields[$fieldNum];
                }
                $count++;
            }
        }
    }
    print STDERR "done\n" if(defined($::v));
    return($count, %data);
}

#*************************************************************************
# 12.04.21 Remove return characters for Windows files
sub ReadInputFields
{
    my($input) = @_;
    my @fields = ();

    if(open(FILE, $input))
    {
        while(<FILE>)
        {
            chomp;
            s/^\s+//;
            s/\r//;
            if(length)
            {
                push @fields, $_;
            }
        }
        close FILE;
    }
    else
    {
        print STDERR "Can't open file with list of input fields - file not found: $input\n";
        exit 1;
    }
    return(@fields);
}

#*************************************************************************
sub OversampleData
{
    my($ndata, $output, $limit, %data, $over) = @_;
    my @overSample = ();

    if(defined($::limit) && defined($::over))
    {
        my %classCounts = ();
        # Count how many of each output class there is
        for(my $i=0; $i<$ndata; $i++)
        {
            my $class = $data{$output}[$i];
            if(defined($classCounts{$class}))
            {
                $classCounts{$class}++;
            }
            else
            {
                $classCounts{$class}=1;
            }
        }

        # Start off assuming we aren't using anything for oversampling
        for (my $i=0; $i<$ndata; $i++)
        {
            $overSample[$i] = 0;
        }

        # Step through each class
        foreach my $class (keys %classCounts)
        {
            my $kept       = $classCounts{$class};
            my $count      = $classCounts{$class};

            my $thisLimit  = $limit;
            $thisLimit     = 2*$count if($limit > 2*$count);

            my $resampling = ($kept < $thisLimit)?1:0;
        
            print STDERR "Oversampling dataset $class..." if(defined($::v) && $resampling);
        
            # While we don't have enough of this class
            while($kept < $thisLimit)
            {
                # Run though the data looking for examples of this class
                for(my $i=0; $i<$ndata; $i++)
                {
                    # See if it's the class of interest
                    my $thisClass = $data{$output}[$i];
                    if($thisClass eq $class)
                    {
                        # If it's not yet chosen for over-sampling
                        if(!$overSample[$i])
                        {
                            # Based on random number we can choose to keep it
#                            my $rnum = Random($count);
                            my $rnum = Random($thisLimit);
                            if($rnum < ($thisLimit-$count))
                            {
                                $overSample[$i] = 1;
                                # Update the number kept - if it's now enough
                                # jump out of the loop
                                $kept++;
                                if($kept >= $thisLimit)
                                {
                                    last;
                                }
                            }
                        }
                    }
                }
            }
            
            print STDERR "done\n" if(defined($::v) && $resampling);
        }
    }
    
    return(@overSample);
}

#*************************************************************************
# 15.10.19 Original By: ACRM
sub WriteOverSampledARFF
{
    my ($output, $nData, $title, %data) = @_;

    my @attributes = ();
    my @isBoolean  = ();

    if(defined($::limit) && defined($::over))
    {
        print STDERR "Writing oversampled data to ARFF file..." if(defined($::v));

        # Find valid input attributes
        foreach my $key (sort keys %data)
        {
            if(inArray($key, @::inputFields) && !defined($::redundantFields{$key}))
            {
                my ($attribType, $boolean) = FindAttribType(0, @{$data{$key}});
                push @attributes, $key;
                push @isBoolean,  $boolean;
            }
        }
        
        # Determine output attribute type
        my ($attribType, $boolean) = FindAttribType(1, @{$data{$output}});
        my $outIsBoolean = $boolean;

        for(my $i=0; $i<$nData; $i++)
        {
            if($::overSample[$i])
            {
                my $outputString = "";
                my $valid  = 1;
                
                # Input attributes
                my $attribCount = 0;
                foreach my $attrib (@attributes)
                {
                    my $datum = $data{$attrib}[$i];
                    
                    if(($datum eq '')||($datum eq '?'))  # Check the line is complete
                    {
                        if(defined($::skip))
                        {
                            $valid = 0;
                            last;
                        }
                        else
                        {
                            # Don't allow missing values in over-sampled data
                            $valid = 0;
                            last;
                            # $datum = '?';
                        }
                    }
                    else
                    {   # Convert to Boolean if needed
                        if(!defined($::ni) && $isBoolean[$attribCount])
                        {
                            $datum = (($datum == 1)?"TRUE":"FALSE");
                        }
                    }
                    
                    # Append to the output string
                    $outputString .= $datum . ",";
                    $attribCount++;
                }
                
                # Output value
                my $datum = $data{$output}[$i];
                if(int(@::allowedClasses))
                {
                    if(!inArray($datum, @::allowedClasses))
                    {
                        if(inArray("_other_", @::allowedClasses))
                        {
                            $datum = "_other_";
                        }
                        else
                        {
                            $valid = 0;
                        }
                    }
                }
                
                # If this is an allowed output attribute (or we weren't checking)
                if($valid)
                {
                    if($datum eq "")
                    {
                        $valid = 0;
                    }
                    else
                    {
                        # Convert to Boolean if needed
                        if(!defined($::no) && $outIsBoolean)
                        {
                            $datum = (($datum == 1)?"TRUE":"FALSE");
                        }
                        # Append to the output string
                        $outputString .= $datum . "\n";
                    }
                }
                
                # Print results if valid
                if($valid)
                {
                    PrintLine(1, $outputString);
                    PrintLineId(1,  $data{$::id}[$i].",".$outputString);
                }
            }
        }
        print STDERR "done\n" if(defined($::v));
    }
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

csv2arff V1.7 (c) 2012-2021, UCL, Prof. Andrew C.R. Martin, Nouf S. Al-Numair

Usage: csv2arff [-ni][-no][-auto][-skip]
                [-norm[=file][-relax][-minus][-write=file]]
                [-title=title][-class=a,b,c] 
                [-id=a [-idfile=file]]
                [-id=a [-iddiscard=file]]
                [-limit=n [-over] [-discard=file] [-id=a [-idfile=file]]]
                [-limit=n [-over] [-discard=file] [-id=a [-iddiscard=file]]]
                (-inputs=a,b,c|inputs.dat) output [file.csv] > file.arff

REQUIRED PARAMETERS
       -inputs=a,b,c   - Comma-separated list of fields to be used as inputs
       --OR--
       inputs.dat      - file with list of fields to be used as inputs (one
                         per line)
       [NOTE - YOU MUST SUPPLY EITHER THE NAME OF THE FILE ON ITS OWN WITH
        NO -inputs FLAG, OR THE LIST OF FIELDS WITH THE -inputs= FLAG]

       output          - name of field to be used as output - i.e. the
                         output label (class) associated with each field

REDIRECTABLE PARAMETERS
       file.csv        - input CSV file(s) - reads from standard input if
                         not specified
       file.arff       - output ARFF file (standard output)

OPTIONS
   Data Format
       -ni             - do not convert binary inputs to nominal Boolean
       -no             - do not convert binary output to nominal Boolean
       -auto           - remove redundant input attributes
       -title=title    - specify a title for the data file
       -skip           - Skip records with missing values

   Normalization
       -norm[=file]    - normalize all numeric attributes to the range 0...1
                         If a file is specified, then data will be
                         normalized based on the ranges in that file rather
                         than the data being read. Normalized values outside
                         the 0...1 range will be set to 0 or 1 as appropriate
                         unless -relax is specified
       -relax          - when used with -norm=file, does not constrain the
                         values after normalization to be within 0...1
       -minus          - with -norm, normalize to -1...1 instead of 0...1
       -write=file     - when -norm is used (without a filename) write the 
                         ranges to a file that can then be read with -norm
                         in future runs. Combining with -norm=file (rather
                         then just with -norm) leads to an error and this
                         usage message being displayed.

   Record selection
       -limit=n        - randomly limit the number of records of any
                         output class to n
       -over           - used with -limit to allow over-sampling - if -limit
                         is greater than the number in a class, this class
                         will be resampled to create -limit entries. Note
                         that over-sampling will only ever resample each 
                         item once, so you cannot more than double a dataset
       -class=a,b,c    - specify allowed output classes (class * will match
                         unspecified classes). Classes that do not match
                         will be discarded.
       -discard=file   - used with -limit to place discarded records in
                         another ARFF file
   Labelling data
       -id=id          - used with -limit, -idfile and -discard to define
                         a unique field in the input that can be used as an
                         identifier for each record
       -idfile=file    - used with -id and -limit to specify a file into 
                         which the records retained in the .arff file are
                         written with the ID prepended onto each record
       -iddiscard=file - used with -id and -limit to specify a file into
                         which the records discarded in the .arff file are
                         written with the ID prepended onto each record

The input CSV file contains a first record with column names and following
records with data.

csv2arff extracts the columns named with -inputs= or in the inputs.dat
file as input attributes for the ARFF file and the named output column
as the output value. The program scans the columns to determine
whether they are numeric or nominal.  When a numeric column contains
only values 0 and 1 (or -1 and 1 - i.e. is a binary column), by
default it converts this to a Boolean nominal column (i.e. values
FALSE and TRUE respectively). This can be overridden for the inputs
with -ni and for the output with -no

The -auto option automatically removes redundant, non-informative input
attributes (i.e. those where all values are the same)

The -limit=n option is used when the data are highly skewed towards
certain classes. If specified, no class will contain more than n
values. Selection is made randomly so will be different on each
run. With -over, the value set by -limit=n may be larger than a
dataset size and will lead to resampling of the dataset. This will
never resample items more than once so you cannot more-than-double the
dataset size. Note that normalization (see -norm) is performed before
limiting the dataset, so multiple datasets generated with -limit will
have been normalized in the same way.

The -norm option normalizes all numeric fields to have the range 0...1
(or -1...1 if -minus is specified).  Some machine learning methods
perform better on normalized data. If a filename is specified with
-norm then the ranges used for normalization will be read from this
file instead of being calculated from the data.  Such a file can be
created by using -write=file with -norm (-norm being specified without
a filename so it calculates ranges from the data).  By default, when
the ranges are read from a file, if data are seen that would lead to a
value being outside the 0...1 (or -1...1) range then the normalized
values will be constrained to this range. this can be over-ridden with
-relax.

The -title option allows you to specify a title for the dataset. If the
title contains spaces, it must be enclosed in inverted commas. e.g.
-title=\"My test dataset\" - spaces will be replaced by underscores
in the ARFF file.

The -class option allows you to specify that the ARFF file will only
contain records with the specified output classes. This allows you to
try classifying subsets of the data. e.g. -class=\"HCM,DCM\" would only
retain records with output class HCM or DCM. The special class name '*'
will match any other class, placing these all into one class called _other_.
Note that -limit will not be applied to the _other_ class but to the 
individual classes that are merged.

The -discard option allows you to place all records discarded by -limit
into another file (for example as a test set).

If the CSV file contains an attribute which is unique for each record
and consequently can be used as an identifier for that record, then, 
if -limit is being used, then -id can be used to indicate that field. 
-idfile then specifies a file to which the retained records are written
prepended with the identifier and -iddiscard writes the discarded records
to a file prepended with the identifier.

__EOF

    exit 0;
}


