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
PKGCONFIG := $(call CheckProg, pkg-config)
SED := $(call CheckProg, gsed sed)
SORT := LC_ALL=C $(call CheckProg, sort) -f
SWIG := $(call CheckProg, swig3.0 swig2.0 swig)

# check for existence of package using pkg-config
CheckPkg = $(shell $(PKGCONFIG) --exists $1 && echo true)

# Octave version string, and hex number define for use in C code
version := $(shell $(OCTAVE) --eval "disp(OCTAVE_VERSION)")
vershex := -DOCTAVE_VERSION_HEX=$(shell $(OCTAVE) --eval "disp(strcat(\"0x\", sprintf(\"%02i\", str2double(strsplit(OCTAVE_VERSION, \".\")))))")

# OctApps source path and file list
curdir := $(shell pwd -L)
srcpath := $(shell $(FIND) $(curdir)/src -type d ! \( -name private \) | $(SORT))
srcfilepath := $(filter-out %/deprecated, $(srcpath))
srcmfiles := $(wildcard $(srcfilepath:%=%/*.m))
srccfiles := $(wildcard $(srcfilepath:%=%/*.hpp) $(srcfilepath:%=%/*.cpp))
srctestfiles := $(wildcard $(srcfilepath:%=%/*.m) $(srcfilepath:%=%/*.cpp) $(srcfilepath:%=%/*.i))

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

ifneq ($(MKOCTFILE),false)		# build extension modules

VPATH = $(srcfilepath)

Compile = rm -f $@ && $(MKOCTFILE) $(vershex) -g -c -o $@ $< $(CFLAGS) $1 && test -f $@
Link = rm -f $@ && $(MKOCTFILE) -g -o $@ $(filter %.o,$^) $(LIBS) $1 && test -f $@

octs += depends

ifeq ($(call CheckPkg, cfitsio),true)		# compile FITS reading module

octs += fitsread
$(octdir)/fitsread.oct : CFLAGS = $(shell $(PKGCONFIG) --cflags cfitsio)
$(octdir)/fitsread.oct : LIBS = $(shell $(PKGCONFIG) --libs cfitsio)

endif						# compile FITS reading module

all : $(octdir) $(octs:%=$(octdir)/%.oct)

$(octdir) :
	@mkdir -p $@

$(octdir)/%.o : %.cpp Makefile
	$(verbose)$(call Compile, -Wall)

$(octdir)/%.oct : $(octdir)/%.o Makefile
	$(verbose)$(call Link)

ifneq ($(SWIG),false)				# generate SWIG extension modules

swig_octs += gsl
$(octdir)/gsl.oct : CFLAGS = $(shell $(PKGCONFIG) --cflags gsl)
$(octdir)/gsl.oct : LIBS = $(shell $(PKGCONFIG) --libs gsl)

all : $(swig_octs:%=$(octdir)/%.oct)

$(swig_octs:%=$(octdir)/%.o) : $(octdir)/%.o : oct/%_wrap.cpp Makefile
	$(verbose)$(call Compile)

$(swig_octs:%=oct/%_wrap.cpp) : oct/%_wrap.cpp : %.i Makefile
	$(verbose)$(SWIG) $(vershex) -octave -c++ -globals "." -o $@ $<

$(swig_octs:%=$(octdir)/%.oct) : $(octdir)/%.oct : $(octdir)/%.o Makefile
	$(verbose)$(call Link)

else						# generate SWIG extension modules

all .PHONY : no_swig
no_swig :
	@echo "No SWIG binary found; SWIG C++ extensions were NOT built"

endif						# generate SWIG extension modules

else					# build extension modules

all .PHONY : no_mkoctfile
no_mkoctfile :
	@echo "No MKOCTFILE binary found; C++ extensions were NOT built"

endif					# build extension modules

# run test scripts
check : all
	@testfiles=; \
	for testfile in $(patsubst $(curdir)/src/%,%,$(srctestfiles)); do \
		testfiledir=`dirname $${testfile}`; \
		testfilename=`basename $${testfile}`; \
		if test -n "$${TESTS}"; then \
			case " $${TESTS} " in \
				*" $${testfilename%.*} "*) testfiles="$${testfiles} $${testfilename}";; \
			esac; \
		elif test -n "$${TESTDIR}"; then \
			case "src/$${testfiledir}/" in \
				$${TESTDIR}*|$${TESTDIR}/*) testfiles="$${testfiles} $${testfilename}"; \
			esac; \
		else \
			testfiles="$${testfiles} $${testfilename}"; \
		fi; \
	done; \
	if test -z "$${testfiles}"; then \
		echo "$(MAKE) $@ ERROR: no tests matched TESTS='$${TESTS}' or TESTDIR='$${TESTDIR}'" >&2; \
		exit 1; \
	fi; \
	if test -n "$${TESTS}"; then \
		echo "Running tests: $${TESTS}"; \
	elif test -n "$${TESTDIR}"; then \
		echo "Running tests in $${TESTDIR}"; \
	else \
		echo "Running all tests"; \
	fi; \
	$(MAKE) `printf "%s.test\n" $${testfiles} | $(SORT)` || exit 1; \
	echo "=================================================="; \
	echo "OctApps test suite has passed successfully!"; \
	echo "=================================================="

%.test :
	@source octapps-user-env.sh; \
	printf "%-48s: " "$*"; \
	$(OCTAVE) --eval "test $*" 2>&1 | { \
		while read line; do \
			case "$${line}" in \
				"?????"*) printf "\r"; exit 0;; \
				"skip"*) printf "skip\n"; exit 0;; \
				"PASSES"*) printf "pass\n"; exit 0;; \
				"!!!!!"*) printf "FAIL\n"; exit 1;; \
			esac; \
		done; \
	}

# generate tags
ifneq ($(CTAGSEX),false)

all .PHONY : TAGS
TAGS :
	$(verbose_0)$(CTAGSEX) -e $(srcmfiles) $(srccfiles)

endif # neq ($(CTAGSEX),false)

# cleanup
clean :
	@$(GIT) clean -Xdf
