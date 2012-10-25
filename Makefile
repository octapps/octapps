SHELL = /bin/bash

FIND = $(shell type -P find || echo false)
GIT = $(shell type -P git || echo false)
MKOCTFILE = $(shell type -P mkoctfile || echo false)
OCTAVE = $(shell type -P octave || echo false)
OCTCONFIG = $(shell type -P octave-config || echo false)
SED = $(shell type -P sed || echo false)
SWIG = $(shell type -P swig || echo false)

version = $(shell $(OCTAVE) -qfH --eval "disp(OCTAVE_VERSION)")

verbose = $(verbose_$(V))
verbose_ = @echo "making $@";

.PHONY : all check clean

all .PHONY : octapps-user-env.sh octapps-user-env.csh
octapps-user-env.sh octapps-user-env.csh : Makefile
	$(verbose)echo "# source this file to access OctApps" > $@; \
	cleanpath="$(SED) -e 's/^/:/;s/$$/:/;:A;s/:\([^:]*\)\(:.*\|\):\1:/:\1:\2:/g;s/:::*/:/g;tA;s/^:*//;s/:*$$//'"; \
	mdirs=`$(FIND) $${PWD}/src -type d -printf '%p:'`; \
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

all : oct/$(version)

oct/$(version) :
	@mkdir -p $@

ifneq ($(SWIG),false)

all : oct/$(version)/gsl.oct

oct/$(version)/gsl.oct : oct/$(version)/gsl_wrap.cpp Makefile
	$(verbose)$(MKOCTFILE) -g -lgsl -o $@ $<

oct/$(version)/%_wrap.cpp : oct/%.i Makefile
	$(verbose)$(SWIG) -octave -c++ -globals "$*cvar" -o $@ $<

endif

all : oct/$(version)/depends.oct

oct/$(version)/depends.oct : oct/$(version)/depends.o Makefile
	$(verbose)$(MKOCTFILE) -g -o $@ $<

oct/$(version)/%.o : oct/%.cpp Makefile
	$(verbose)$(MKOCTFILE) -g -c -o $@ $<

check : all
	@source octapps-user-env.sh; \
	mfiles=`$(FIND) $${PWD}/src -name deprecated -prune -or -name '*.m' -printf '%f\n'`; \
	for mfile in $${mfiles}; do \
		echo "testing $${mfile}"; \
		$(OCTAVE) -qfH --eval "test $${mfile}; exit(1)" && exit 1; \
	done; exit 0

clean :
	$(verbose)$(GIT) clean -Xdf
