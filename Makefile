SHELL = /bin/bash
.DELETE_ON_ERROR :
.SECONDARY :

# use "make V=1" to display verbose output
verbose = $(verbose_$(V))
verbose_ = $(verbose_0)
verbose_0 = @echo "Making $@";

# check for a program in a list using type -P, or return false
CheckProg = $(strip $(shell $(1:%=type -P % || ) echo false))

# required programs
CTAGSEX := $(call CheckProg, ctags-exuberant)
FIND := $(call CheckProg, gfind find)
GIT := $(call CheckProg, git)
GREP := $(call CheckProg, grep)
MKOCTFILE := $(call CheckProg, mkoctfile)
OCTAVE := $(call CheckProg, octave) --silent --norc --no-history --no-window-system
SED := $(call CheckProg, gsed sed)
SORT := LC_ALL=C $(call CheckProg, sort) -f
SWIG := $(call CheckProg, swig)

# Octave version string, and hex number define for use in C code
version := $(shell $(OCTAVE) --eval "disp(OCTAVE_VERSION)")
vers_num := -DOCT_VERS_NUM=$(shell $(OCTAVE) --eval "disp(strcat(\"0x\", sprintf(\"%02i\", str2double(strsplit(OCTAVE_VERSION, \".\")))))")

# OctApps source path and file list
curdir := $(shell pwd -L)
srcpath := $(shell $(FIND) $(curdir)/src -type d ! \( -name private \) | $(SORT))
srcfilepath := $(filter-out %/deprecated, $(srcpath))
srcmfiles := $(wildcard $(srcfilepath:%=%/*.m))
srccfiles := $(wildcard $(srcfilepath:%=%/*.hpp) $(srcfilepath:%=%/*.cpp))

# OctApps extension module directory
octdir := oct/$(version)

# main targets
.PHONY : all check clean

# print list of deprecated functions at finish
all :
	@$(FIND) $(curdir)/src -path '*/deprecated/*' | $(SED) 's|^.*/|Warning: deprecated function |'
	@echo "=================================================="; \
	echo "OctApps has been successfully built!"; \
	echo "To set up your environment, please add the line"; \
	echo "  . $(curdir)/octapps-user-env.sh"; \
	echo "to ~/.profile for Bourne shells (e.g. bash), or"; \
	echo "  source $(curdir)/octapps-user-env.csh"; \
	echo "to ~/.login for C shells (e.g. tcsh)."; \
	echo "=================================================="

# generate environment scripts
all .PHONY : octapps-user-env.sh octapps-user-env.csh
octapps-user-env.sh octapps-user-env.csh : Makefile
	$(verbose_0)case $@ in \
		*.csh) empty='?'; setenv='setenv'; equals=' ';; \
		*) empty='#'; setenv='export'; equals='=';; \
	esac; \
	cleanpath="$(SED) -e 's/^/:/;s/$$/:/;:A;s/:\([^:]*\)\(:.*\|\):\1:/:\1:\2:/g;s/:::*/:/g;tA;s/^:*//;s/:*$$//'"; \
	octave_path="$(curdir)/$(octdir):`echo $(srcpath) | $(SED) 's/  */:/g'`:\$${OCTAVE_PATH}"; \
	path="$(curdir)/bin:\$${PATH}"; \
	echo "# source this file to access OctApps" > $@; \
	echo "test \$${$${empty}OCTAVE_PATH} -eq 0 && $${setenv} OCTAVE_PATH" >>$@; \
	echo "$${setenv} OCTAVE_PATH$${equals}\`echo $${octave_path} | $${cleanpath}\`" >>$@; \
	echo "test \$${$${empty}PATH} -eq 0 && $${setenv} PATH" >>$@; \
	echo "$${setenv} PATH$${equals}\`echo $${path} | $${cleanpath}\`" >>$@

# build extension modules
ifneq ($(MKOCTFILE),false)

VPATH = $(srcfilepath)

COMPILE = $(MKOCTFILE) $(vers_num) -g -c -o $@ $<
LINK = $(MKOCTFILE) -g -o $@ $(filter %.o,$^) $(LIBS)

octs = \
	depends

all : $(octdir) $(octs:%=$(octdir)/%.oct)

$(octdir) :
	@mkdir -p $@

$(octdir)/%.o : %.cpp Makefile
	$(verbose)$(COMPILE) -Wall

$(octdir)/%.oct : $(octdir)/%.o Makefile
	$(verbose)$(LINK)

# generate SWIG extension modules
ifneq ($(SWIG),false)

swig_octs = \
	gsl

$(octdir)/gsl.oct : LIBS = -lgsl

all : $(swig_octs:%=$(octdir)/%.oct)

$(swig_octs:%=$(octdir)/%.o) : $(octdir)/%.o : oct/%_wrap.cpp Makefile
	$(verbose)$(COMPILE)

$(swig_octs:%=oct/%_wrap.cpp) : oct/%_wrap.cpp : %.i Makefile
	$(verbose)$(SWIG) $(vers_num) -octave -c++ -globals "." -o $@ $<

$(swig_octs:%=$(octdir)/%.oct) : $(octdir)/%.oct : $(octdir)/%.o Makefile
	$(verbose)$(LINK)

endif # neq ($(SWIG),false)

endif # neq ($(MKOCTFILE),false)

# run test scripts
check : all
	@test -n "$${TESTS}" || TESTS="$(patsubst %.m,%,$(notdir $(srcmfiles)))"; \
	$(MAKE) `printf " %s.test" $${TESTS}` || exit 1; \
	echo "=================================================="; \
	echo "OctApps test suite has passed successfully!"; \
	echo "=================================================="

%.test :
	@source octapps-user-env.sh; \
	status=""; while read line; do \
		case "$${line}" in \
			"skip"*) status="skip";; \
			"PASSES"*) status="pass";; \
			"!!!!!"*) status="FAIL";; \
		esac; \
	done < <( $(OCTAVE) --eval "test $*" 2>&1 ); \
	test -n "$${status}" && echo "$${status}: $*"; \
	test "$${status}" != FAIL

# generate tags
ifneq ($(CTAGSEX),false)

all .PHONY : TAGS
TAGS :
	$(verbose_0)$(CTAGSEX) -e $(srcmfiles) $(srccfiles)

endif # neq ($(CTAGSEX),false)

# cleanup
clean :
	@$(GIT) clean -Xdf
