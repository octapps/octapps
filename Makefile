SHELL = /bin/bash

FIND = $(shell type -P find || echo false)
GIT = $(shell type -P git || echo false)
MKOCTFILE = $(shell type -P mkoctfile || echo false)
OCTAVE = $(shell type -P octave || echo false) --silent --norc --no-history --no-window-system
OCTCONFIG = $(shell type -P octave-config || echo false)
SED = $(shell type -P sed || echo false)
SWIG = $(shell type -P swig || echo false)
CTAGSEX = $(shell type -P ctags-exuberant || echo false)

version = $(shell $(OCTAVE) --eval "disp(OCTAVE_VERSION)")

verbose = $(verbose_$(V))
verbose_ = @echo "making $@";

.PHONY : all check clean

all .PHONY : octapps-user-env.sh octapps-user-env.csh
octapps-user-env.sh octapps-user-env.csh : Makefile
	$(verbose)echo "# source this file to access OctApps" > $@; \
	cleanpath="$(SED) -e 's/^/:/;s/$$/:/;:A;s/:\([^:]*\)\(:.*\|\):\1:/:\1:\2:/g;s/:::*/:/g;tA;s/^:*//;s/:*$$//'"; \
	mdirs=`$(FIND) $${PWD}/src -type d ! -name private -printf '%p:'`; \
	octave_path="$${PWD}/oct/$(version):$${mdirs}\$${OCTAVE_PATH}"; \
	path="$${PWD}/bin:\$${PATH}"; \
	case $@ in \
		*.csh) \
			echo "if ( ! \$${?OCTAVE_PATH} ) setenv PATH" >> $@; \
			echo "setenv OCTAVE_PATH \`echo $${octave_path} | $${cleanpath}\`" >>$@; \
			echo "if ( ! \$${?PATH} ) setenv PATH" >> $@; \
			echo "setenv PATH \`echo $${path} | $${cleanpath}\`" >>$@; \
			echo "complete octapps_run 'p|1|\`$(FIND) $${PWD}/src -type f -name \"*.m\" -printf \"%f \"\`|'" >> $@; \
			;; \
		*.sh) \
			echo "OCTAVE_PATH=\`echo $${octave_path} | $${cleanpath}\`" >>$@; \
			echo "export OCTAVE_PATH" >>$@; \
			echo "PATH=\`echo $${path} | $${cleanpath}\`" >>$@; \
			echo "export PATH" >>$@; \
			echo "_octapps_run() {" >>$@; \
			echo "  COMPREPLY=()" >>$@; \
			echo "  if [ \$${COMP_CWORD} -eq 1 ]; then" >>$@; \
			echo "    COMPREPLY=( \`$(FIND) $${PWD}/src -type f -name \"\$${COMP_WORDS[COMP_CWORD]}*.m\" -printf '%f\n'\` )" >>$@; \
			echo "  fi" >>$@; \
			echo "}" >>$@; \
			echo "complete -F _octapps_run octapps_run" >>$@; \
			;; \
	esac

ifneq ($(MKOCTFILE),false)

all : oct/$(version)

oct/$(version) :
	@mkdir -p $@

ifneq ($(SWIG),false)

all : oct/$(version)/gsl.oct

oct/$(version)/gsl.oct : oct/$(version)/gsl_wrap.o
	$(verbose)$(MKOCTFILE) -g -lgsl -o $@ $<

oct/$(version)/%_wrap.o : oct/$(version)/%_wrap.cpp
	$(verbose)$(MKOCTFILE) -c -o $@ $<

oct/$(version)/%_wrap.cpp : oct/%.i Makefile
	$(verbose)$(SWIG) -octave -c++ -globals "$*cvar" -o $@ $<

endif # neq ($(SWIG),false)

all : oct/$(version)/depends.oct

oct/$(version)/depends.oct : oct/$(version)/depends.o Makefile
	$(verbose)$(MKOCTFILE) -g -o $@ $<

oct/$(version)/%.o : oct/%.cpp Makefile
	$(verbose)$(MKOCTFILE) -g -c -o $@ $<

endif # neq ($(MKOCTFILE),false)

check : all
	@source octapps-user-env.sh; \
	mfiles=`$(FIND) $${PWD}/src -name deprecated -prune -or -name '*.m' -printf '%p\n'`; \
	script='printf("testing %s ...\n",f);[n,m]=test(f); printf("... passed %i of %i\n",n,m); exit(!(0<n && n==m));'; \
	for mfile in $${mfiles}; do \
		if grep -q '^%!' "$${mfile}"; then \
			$(OCTAVE) -qfH --eval "f='$${mfile}';$${script}" || exit 1; \
		fi; \
	done; exit 0

ifneq ($(CTAGSEX),false)

all .PHONY : TAGS
TAGS :
	$(verbose)$(GIT) ls-files '*.m' | xargs $(CTAGSEX) -e

endif # neq ($(CTAGSEX),false)

clean :
	$(verbose)$(GIT) clean -Xdf
