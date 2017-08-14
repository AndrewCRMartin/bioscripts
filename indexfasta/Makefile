updir=/acrm/data/swissprot/full
idxdir=/acrm/data/tmp
indexfasta=./indexfasta.pl
indexsprot=./indexswissprot.pl

# Get rid of all built-in SUFFIX rules
.SUFFIXES : 

# Continue after all errors
.IGNORE :

# Source and destination directories
vpath %.dat    $(updir)
vpath %.fasta  $(updir)
vpath %.datidx $(idxdir)
vpath %.faaidx $(idxdir)

dstems1 := uniprot_sprot.dat   uniprot_trembl.dat
fstems1 := uniprot_sprot.fasta uniprot_trembl.fasta

# Strip the extension
dstems   := $(basename $(dstems1))
fstems   := $(basename $(fstems1))

# Add the .idx extension to create list of targets
dtargets := $(addsuffix .datidx, $(dstems))
ftargets := $(addsuffix .faaidx, $(fstems))

# Phony rule to build all the targets
all : $(dtargets) $(ftargets)

%.datidx : %.dat
	$(indexsprot) $< $(idxdir)/$@
	touch $(idxdir)/$@

%.faaidx : %.fasta
	$(indexfasta) $< $(idxdir)/$@
	touch $(idxdir)/$@

clean :
	\rm -f $(idxdir)/*.datidx*
	\rm -f $(idxdir)/*.faaidx*


