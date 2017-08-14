# This is where you want to install the Perl scripts
dest=$(HOME)/scripts/bioscripts/ftpmirror
# This is where you want to install the documentation
docdest=$(HOME)/scripts/bioscripts/docs
# And this is where the executables live
bin=$(HOME)/bin

# Current directory
src=$(shell pwd)

# Get rid of all built-in SUFFIX rules
.SUFFIXES : 

# Delete targets which can't be properly built
# Hmmmm this doesn't actually work cos the target is not placed in the
# current directory
.DELETE_ON_ERROR :

# Continue after all errors
.IGNORE :

# Destination directories
vpath %.src $(dest)
vpath %.pl  $(src)
vpath %     $(bin)

# Perl
psources := $(wildcard $(src)/*.pl)
pstems   := $(notdir $(psources))       # Strip the path
pbases   := $(basename $(pstems))       # Strip the extension
pfiles   := $(addsuffix .src, $(pbases))

all :
	@echo "Nothing to do."
	@echo "Use 'make install' to install the files"


install : $(pbases)

%.src : %.pl
	mkdir -p $(dest)
	(cd $(dest); cp $(src)/$< $@)

% : %.src
	mkdir -p $(bin)
	(cd $(bin); ln -sf $(dest)/$< $@)

