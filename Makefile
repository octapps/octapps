PREFIX = $(shell echo $$PWD/_inst)

SHELL = /bin/bash
.DELETE_ON_ERROR :
.SECONDARY :

# current directory
curdir := $(shell pwd -L)

# use "make V=1" to display verbose output
verbose = $(verbose_$(V))
verbose_ = $(verbose_0)
verbose_0 = @
making = $(making_$(V))
making_ = $(making_0)
making_0 = @echo "Making $@";
makingdoc = $(makingdoc_$(V))
makingdoc_ = $(makingdoc_0)
makingdoc_0 = @echo "Making documentation for" `echo $* | $(SED) "s|^$${OCTAPPS_TMPDIR}/||;"'s|@@|@|g;s|::|/|g;'`;

# check for a program in a list using type -P, or return false
CheckProg = $(strip $(shell $(1:%=type -P % || ) echo false))

# required programs
AWK := $(call CheckProg, gawk awk)
CTAGSEX := $(call CheckProg, ctags-exuberant)
DIFF := $(call CheckProg, diff)
FIND := $(call CheckProg, gfind find)
GIT := $(call CheckProg, git)
GREP := $(call CheckProg, grep)
INSTALL := $(call CheckProg, install)
MAKEINFO := $(call CheckProg, makeinfo) --force --no-warn --no-validate -c TOP_NODE_UP_URL='https://github.com/octapps/octapps'
MKOCTFILE := env CC="$(CC)" CXX="$(CXX)" $(call CheckProg, mkoctfile)
OCTAVE := $(call CheckProg, octave-cli, octave) --no-gui --silent --norc --no-history --no-window-system
OCTCONFIG := env CC="$(CC)" CXX="$(CXX)" $(call CheckProg, octave-config)
PKGCONFIG := $(call CheckProg, pkg-config)
SED := $(call CheckProg, gsed sed)
SORT := LC_ALL=C $(call CheckProg, sort) -f
SWIG := $(call CheckProg, swig3.0 swig2.0 swig)
TR := $(call CheckProg, tr)
UNIQ := $(call CheckProg, uniq)

