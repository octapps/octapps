SHELL = /bin/bash
.DELETE_ON_ERROR :
.SECONDARY :

# current directory
curdir := $(shell pwd -L)

# use "make V=1" to display verbose output
making = $(making_$(V))
making_ = $(making_0)
making_0 = @echo "Making $@";
verbose = $(verbose_$(V))
verbose_ = $(verbose_0)
verbose_0 = @

# check for a program in a list using type -P, or return false
CheckProg = $(strip $(shell $(1:%=type -P % || ) echo false))

# required programs
AWK := $(call CheckProg, gawk awk)
CTAGSEX := $(call CheckProg, ctags-exuberant)
DIFF := $(call CheckProg, diff)
FIND := $(call CheckProg, gfind find)
GIT := $(call CheckProg, git)
GREP := $(call CheckProg, grep)
MKOCTFILE := env CC= CXX= $(call CheckProg, mkoctfile)
OCTAVE := $(call CheckProg, octave) --silent --norc --no-history --no-window-system
PKGCONFIG := $(call CheckProg, pkg-config)
SED := $(call CheckProg, gsed sed)
SORT := LC_ALL=C $(call CheckProg, sort) -f
SWIG := $(call CheckProg, swig3.0 swig2.0 swig)
TR := $(call CheckProg, tr)
UNIQ := $(call CheckProg, uniq)

# check for existence of package using pkg-config
CheckPkg = $(shell $(PKGCONFIG) --exists $1 && echo true)

# Octave version string, and hex number define for use in C code
version := $(shell $(OCTAVE) --eval "disp(OCTAVE_VERSION)")
vershex := -DOCTAVE_VERSION_HEX=$(shell $(OCTAVE) --eval "addpath('$(curdir)/src/version-handling', '-begin'); printf('0x%x', versionstr2hex(OCTAVE_VERSION))")

