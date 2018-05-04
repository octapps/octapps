---
title: 'OctApps: a library of Octave functions for continuous gravitational-wave data analysis'
tags:
  - Octave
  - gravitational waves
  - continuous waves
  - pulsars
  - data analysis
authors:
  - name: Karl Wette
    orcid: 0000-0002-4394-7179
    affiliation: 1
  - name: Reinhard Prix
    orcid: 0000-0002-3789-6424
    affiliation: "2, 3"
  - name: David Keitel
    orcid: 0000-0002-2824-626X
    affiliation: 4
  - name: Matthew Pitkin
    orcid: 0000-0003-4548-526X
    affiliation: 4
  - name: Christoph Dreissigacker
    affiliation: "2, 3"
  - name: John T. Whelan
    orcid: 0000-0001-5710-6576
    affiliation: 5
  - name: Paola Leaci
    affiliation: "6, 7"
affiliations:
  - name: ARC Centre of Excellence for Gravitational Wave Discovery (OzGrav) and Centre for Gravitational Physics, Research School of Physics and Engineering, The Australian National University, ACT 0200, Australia
    index: 1
  - name: Max Planck Institute for Gravitational Physics (Albert Einstein Institute), D-30167 Hannover, Germany
    index: 2
  - name: Leibniz Universität Hannover, D-30167 Hannover, Germany
    index: 3
  - name: Institute for Gravitational Research, SUPA, University of Glasgow, Glasgow G12 8QQ, UK
    index: 4
  - name: Rochester Institute of Technology, Rochester, NY 14623, USA
    index: 5
  - name: Università di Roma 'La Sapienza,' I-00185 Roma, Italy
    index: 6
  - name: INFN, Sezione di Roma, I-00185 Roma, Italy
    index: 7
date: 26 March 2018
bibliography: paper.bib
---

# Summary

Gravitational waves are minute ripples in spacetime, first predicted by Einstein's general theory of relativity in 1916.
Their existence has now been confirmed by the recent successful detections of gravitational waves from the collision and merger of binary black holes [@LIGOVirg2016a] and binary neutron stars [@LIGOVirg2017a] in data from the [LIGO](https://www.ligo.org) and [Virgo](http://www.virgo-gw.eu) gravitational-wave detectors.
Gravitational waves from rapidly-rotating neutron stars, whose shape deviates from perfect axisymmetry, are another potential astrophysical source of gravitational waves, but which so far have not been detected.
The search for this type of signals, also known as continuous waves, presents a significant data analysis challenge, as their weak signatures are expected to be buried deep within the instrumental noise of the LIGO and Virgo detectors.
For reviews of continuous-wave sources, data analysis techniques, and recent searches of LIGO and Virgo data, see for example @Prix2009a and @Rile2017a.

The *OctApps* library provides various functions, written in Octave [@Octave2015], intended to aid research scientists who perform searches for continuous gravitational waves.
They are organized into the following directories:

- `src/cw-data-analysis`: general-purpose functions for continuous-wave data analysis.
- `src/cw-line-veto`: functions which implement detection statistics which are robust to instrumental disturbances in the detector data, as described in [@KeitEtAl2014a].
- `src/cw-metric-template-banks`: functions which determine the number of filtering operations required to search for continuous waves over various astrophysical parameter spaces, described further in [@WettPrix2013a] and [@LeacPrix2015a].
- `src/cw-optimal-search-setup`: functions which determine the optimally-sensitive search for continuous gravitational waves, given a fixed computing budget, following the method of [@PrixShal2012a].
- `src/cw-sensitivity`: functions which predict the sensitivity of a search for continuous waves, following the method of [@Wett2012a].
- `src/cw-weave-models`: functions which characterize the behaviour of *Weave*, an implementation of an optimized search pipeline for continuous waves [@Wett2018a].

Many of these scripts make use of C functions from the [LSC Algorithm Library Suite (LALSuite)](https://wiki.ligo.org/DASWG/LALSuite), using [SWIG](http://www.swig.org) to provide the C-to-Octave interface.

In addition, *OctApps* provides various general-purpose functions, which may be of broader interest to users of Octave, organized into the following directories:

- `src/array-handling`: manipulation of Octave arrays and cell arrays.
- `src/command-line`: includes `parseOptions()`, a powerful parser for Octave function argument lists in the form of key--value pairs. Together with `octapps_run`, a Unix shell script, it allows Octave functions to also be called directly from the Unix command line using a `--key=value` argument syntax.
- `src/condor-jobs`: submission of jobs to a computer cluster using the [HTCondor](https://research.cs.wisc.edu/htcondor) job submission system. It includes `depends()`, a low-level function written using Octave's C++ API which, given the name of an Octave function, returns the names of all Octave functions called by the named function; it is used to deploy a self-contained tarball of Octave `.m` files to a remote node on a computer cluster.
- `src/convert-units`: functions which convert between different angular units, and between different time standards.
- `src/file-handling`: parsing of various file formats, such as FITS and `.ini`.
- `src/general`: miscellaneous general-purpose functions.
- `src/geometry`: mathematical operations associated with geometric objects, e.g. computing the intersection of two lines.
- `src/histograms`: includes `@Hist`, an Octave class representing a histogram, with various method functions which perform common statistical operations, e.g. computing the cumulative distribution function.
- `src/lattices`: mathematical operations associated with lattice theory, e.g. computing the nearest point in a lattice to a given point in space.
- `src/mathematical`: miscellaneous general mathematical functions, including some C functions incorporated from the GNU Scientific Library [@GSL2009], using SWIG to provide the C-to-Octave interface.
- `src/plotting`: helper functions for plot creation and output in [TeX](https://www.tug.org) format.
- `src/statistics`: miscellaneous statistical functions, particularly for probability distributions.
- `src/text-handling`: various functions for creating formatted text output.
- `src/version-handling`: handling of version information, particularly from the [Git](https://git-scm.com) version control system.

Development of *OctApps* is hosted on [GitHub](https://github.com/octapps/octapps); a test suite of all functions in *OctApps* is regularly integrated on [Travis CI](https://travis-ci.org/octapps/octapps).
The [README](https://github.com/octapps/octapps/blob/master/README.md) file provides instructions for building, testing, and contributing to *OctApps*, as well as a full list of prerequisite software required by *OctApps*.
A [reference listing](https://octapps.github.io) of functions in *OctApps* in HTML format is available; documentation of each *OctApps* function can also be accessed through the `help` function in Octave.

## Acknowledgements

We acknowledge that *OctApps* includes contributions from Zdravko Botev, Ronaldas Macas, John McNabb, and Daniel de Torre Herrera.
We thank Steven R. Brandt for reviewing this paper and providing the `Dockerfile` for building and testing *OctApps*.
This paper has document number LIGO-P1800078-v4.

# References