# check for latest version of SWIG
SWIG := $(shell ( for swigbin in swig swig2.0 swig3.0 swig4.0; do \
		swigbin=`type -P $${swigbin} || echo false`; $${swigbin} -version | $(SED) -n "s|\.| |g;s|^SWIG Version|$${swigbin}|p"; \
		done; echo false 0 0 0 ) | sort -r -n -k2,4 | $(SED) -n 's| .*$$||;1p' )

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
srctexifiles = $(srctestfiles)
srcotherfiles = \
	$(wildcard src/histograms/@Hist/*.m) \
	$(wildcard src/histograms/@Hist/private/*.m) \
	src/lattices/lattice_mismatch_hgrms.bin.gz \
	$(end_of_list)

# OctApps extension module directory
octdir := oct/$(version)

# main target
.PHONY : all install

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

ifneq ($(GIT),false)			# requires Git

# generate author list, sorted by last name
all .PHONY : AUTHORS
AUTHORS : Makefile
	$(making)( $(GIT) shortlog -s | $(SED) 's/^[^A-Z]*//'; $(GIT) grep Copyright src/ | $(SED) 's/\s*([^()][^()]*)//g;s/^.*Copyright [-0-9, ]*//' | $(TR) ',' '\n' | $(SED) 's/^ *//' ) | $(SORT) -u > .$@.all; \
	awkscript='/^[A-Z].*@.*$$/ { name = $$0 } /^[0-9]/ { lines[name] += $$1 } END { for (name in lines) printf "%i\t%s\n", lines[name], name }'; \
	$(GIT) log --pretty='format:%aN <%aE>' --numstat | $(AWK) "$${awkscript}" | $(SORT) -k1,1 -n -r | $(SED) -n 's/^[^A-Z]*//;s/ <[^@]*@[^@]*>$$//p' > $@; \
	echo >> $@; $(SORT) .$@.all $@ $@ | $(UNIQ) -u | $(SED) 's/ \([a-z][a-z]*\) / \1@/;t;s/ \([^ ][^ ]*\)$$/@\1/' | $(SORT) -t @ -k2,2 | $(SED) 's/@/ /g' >> $@; \
	rm -f .$@.*

endif					# requires Git

ifneq ($(MKOCTFILE),false)		# build extension modules

VPATH = $(srcfilepath)

ALL_CFLAGS = -Wno-narrowing -Wno-deprecated-declarations

Compile = rm -f $@ \
	&& ABIFLAG=`cat $(octdir)/abiflag.cfg` \
	&& CFLAGS=`test "x$(DEPENDS)" = x || $(PKGCONFIG) --cflags $(DEPENDS)` \
	&& $(MKOCTFILE) $(vershex) -g -c -o $@ $< $(ALL_CFLAGS) $${ABIFLAG} $${CFLAGS} $1 \
	&& test -f $@

Link = rm -f $@ \
	&& LIBS=`test "x$(DEPENDS)" = x || $(PKGCONFIG) --libs $(DEPENDS)` \
	&& $(MKOCTFILE) -g -o $@ $(filter %.o,$^) $${LIBS} $1 \
	&& test -f $@

MakeABIFlagModule = rm -f $(octdir)/abiflag.oct \
	&& $(MKOCTFILE) -D_GLIBCXX_USE_CXX11_ABI=$1 -c -o $(octdir)/abiflag.o $(octdir)/abiflag.cc \
	&& $(MKOCTFILE) -o $(octdir)/abiflag.oct $(octdir)/abiflag.o \
	&& $(OCTAVE) --path "$(octdir)" --eval "abiflag" >/dev/null 2>&1

$(octdir) :
	$(verbose)mkdir -p $@

$(octdir)/abiflag.cfg : $(octdir) Makefile
	$(making)echo "#include <octave/oct.h>" > $(octdir)/abiflag.cc; \
	echo "DEFUN_DLD( abiflag, args, nargout, \"usage\" ) { return octave_value_list(); }" >> $(octdir)/abiflag.cc; \
	( $(call MakeABIFlagModule,0) && echo "-D_GLIBCXX_USE_CXX11_ABI=0" > $@ ) || true; \
	( $(call MakeABIFlagModule,1) && echo "-D_GLIBCXX_USE_CXX11_ABI=1" > $@ ) || true; \
	rm -f $(octdir)/abiflag.cc $(octdir)/abiflag.o $(octdir)/abiflag.oct

$(octdir)/%.o : %.cc $(octdir)/abiflag.cfg Makefile
	$(making)$(call Compile,-Wall)

$(octdir)/%.oct : $(octdir)/%.o Makefile
	$(making)$(call Link)

octs += depends

ifeq ($(call CheckPkg, cfitsio),true)		# compile FITS reading module

octs += fitsread
$(octdir)/fitsread.oct : DEPENDS = cfitsio

endif						# compile FITS reading module

all : $(octdir) $(octs:%=$(octdir)/%.oct)

ifneq ($(SWIG),false)				# generate SWIG extension modules

swig_octs += gsl
$(octdir)/gsl.oct : DEPENDS = gsl

all : $(swig_octs:%=$(octdir)/%.oct)

$(swig_octs:%=$(octdir)/%.o) : $(octdir)/%.o : oct/%.cc $(octdir)/abiflag.cfg Makefile
	$(making)$(call Compile)

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
.PHONY : check
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
	export OCTAPPS_TMPDIR='/tmp/octapps-make-check'; \
	if test "x$(NOCLEANUP)" = x; then \
		rm -rf "$${OCTAPPS_TMPDIR}"; \
		export OCTAPPS_TMPDIR=`mktemp -d -t octapps-make-check.XXXXXX`; \
	else \
		mkdir -p "$${OCTAPPS_TMPDIR}"; \
	fi; \
	echo "Created temporary directory $${OCTAPPS_TMPDIR}"; \
	$(MAKE) `printf "$${OCTAPPS_TMPDIR}/%s.test\n" $${testfiles} | $(SORT)` || exit 1; \
	if test "x$(NOCLEANUP)" = x; then \
		rm -rf "$${OCTAPPS_TMPDIR}"; \
		echo "Removed temporary directory $${OCTAPPS_TMPDIR}"; \
	else \
		echo "NOT removing temporary directory $${OCTAPPS_TMPDIR}"; \
	fi; \
	echo "=================================================="; \
	echo "OctApps test suite has passed successfully!"; \
	echo "=================================================="

%.test :
	$(verbose)source octapps-user-env.sh; \
	case "X$(MAKEFLAGS)" in \
		*j*) cn='\n'; cr=''; cl='';; \
		*) cn=''; cr='\r'; cl='\n';; \
	esac; \
	test=`echo "$*" | $(SED) "s|^$${OCTAPPS_TMPDIR}/||;"'s|::|/|g'`; \
	printf "%-48s: %-16s$${cn}" "$${test}" "test(s) running"; \
	env TMPDIR="$${OCTAPPS_TMPDIR}" $(OCTAVE) --eval "__octapps_make_check__('$${test}');" 2>&1 | tee $@ | { \
		while true; do \
			read -t 60 line; \
			case "$${line}" in \
				"error: help"*) action=missinghelp;; \
				"?????"*) action=missingtest;; \
				"skip"*) if test "x$(NOSKIP)" = x; then action=skip; else action=fail; fi;; \
				"PASSES"*) action=pass;; \
				"!!!!!"*) action=fail;; \
				*) action=;; \
			esac; \
			case "$${action}" in \
				missinghelp) printf "$${cr}%-48s: %-16s\n" "$${test}" "HELP MESSAGE ERROR"; status=1;; \
				missingtest) printf "$${cr}%-48s: %-16s\n" "$${test}" "MISSING TEST(S)"; status=1;; \
				skip) printf "$${cr}%-48s: %-16s\n" "$${test}" "skipping test(s)"; status=0;; \
				pass) printf "$${cr}%-48s: %-16s\n" "$${test}" "test(s) passed"; status=0;; \
				fail) printf "$${cr}%-48s: %-16s\n" "$${test}" "TEST(S) FAILED"; status=1;; \
				*) status=;; \
			esac; \
			if test "x$${status}" = x1; then \
				printf "%-72s\n" "$${test}:" | $(SED) 's/ /-/g;s/:-/: /'; \
				$(SED) "s|^|$${test}: |" $@; \
				printf "%-72s\n" "$${test}:" | $(SED) 's/ /-/g;s/:-/: /'; \
			fi; \
			if test "x$${status}" != x; then \
				exit $${status}; \
			fi; \
			if test "x$${line}" = x; then \
				printf "$${cl}%-48s: %-16s$${cn}" "$${test}" "test(s) running"; \
			fi; \
		done; \
	}

