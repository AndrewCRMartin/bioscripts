bioscripts
==========

See below for Installation instructions.

Bioinformatics
--------------

### fastamotifsearch.pl

A simple script to search for a motif in a FASTA file. Specified amino
acids or X for any amino acid are allowed.

### grabpdb.pl

Grab a PDB file by code from the internet

### grabsprot.pl

Grab a SwissProt or FASTA file from UniProtKB by specifying accession
or identifier. Can also download the DNA if there is a link to an ENA
entry.

### indexfasta / getfasta

Index a FASTA file such that an entry can be grabbed quickly

### indexswissprot / getswissprot

Index a SwissProt file such that an entry can be grabbed quickly

Weka
----

### arff2csv

Converts a Weka ARFF file to CSV format

### csv2arff

Converts a CSV file to Weka ARFF format with lots of options to select subsets of data, etc.

LaTeX
-----

### checktex

Checks the nesting of environments and curly brackets in a LaTeX
file. Also checks cross-references to tables, figures, etc and reports
those that haven't been reference or have been referenced out of
order.

### fclean

Intelligently lean up intermediate files when using LaTeX. 

ftpmirror
---------

A powerful script for mirroring FTP sites


INSTALLATION
============

Installation places the scripts in a specified directory and then
makes links in a binary directory with no extension (so you can just
type commands such as "grabpdb")

Edit the Makefile to modify 

    "dest" - where the scripts will live
    "bin"  - your binary directory (in your path)

The defaults are sensible

Type:

    make install

to install the scripts.

indexfasta
----------

The `Makefile` in the indexfasta directory also allows updating of the
indexes for `getfasta` / `getswissprot` - i.e. it will run
`indexfasta` and `indexswissprot`. You will need to edit the
`Makefile` to define the directories containing the SwissProt data and
where the index will live.

PREREQUISITES
-------------

You need to install the following Perl modules:

    LWP::UserAgent

Fedora/RedHat/CentOS installs this automatically. Otherwise (as root)
do: 

    perl -MCPAN -e shell
    install LWP::UserAgent

