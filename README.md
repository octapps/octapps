### OctApps

Welcome to OctApps, the unofficial LSC Octave script repository!

Homepage: https://gitlab.aei.uni-hannover.de/octapps/octapps

Bugs should be reported to: https://bugs.ligo.org/redmine/projects/octapps

#### Checking out

OctApps is available via git with the following commands:

* Authorisation via SSH keys:
  > git clone git@gitlab.aei.uni-hannover.de:octapps/octapps.git

* Authorisation via command-line prompt:
  > git clone https://gitlab.aei.uni-hannover.de/octapps/octapps.git

#### Building

To use any OctApps functions with Octave, first run

> make

to generate the user environment setup scripts, then either add

> . /path/to/octapps/octapps-user-env.sh

to your ~/.profile file for Bourne shells (e.g. bash), or

> source /path/to/octapps/octapps-user-env.csh

to your ~/.login file for C shells (e.g. tcsh). You will also need to re-run "make" after adding any
new directories to OctApps.

If you have SWIG (http://www.swig.org/) installed, running

> make

will also build .oct modules which are required by some scripts. You will need to install the
development features of Octave, i.e. whichever package provides the script 'mkoctfile', in order to
compile .oct modules. Some scripts also require the LALSuite bindings for Octave.

#### Testing

To execute the OctApps test suite, consisting of tests embedded in Octave script files, run

> make check