# OctApps source path and file lists
srcpath := $(shell $(OCTAVE) --eval "addpath('$(curdir)/src/general', '$(curdir)/src/version-handling', '-begin'); __octapps_genpath__()")
srcfilepath := $(filter-out %/deprecated, $(srcpath))
srcmfiles := $(wildcard $(srcfilepath:%=%/*.m))
srccfiles := $(wildcard $(srcfilepath:%=%/*.hpp) $(srcfilepath:%=%/*.cc))
srctestfiles := $(filter-out %__.m, $(wildcard $(srcfilepath:%=%/*.m) $(srcfilepath:%=%/@*/*.m) $(srcfilepath:%=%/*.cc) $(srcfilepath:%=%/*.i)))

# OctApps extension module directory
octdir := oct/$(version)

# main targets
.PHONY : all check clean

# print list of deprecated functions at finish
all :
	$(verbose)test -f .deprecated || echo > .deprecated; \
	$(FIND) $(curdir)/src -path '*/deprecated/*.m' -printf '%f\n' > .deprecated-new; \
	$(DIFF) --normal .deprecated .deprecated-new | $(SED) -n 's|^>|Warning: deprecated function|p'; \
	mv -f .deprecated-new .deprecated
	@echo "=================================================="; \
	echo "OctApps has been successfully built!"; \
	echo "To set up your environment, please add the line"; \
	echo "  . $(curdir)/octapps-user-env.sh"; \
	echo "to ~/.profile for Bourne shells (e.g. bash), or"; \
	echo "  source $(curdir)/octapps-user-env.csh"; \
	echo "to ~/.login for C shells (e.g. tcsh)."; \
	echo "=================================================="

# generate links in bin/ directory
all .PHONY : bin
bin :
	$(making)mkdir -p $(curdir)/bin; \
	rm -f $(curdir)/bin/octapps_run; \
	ln -s $(curdir)/src/command-line/octapps_run $(curdir)/bin/octapps_run; \
	for octappsrunlink in `$(GREP) -l '\#\# octapps_run_link' $(srcmfiles)`; do \
		octappsrunfunc=`basename $${octappsrunlink} | $(SED) 's/\.m$$//'`; \
		octappsrunfile="$(curdir)/bin/$${octappsrunfunc}"; \
		printf "#!/bin/bash\nexec octapps_run $${octappsrunfunc} \"\$$@\"\n" > $${octappsrunfile}; \
		chmod +x $${octappsrunfile}; \
	done

# generate environment scripts
all .PHONY : octapps-user-env.sh octapps-user-env.csh
octapps-user-env.sh octapps-user-env.csh : Makefile
	$(making)case $@ in \
		*.csh) empty='?'; setenv='setenv'; equals=' ';; \
		*) empty='#'; setenv='export'; equals='=';; \
	esac; \
	cleanpath="$(SED) -e 's/^/:/;s/$$/:/;:A;s/:\([^:]*\)\(:.*\|\):\1:/:\1:\2:/g;s/:::*/:/g;tA;s/^:*//;s/:*$$//'"; \
	octave_path="$(curdir)/$(octdir):$(curdir)/oct:`echo $(srcpath) | $(SED) 's/  */:/g'`:\$${OCTAVE_PATH}"; \
	path="$(curdir)/bin:\$${PATH}"; \
	echo "# source this file to access OctApps" > $@; \
	echo "test \$${$${empty}OCTAVE_PATH} -eq 0 && $${setenv} OCTAVE_PATH" >>$@; \
	echo "$${setenv} OCTAVE_PATH$${equals}\`echo $${octave_path} | $${cleanpath}\`" >>$@; \
	echo "test \$${$${empty}PATH} -eq 0 && $${setenv} PATH" >>$@; \
	echo "$${setenv} PATH$${equals}\`echo $${path} | $${cleanpath}\`" >>$@

# generate author list, sorted by last name
all .PHONY : AUTHORS
AUTHORS : Makefile
	$(making)( $(GIT) shortlog -s | $(SED) 's/^[^A-Z]*//'; $(GIT) grep Copyright src/ | $(SED) 's/^.*Copyright ([Cc]) [-0-9, ]*//' | $(TR) ',' '\n' | $(SED) 's/^ *//' ) | $(SORT) -u > .$@.all; \
	awkscript='/^[A-Z].*@.*$$/ { name = $$0 } /^[0-9]/ { lines[name] += $$1 } END { for (name in lines) printf "%i\t%s\n", lines[name], name }'; \
	$(GIT) log --pretty='format:%aN <%aE>' --numstat | $(AWK) "$${awkscript}" | $(SORT) -k1,1 -n -r | $(SED) -n 's/^[^A-Z]*//;s/ <[^@]*@[^@]*>$$//p' > $@; \
	echo >> $@; $(SORT) .$@.all $@ $@ | $(UNIQ) -u | $(SED) 's/ \([a-z][a-z]*\) / \1@/;t;s/ \([^ ][^ ]*\)$$/@\1/' | $(SORT) -t @ -k2,2 | $(SED) 's/@/ /g' >> $@; \
	rm -f .$@.*

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
	$(verbose)mkdir -p $@

$(octdir)/%.o : %.cc Makefile
	$(making)$(call Compile, -Wall -Wno-narrowing)

$(octdir)/%.oct : $(octdir)/%.o Makefile
	$(making)$(call Link)

ifneq ($(SWIG),false)				# generate SWIG extension modules

swig_octs += gsl
$(octdir)/gsl.oct : CFLAGS = $(shell $(PKGCONFIG) --cflags gsl)
$(octdir)/gsl.oct : LIBS = $(shell $(PKGCONFIG) --libs gsl)

all : $(swig_octs:%=$(octdir)/%.oct)

$(swig_octs:%=$(octdir)/%.o) : $(octdir)/%.o : oct/%.cc Makefile
	$(making)$(call Compile, -Wno-narrowing)

$(swig_octs:%=oct/%.cc) : oct/%.cc : %.i Makefile
	$(making)$(SWIG) $(vershex) -octave -c++ -globals "." -o $@ $<

$(swig_octs:%=$(octdir)/%.oct) : $(octdir)/%.oct : $(octdir)/%.o Makefile
	$(making)$(call Link)

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
	$(verbose)testfiles=; \
	for testfile in $(patsubst $(curdir)/src/%,%,$(srctestfiles)); do \
		testfiledir=`dirname $${testfile}`; \
		testfilename=`basename $${testfile}`; \
		testclass=`basename $${testfiledir}`; \
		case "$${testclass}" in \
			@*) \
				testfilename="$${testclass}::$${testfilename}";; \
		esac; \
		if test -n "$${TESTS}"; then \
			case " $${TESTS} " in \
				*" $${testfilename%.*} "*) testfiles="$${testfiles} $${testfilename}";; \
				*" src/$${testfile} "*) testfiles="$${testfiles} $${testfilename}";; \
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
	export OCTAPPS_TMPDIR=`mktemp -d -t octapps-make-check.XXXXXX`; \
	echo "Created temporary directory $${OCTAPPS_TMPDIR}"; \
	$(MAKE) `printf "%s.test\n" $${testfiles} | $(SORT)` || exit 1; \
	rm -rf "$${OCTAPPS_TMPDIR}"; \
	echo "Removed temporary directory $${OCTAPPS_TMPDIR}"; \
	echo "=================================================="; \
	echo "OctApps test suite has passed successfully!"; \
	echo "=================================================="

