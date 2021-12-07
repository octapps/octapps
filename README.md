OctApps
=======

Welcome to *OctApps*, a library of Octave functions for continuous gravitational-wave data analysis.

Downloading
-----------

*OctApps* is hosted on [GitHub](https://github.com).
Please see the [project homepage](https://github.com/octapps/octapps) for instructions for checking out the repository with `git clone`.

Alternatively, a [Docker](https://www.docker.com) image containing the latest version of *OctApps* can be built by running

> $ docker build https://github.com/octapps/octapps.git

Dependencies
------------

*OctApps* depends on the following packages for various purposes:

<table>
<tr><th> Package </th><th> Purpose </th><th> Debian/Ubuntu </th><th> MacOSX </th></tr>
<tr><td> GNU Core Utilities </td><td> Used to build <i>OctApps</i> </td><td> installed as standard </td><td> <tt>brew install coreutils</tt> </td></tr>
<tr><td> GNU Find Utilities </td><td> Used to build <i>OctApps</i> </td><td> installed as standard </td><td> <tt>brew install findutils</tt> </td></tr>
<tr><td> GNU Sed </td><td> Used to build <i>OctApps</i> </td><td> installed as standard </td><td> <tt>brew install gnu-sed</tt> </td></tr>
<tr><td> GNU Awk </td><td> Used to build <i>OctApps</i> </td><td> installed as standard </td><td> <tt>brew install gawk</tt> </td></tr>
<tr><td> GNU Make </td><td> Used to build <i>OctApps</i> </td><td> <tt>apt install make</tt> </td><td> <tt>brew install make</tt> </td></tr>
<tr><td> pkg-config </td><td> Used to build <i>OctApps</i> </td><td> <tt>apt install pkg-config</tt> </td><td> <tt>brew install pkg-config</tt> </td></tr>
<tr><td> Octave </td><td> Running <i>OctApps</i> </td><td> <tt>apt install octave</tt> </td><td> <tt>brew install octave</tt> </td></tr>
<tr><td> Octave development headers </td><td> Used to build extension modules </td><td> <tt>apt install liboctave-dev</tt> </td><td> <tt>brew install octave</tt> </td></tr>
<tr><td> SWIG </td><td> Used to build extension modules </td><td> <tt>apt install swig3.0</tt> </td><td> <tt>brew install swig</tt> </td></tr>
<tr><td> GNU Texinfo </td><td> Used to build HTML documentation </td><td> <tt>apt install texinfo</tt> </td><td> <tt>brew install texinfo</tt> </td></tr>
<tr><td> LSC Algorithm Library (LALSuite) </td><td> Continuous gravitational-wave functions require packages <tt>lal-octave</tt>, <tt>lalxml-octave</tt>, <tt>lalpulsar-octave</tt>, and <tt>lalapps</tt> </td><td colspan="2"> See <a href="https://wiki.ligo.org/DASWG/LALSuite">project homepage</a> for build instructions </td></tr>
<tr><td> GNU Scientific Library </td><td> Used by <tt>gsl</tt> module </td><td> <tt>apt install libgsl-dev</tt> </td><td> <tt>brew install gsl</tt> </td></tr>
<tr><td> Gnuplot </td><td> Used by <tt>ezprint()</tt> function </td><td> <tt>apt install gnuplot</tt> </td><td> <tt>brew install gnuplot</tt> </td></tr>
<tr><td> FFmpeg </td><td> Used by <tt>ezmovie()</tt> function </td><td> <tt>apt install ffmpeg</tt> </td><td> <tt>brew install ffmpeg</tt> </td></tr>
<tr><td> CFITSIO </td><td> Used by <tt>fitsread()</tt> function </td><td> <tt>apt install libcfitsio-dev</tt> </td><td> <tt>brew install cfitsio</tt> </td></tr>
<tr><td> bzip2 </td><td> Used by <tt>SuperskyMetricsCache()</tt> function </td><td> <tt>apt install bzip2</tt> </td><td> <tt>brew install bzip2</tt> </td></tr>
</table>

Building
--------

To use any *OctApps* functions with Octave, first run

> $ make

to generate the user environment setup scripts, then either add

> $ . \<your-path-to>/octapps/octapps-user-env.sh

to your `~/.profile` file for Bourne shells (e.g. `bash`), or

> $ source \<your-path-to>/octapps/octapps-user-env.csh

to your `~/.login` file for C shells (e.g. `tcsh`).
You will also need to re-run `make` after any new directories are added to *OctApps*.

Testing
-------

To execute the *OctApps* test suite, consisting of tests embedded in Octave function files, run

> $ make check

You can also run the test suite for specific functions files:

> $ make check TESTS=runCode

> $ make check TESTS=src/general/runCode.m

or specific directories:

> $ make check TESTDIR=src/general

The *OctApps* test suite is regularly executed via [GitHub Actions](https://github.com/features/actions).
Current build status: [![Build Status](https://github.com/octapps/octapps/actions/workflows/ci.yml/badge.svg)](https://github.com/octapps/octapps/actions/workflows/ci.yml).

Documentation
-------------

A [reference manual](https://octapps.github.io) for *OctApps* in HTML format is regularly generated from the [master](https://github.com/octapps/octapps/tree/master) branch on GitHub.
It includes tutorials on several important features of *OctApps*, documentation for each function in the library, and example usages.

Documentation can also be obtained from within Octave on any *OctApps* function by running

> $ octave:1> help \<name-of-function>

Example usage for many *OctApps* functions can be found in the embedded tests, which can be printed using

> $ octave:1> test \<name-of-function> verbose

Contributing
------------

Contributions to *OctApps* are welcome.
Bug reports and other requests for support should be raised on the [issue tracker](https://github.com/octapps/octapps/issues) on GitHub.
Bug fixes and new contributions should be submitted as [pull requests](https://github.com/octapps/octapps/pulls) to the main *OctApps* repository.
Documentation for *OctApps* is embedded in Octave function files, and is written in [Texinfo](https://www.gnu.org/software/texinfo) format.

Acknowledgement
---------------

If you make use of *OctApps*, please cite our paper [![DOI](http://joss.theoj.org/papers/10.21105/joss.00707/status.svg)](https://doi.org/10.21105/joss.00707) in the [Journal of Open Source Software](http://joss.theoj.org):

```
@article{octapps,
  author = {Karl Wette and Reinhard Prix and David Keitel and Matthew Pitkin and Christoph Dreissigacker and John T. Whelan and Paola Leaci},
  title = {{OctApps: a library of Octave functions for continuous gravitational-wave data analysis}},
  journal = {Journal of Open Source Software},
  year = {2018},
  volume = {3},
  number = {26},
  pages = {707},
  doi = {10.21105/joss.00707},
}
```
