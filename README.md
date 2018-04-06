OctApps
=======

Welcome to *OctApps*, a library of Octave functions for continuous gravitational-wave data analysis.

Downloading OctApps
-------------------

*OctApps* is hosted as a [git](https://git-scm.com/) repository.
See the project [homepage](https://github.com/octapps/octapps) for instructions for checking out the repository with `git clone`.
Bugs should be reported on the [issue tracker](https://github.com/octapps/octapps/issues) and patches submitted via merge requests.

Building and Using OctApps
--------------------------

To use any *OctApps* functions with Octave, first run

> make

to generate the user environment setup scripts, then either add

> . /YOUR/PATH/TO/octapps/octapps-user-env.sh

to your `~/.profile` file for Bourne shells (e.g. bash), or

> source /YOUR/PATH/TO/octapps/octapps-user-env.csh

to your `~/.login` file for C shells (e.g. tcsh).
You will also need to re-run `make` after adding any new directories to *OctApps*.

If you have [SWIG](http://www.swig.org/) installed, running `make` will also build `.oct` modules which are required by some functions.
You will need to install the development features of Octave, i.e. whichever package provides the command `mkoctfile`, in order to compile `.oct` modules.
Some functions also require the [LALSuite](https://wiki.ligo.org/DASWG/LALSuite) bindings for Octave; see that project's homepage for build instructions.

Testing OctApps
---------------

To execute the *OctApps* test suite, consisting of tests embedded in Octave function files, run

> make check

You can also run the test suite for specific functions files:

> make check TESTS=funcName

> make check TESTS=src/general/funcName.m

or specific directories:

> make check TESTDIR=src/general/

The *OctApps* test suite is regularly executed on [Travis CI](https://travis-ci.org/).
Current build status: [![Build Status](https://travis-ci.org/octapps/octapps.svg?branch=master)](https://travis-ci.org/octapps/octapps).
