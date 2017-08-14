# This is where you want to install the Perl scripts
dest=$(HOME)/scripts/bioscripts/indexfasta
# And this is where the executables live
bin=$(HOME)/bin

# The location of SwissProt
updir=/acrm/data/swissprot/full
# The location of your index files
idxdir=/acrm/data/tmp

###############################################################
#            Shouldn't need changes after this                #
###############################################################

# Current directory
src=$(shell pwd)


indexfasta=$(BIN)/indexfasta
indexsprot=$(BIN)/indexswissprot

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

# Destination directories
vpath %.src $(dest)
vpath %.pl  $(src)
vpath %     $(bin)

# Perl
psources := $(wildcard $(src)/*.pl)
pstems   := $(notdir $(psources))       # Strip the path
pbases   := $(basename $(pstems))       # Strip the extension
pfiles   := $(addsuffix .src, $(pbases))


install : $(pbases)
	cp Makefile $(dest)

%.src : %.pl
	mkdir -p $(dest)
	(cd $(dest); cp $(src)/$< $@)

% : %.src
	mkdir -p $(bin)
	(cd $(bin); ln -sf $(dest)/$< $@)