# generate HTML documentation
.PHONY : html
html : all
	$(verbose)texifiles=; texifilesdirs=; texidirs=; \
	for texifile in $(patsubst $(curdir)/src/%,%,$(srctexifiles)); do \
		texifiledir=`dirname $${texifile}`; \
		texifilename=`basename $${texifile}`; \
		texiclass=`basename $${texifiledir}`; \
		case "$${texiclass}" in \
			@*) \
				texifilename="$${texiclass}::$${texifilename}";; \
		esac; \
		texidirname=`echo $${texifiledir} | $(SED) 's|/|::|g;'`; \
		texifiles="$${texifiles} $${texifilename}"; \
		texidirfiles="$${texidirfiles} $${texidirname} "`echo $${texifilename} | $(SED) 's|@|@@|g'`; \
		texidirs="$${texidirs} "`echo $${texidirname} | $(SED) 's|@|@@|g'`; \
	done; \
	export OCTAPPS_TMPDIR='/tmp/octapps-make-html'; \
	if test "x$(NOCLEANUP)" = x; then \
		rm -rf "$${OCTAPPS_TMPDIR}"; \
		export OCTAPPS_TMPDIR=`mktemp -d -t octapps-make-html.XXXXXX`; \
	else \
		mkdir -p "$${OCTAPPS_TMPDIR}"; \
	fi; \
	echo "Created temporary directory $${OCTAPPS_TMPDIR}"; \
	printf "$${OCTAPPS_TMPDIR}/%s.dir.texi %s.texi\n" $${texidirfiles} | $(SORT) | $(AWK) '{ printf "@include %s\n", $$2 >> $$1}'; \
	$(OCTAVE) --eval "fid = fopen('$${OCTAPPS_TMPDIR}/directory-index.texi', 'w'); assert(fid >= 0); fprintf(fid, '@include %s\n', texi_macros_file()); fclose(fid);"; \
	printf "@menu\n" > "$${OCTAPPS_TMPDIR}/directory-index-menu.texi"; \
	for texidir in `printf "%s\n" $${texidirs} | $(SORT) -u`; do \
		dir=`echo $${texidir} | $(SED) 's|::|/|g;'`; \
		printf "* @file{%s}:: Functions in the @file{%s} directory.\n" "$${dir}" "$${dir}" >> "$${OCTAPPS_TMPDIR}/directory-index-menu.texi"; \
		printf "@node @file{%s}\n@section @file{%s}\n@include %s\n" "$${dir}" "$${dir}" "$${texidir}.dir.texi" >> "$${OCTAPPS_TMPDIR}/directory-index.texi"; \
	done; \
	printf "@end menu\n" >> "$${OCTAPPS_TMPDIR}/directory-index-menu.texi"; \
	$(MAKE) `printf "$${OCTAPPS_TMPDIR}/%s.texi\n" $${texifiles} | $(SORT)` || exit 1; \
	if test "x$(GIT)" != xfalse; then \
		gitstatus=`( $(GIT) diff --quiet && echo "" ) || echo " @b{UNCLEAN}"`; \
		$(GIT) log -1 --pretty="format:This manual was generated from @emph{OctApps} commit @t{%H}$${gitstatus}, %aD." > "$${OCTAPPS_TMPDIR}/gitinfo.texi"; \
	else \
		echo "This manual was last generated on @today{}." > "$${OCTAPPS_TMPDIR}/gitinfo.texi"; \
	fi; \
	mkdir -p "$(curdir)/html"; \
	rm -rf "$(curdir)/html"/*; \
	( cd "$${OCTAPPS_TMPDIR}" && $(MAKEINFO) --html -o "$(curdir)/html" "$(curdir)/doc/home.texi" ) || exit 1; \
	cp "$(curdir)/doc"/*.png "$(curdir)/html"; \
	echo "OctApps reference manual: https://octapps.github.io" > "$(curdir)/html/README.md"; \
	if test "x$(NOCLEANUP)" = x; then \
		rm -rf "$${OCTAPPS_TMPDIR}"; \
		echo "Removed temporary directory $${OCTAPPS_TMPDIR}"; \
	else \
		echo "NOT removing temporary directory $${OCTAPPS_TMPDIR}"; \
	fi; \
	echo "=================================================="; \
	echo "OctApps HTML documentation has been built!"; \
	echo "=================================================="

%.texi :
	$(makingdoc)source octapps-user-env.sh; \
	$(OCTAVE) --eval "__octapps_make_html__('$*');"

# install to PREFIX
install: all
	$(verbose)prefix=`$(OCTCONFIG) -p PREFIX`; test "x$${prefix}" = x && prefix=`$(OCTCONFIG) -p OCTAVE_HOME`; \
	octsitedir=`$(OCTCONFIG) --oct-site-dir | sed "s|^$${prefix}|$(PREFIX)|"`; \
	msitedir=`$(OCTCONFIG) --m-site-dir | sed "s|^$${prefix}|$(PREFIX)|"`; \
	$(INSTALL) -m755 -d $(PREFIX)/bin $(PREFIX)/etc $${octsitedir} $${msitedir} $${msitedir}/octapps; \
	$(INSTALL) $(curdir)/bin/octapps_run $(PREFIX)/bin; \
	$(INSTALL) $(octdir)/*.oct $${octsitedir}; \
	for n in $(patsubst $(curdir)/%,%,$(srcmfiles)) $(srcotherfiles); do \
		$(INSTALL) -D -m644 $(curdir)/$$n $${msitedir}/octapps/$$n || exit 1; \
	done; \
	for n in octapps-user-env.sh octapps-user-env.csh; do \
		case $$n in \
			*.csh) empty='?'; setenv='setenv'; equals=' ';; \
			*) empty='#'; setenv='export'; equals='=';; \
		esac; \
		echo "# source this file to access OctApps" > $(PREFIX)/etc/$$n; \
		echo "test \$${$${empty}OCTAVE_PATH} -eq 0 && $${setenv} OCTAVE_PATH" >> $(PREFIX)/etc/$$n; \
		echo "$${setenv} OCTAVE_PATH$${equals}$${octsitedir}"`$(FIND) $${msitedir}/octapps -type d -printf ':%p' | $(SORT)`":\$${OCTAVE_PATH}" >> $(PREFIX)/etc/$$n; \
		echo "test \$${$${empty}PATH} -eq 0 && $${setenv} PATH" >> $(PREFIX)/etc/$$n; \
		echo "$${setenv} PATH$${equals}$(PREFIX)/bin:\$${PATH}" >> $(PREFIX)/etc/$$n; \
		chmod 644 $(PREFIX)/etc/$$n; \
	done
	@echo "=================================================="; \
	echo "OctApps has been successfully installed in"; \
	echo "  $(PREFIX)"; \
	echo "To set up your environment, please add the line"; \
	echo "  . $(PREFIX)/etc/octapps-user-env.sh"; \
	echo "to ~/.profile for Bourne shells (e.g. bash), or"; \
	echo "  source $(PREFIX)/etc/octapps-user-env.csh"; \
	echo "to ~/.login for C shells (e.g. tcsh)."; \
	echo "=================================================="

ifneq ($(CTAGSEX),false)		# requires Exuberant Ctags

# generate tags
all .PHONY : TAGS
TAGS :
	$(making)$(CTAGSEX) -e $(srcmfiles) $(srccfiles)

endif					# requires Exuberant Ctags

ifneq ($(GIT),false)			# requires Git

# cleanup
.PHONY : clean
clean :
	$(verbose)$(GIT) clean -Xdf

endif					# requires Git
