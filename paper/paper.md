---
title: 'OctApps: a library of Octave functions and scripts for gravitational-wave data analysis'
tags:
  - Octave
  - gravitational waves
  - data analysis
authors:
  - name: Reinhard Prix
    affiliation: 1
  - name: Christoph Dreissigacker
    affiliation: 1
  - name: David Keitel
    affiliation: 2
  - name: Paola Leaci
    affiliation: "3, 4"
  - name: Matthew Pitkin
    affiliation: 2
  - name: Karl Wette
    orcid: 0000-0002-4394-7179
    affiliation: 5
  - name: John T. Whelan
    affiliation: 6
affiliations:
  - name: Max Planck Institute for Gravitational Physics (Albert Einstein Institute), D-30167 Hannover, Germany
    index: 1
  - name: Institute for Gravitational Research, SUPA, University of Glasgow, Glasgow G12 8QQ, UK
    index: 2
  - name: Università di Roma 'La Sapienza,' I-00185 Roma, Italy
    index: 3
  - name: INFN, Sezione di Roma, I-00185 Roma, Italy
    index: 4
  - name: ARC Centre of Excellence for Gravitational Wave Discovery (OzGrav) and Centre for Gravitational Physics, Research School of Physics and Engineering, The Australian National University, ACT 0200, Australia
    index: 5
  - name: Rochester Institute of Technology, Rochester, NY 14623, USA
    index: 6
date: 21 March 2018
bibliography: paper.bib
---

# Summary

Gravitational waves are minute ripples in spacetime, first predicted by Einstein's general theory of relativity in 1916.
Their existence has now been confirmed by the recent successful detections of gravitational waves from the collision and merger of binary black holes [@LIGOVirg2016a] and binary neutron stars [@LIGOVirg2017a] in data from the [LIGO](https://www.ligo.org/) and [Virgo](http://www.virgo-gw.eu/) gravitational-wave detectors.
Gravitational waves from rapidly-rotating neutron stars, whose shape deviates from perfect axisymmetry, are another potential astrophysical source of gravitational waves, but which so far have not been detected.
The search for these type of signals, also known as continuous waves, presents a significant data analysis challenge, as their weak signatures are expected to be buried deep within the instrumental noise of the LIGO and Virgo detectors.
For reviews of continuous wave sources, data analysis techniques, and recent searches of LIGO and Virgo data, see for example [@Prix2009a, @Rile2017a].

The *OctApps* library provides various functions and scripts, written in Octave [@Octave2015], intended to aid research scientists who perform searches for continuous gravitational waves.
For example, it provides the following modules:

- `src/cw-sensitivity`: scripts which predict the sensitivity of a search for continuous waves, following the method of [@Wett2012a].
- `src/cw-optimal-search-setup`: scripts which determine the optimally-sensitive search for continuous gravitational waves, given a fixed computing budget, following the method of [@PrixShal2012a].
- `src/cw-line-veto`: scripts which implement detection statistics which are robust to instrumental disturbances in the detector data, as described in [@KeitEtAl2014a].
- `src/cw-metrics` and `src/cw-template-banks`: scripts which determine the number of filtering operations required to search for continuous waves over various astrophysical parameter spaces, described further in [@WettPrix2013a, @LeacPrix2015a].
- `src/cw-weave-scripts`: scripts which characterize the behaviour of *Weave*, an implementation of an optimized search pipeline for continuous waves [@Wett2018a].

In addition, *OctApps* provides many general-purpose functions and scripts, which may be of broader interest to users of Octave.
These include:

- `parseOptions()`: a powerful parser for Octave function argument lists in the form of key--value pairs.
- `octapps_run`: a Unix shell script which allows Octave functions which use `parseOptions()` to also be called directly from the Unix command line using a `--key=value` argument syntax.
- `@Hist`: an Octave class representing a histogram, with various method functions which perform common statistical operations, such as computing the cumulative distribution function.
- `depends()`: a low-level function written using Octave's C++ API which, given the name of an Octave function, returns the names of all Octave functions called by the named function. It can be used to deploy a self-contained tarball of OctApps scripts to a remote node on a computer cluster.

Development of *OctApps* is hosted [here](https://gitlab.aei.uni-hannover.de/octapps/octapps).
Documentation of each function or script is provided through the `help` function in Octave.