%.test :
	$(verbose)source octapps-user-env.sh; \
	case "X$(MAKEFLAGS)" in \
		*j*) cn='\n'; cr='';; \
		*) cn=''; cr='\r';; \
	esac; \
	test=`echo "$*" | $(SED) 's|::|/|g'`; \
	printf "%-48s: $${cn}" "$${test}"; \
	OCTAPPS_TEST_LOG="$${OCTAPPS_TMPDIR}/.$*.log"; \
	env TMPDIR="$${OCTAPPS_TMPDIR}" $(OCTAVE) --eval "__octapps_make_check__('$${test}');" 2>&1 | tee "$${OCTAPPS_TEST_LOG}" | { \
		while read line; do \
			case "$${line}" in \
				"error: help"*) action=missinghelp;; \
				"?????"*) action=missingtest;; \
				"skip"*) if test "x$(NOSKIP)" = x; then action=skip; else action=fail; fi;; \
				"PASSES"*) action=pass;; \
				"!!!!!"*) action=fail;; \
				*) action=;; \
			esac; \
			case "$${action}" in \
				missinghelp) printf "$${cr}%-48s: HELP MESSAGE ERROR\n" "$${test}"; status=1;; \
				missingtest) printf "$${cr}%-48s: MISSING TEST(S)\n" "$${test}"; status=1;; \
				skip) printf "$${cr}%-48s: skipping test(s)\n" "$${test}"; status=0;; \
				pass) printf "$${cr}%-48s: test(s) passed\n" "$${test}"; status=0;; \
				fail) printf "$${cr}%-48s: TEST(S) FAILED\n" "$${test}"; status=1;; \
				*) status=;; \
			esac; \
			if test "x$${status}" = x1; then \
				printf "%-72s\n" "$${test}:" | $(SED) 's/ /-/g;s/:-/: /'; \
				$(SED) "s|^|$${test}: |" "$${OCTAPPS_TEST_LOG}"; \
				printf "%-72s\n" "$${test}:" | $(SED) 's/ /-/g;s/:-/: /'; \
			fi; \
			if test "x$${status}" != x; then \
				exit $${status}; \
			fi; \
		done; \
	}

# generate tags
ifneq ($(CTAGSEX),false)

all .PHONY : TAGS
TAGS :
	$(making)$(CTAGSEX) -e $(srcmfiles) $(srccfiles)

endif # neq ($(CTAGSEX),false)

# cleanup
clean :
	$(verbose)$(GIT) clean -Xdf
