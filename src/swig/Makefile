SHELL = /bin/bash

OCTDIR = lib

INTERFACES = $(wildcard gsl/*.i)
vpath %.i $(dir $(INTERFACES))

OCTFILES = $(addprefix $(OCTDIR)/,$(addsuffix .oct,$(basename $(notdir $(INTERFACES)))))

.PHONY : all clean

all : $(OCTFILES)

clean :
	rm -f $(OCTFILES) && rmdir $(OCTDIR)

.PRECIOUS : %_wrap.cpp %_wrap.o

$(OCTDIR)/gsl_%.oct : gsl_%_wrap.cpp
	mkdir -p $(OCTDIR) && mkoctfile -lgsl -o $@ $< && rm -f $< $(addsuffix .o,$(basename $<))

%_wrap.cpp : %.i
	swig -c++ -octave -o $@ $<
