# This is where you want to install the Perl scripts
dest=/tmp/test/bioscripts
# And this is where the executables live
bin=/tmp/test/bin

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

all : $(pbases)

%.src : %.pl
	(cd $(dest); cp $(src)/$< $@)

% : %.src
	(cd $(bin); ln -sf $(dest)/$< $@)

