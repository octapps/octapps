SHELL = /bin/bash
.DELETE_ON_ERROR :

# use "make V=1" to display verbose output
verbose = $(verbose_$(V))
verbose_ = $(verbose_0)
verbose_0 = @echo "making $@";

# check for a program in a list using type -P, or return false
CheckProg = $(strip \
              $(if $(1), \
                $(if $(shell type -P $(firstword $(1))), \
                  $(firstword $(1)), \
                  $(call CheckProg,$(strip $(wordlist 2, $(words $(1)), $(1)))) \
                 ), \
                 false \
                ) \
              )

# required programs
CTAGSEX := $(call CheckProg, ctags-exuberant)
FIND := $(call CheckProg, gfind find)
GIT := $(call CheckProg, git)
GREP := $(call CheckProg, grep)
MKOCTFILE := $(call CheckProg, mkoctfile)
OCTAVE := $(call CheckProg, octave) --silent --norc --no-history --no-window-system
SED := $(call CheckProg, gsed sed)
SWIG := $(call CheckProg, swig)

# Octave version
version := $(shell $(OCTAVE) --eval "disp(OCTAVE_VERSION)")

# OctApps source path and file list
srcpath := $(shell $(FIND) $(CURDIR)/src -type d ! \( -name private -or -name deprecated \) -printf '%p:')
srcfiles := $(shell $(FIND) `echo $(srcpath) | $(SED) 's/:/ /g'` -type f -name '*.m')

.PHONY : all check clean

# generate environment scripts
all .PHONY : octapps-user-env.sh octapps-user-env.csh
octapps-user-env.sh octapps-user-env.csh : Makefile
	$(verbose)echo "# source this file to access OctApps" > $@; \
	cleanpath="$(SED) -e 's/^/:/;s/$$/:/;:A;s/:\([^:]*\)\(:.*\|\):\1:/:\1:\2:/g;s/:::*/:/g;tA;s/^:*//;s/:*$$//'"; \
	octave_path="$${PWD}/oct/$(version):$(srcpath)\$${OCTAVE_PATH}"; \
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

# build extension modules
ifneq ($(MKOCTFILE),false)

oct_modules = \
	depends

# generate SWIG extension modules
ifneq ($(SWIG),false)

oct_modules += \
	gsl

gsl_ldflags = -lgsl

oct/%.cpp : oct/%.i Makefile
	$(verbose)$(SWIG) -octave -c++ -globals "$*cvar" -o $@ $<

endif # neq ($(SWIG),false)

all : oct/$(version) $(addprefix oct/$(version)/, $(addsuffix .oct, $(oct_modules)))

oct/$(version) :
	@mkdir -p $@

oct/$(version)/%.oct : oct/$(version)/%.o Makefile
	$(verbose)$(MKOCTFILE) -g -o $@ $< $($*_ldflags)

oct/$(version)/%.o : oct/%.cpp Makefile
	$(verbose)$(MKOCTFILE) -g -c -o $@ $<

endif # neq ($(MKOCTFILE),false)

# run test scripts
check : all
	$(verbose)source octapps-user-env.sh; \
	script='printf("testing %s ...\n",f);[n,m]=test(f); printf("... passed %i of %i\n",n,m); exit(!(0<n && n==m));'; \
	for mfile in `$(GREP) -l '^%!' $(srcfiles) /dev/null`; do \
		$(OCTAVE) -qfH --eval "f='$${mfile}';$${script}" || exit 1; \
	done; exit 0

# generate tags
ifneq ($(CTAGSEX),false)

all .PHONY : TAGS
TAGS :
	$(verbose)$(CTAGSEX) -e $(srcfiles)

endif # neq ($(CTAGSEX),false)

# cleanup
clean :
	$(verbose)$(GIT) clean -Xdf
