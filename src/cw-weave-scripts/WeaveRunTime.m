#!/usr/bin/env octapps_run
##
## Estimate the run time of 'lalapps_Weave'.
## Usage:
##   [total, times] = WeaveRunTime("opt", val, ...)
## Options:
##   EITHER:
##     setup_file:      Weave setup file
##   OR:
##     Nsegments:       number of segments
##     Ndetectors:      number of detectors
##     ref_time:        GPS reference time
##     start_time:      GPS start time
##     coh_Tspan:       time span of coherent segments
##     semi_Tspan:      total time span of semicoherent search
##   EITHER:
##     result_file:     Weave result file
##   OR:
##     freq_min/max:    minimum/maximum frequency range
##     dfreq:           frequency spacing
##     f1dot_min/max:   minimum/maximum 1st spindown
##     f2dot_min/max:   minimum/maximum 2nd spindown (optional)
##     NSFTs:           total number of SFTs
##     Fmethod:         F-statistic method used by search
##     Ncohres:         number of coherent results
##     Nsemires:        number of semicoherent results
##   tau_set:
##     Set of fundamental timing constants to use
## Outputs:
##   times.total:
##     estimate of total CPU run time (seconds)
##   times.<field>:
##     estimate of CPU time (seconds) to perform action <field>;
##     see the script itself for further documentation
##   extra:
##     extra information, potentially specific to F-statistic algorithm

## Copyright (C) 2017 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [times, extra] = WeaveRunTime(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"Nsegments", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"Ndetectors", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"ref_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"start_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"coh_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"semi_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"result_file", "char", []},
               {"freq_min", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"dfreq", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f1dot_min", "real,scalar,+exactlyone:result_file", []},
               {"f1dot_max", "real,scalar,+exactlyone:result_file", []},
               {"f2dot_min", "real,scalar,+atmostone:result_file", 0},
               {"f2dot_max", "real,scalar,+atmostone:result_file", 0},
               {"NSFTs", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Fmethod", "char,+exactlyone:result_file", []},
               {"Ncohres", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Nsemires", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"tau_set", "char"},
               {"TSFT", "integer,strictpos,scalar", 1800},
               []);

  ## parse fundamental timing constant set
  tau = struct;
  switch tau_set
    case "v1"
      tau.lattice = 1.4e-10;
      tau.query = 8.9e-11;
      tau.demod_psft = 6.3e-8;
      tau.resamp_Fbin = 6.1e-8;
      tau.resamp_FFT = 3.4e-8;
      tau.resamp_spin = 7.7e-8;
      tau.mean2F_add = 7.0e-10;
      tau.mean2F_div = 2.1e-9;
      tau.output = 6.9e-10;
    otherwise
      error("%s: invalid timing constant set '%s'", funcName, tau_set);
  endswitch

  ## initialise variables
  times = struct;
  extra = struct;

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = fitsread(setup_file);
    assert(isfield(setup, "segments"));
    segs = setup.segments.data;
    segment_list = [ [segs.start_s] + 1e-9*[segs.start_ns]; [segs.end_s] + 1e-9*[segs.end_ns] ]';
    segment_props = AnalyseSegmentList(segment_list);
    Nsegments = segment_props.num_segments;
    Ndetectors = length(setup.primary.header.detect);
    ref_time = str2double(setup.primary.header.date_obs_gps);
    start_time = min(segment_list(:));
    coh_Tspan = segment_props.coh_mean_Tspan;
    semi_Tspan = segment_props.inc_Tspan;
  endif

  ## if given, load result file and extract various parameters
  if !isempty(result_file)
    result = fitsread(result_file);
    result_hdr = result.primary.header;
    freq_min = result_hdr.minrng_freq;
    freq_max = result_hdr.maxrng_freq;
    dfreq = result_hdr.dfreq;
    f1dot_min = getoptfield(0, result_hdr, "minrng_f1dot");
    f1dot_max = getoptfield(0, result_hdr, "maxrng_f1dot");
    f2dot_min = getoptfield(0, result_hdr, "minrng_f2dot");
    f2dot_max = getoptfield(0, result_hdr, "maxrng_f2dot");
    NSFTs = result_hdr.nsfts;
    Fmethod = result_hdr.fmethod;
    Ncohres = result_hdr.ncohres;
    Nsemires = result_hdr.nsemires;
  endif

  ## estimate time to interate over lattice tiling
  times.lattice = Nsemires * tau.lattice;

  ## estimate time to perform nearest-neighbour lookup queries
  times.query = Nsemires * Nsegments * tau.query;

  ## estimate time to compute coherent F-statistics
  if strncmpi(Fmethod, "Resamp", 6)

    ## estimate time using resampling F-statistic algorithm
    args = struct;
    args.Tcoh = (NSFTs * TSFT) / (Nsegments * Ndetectors);
    args.Tspan = coh_Tspan;
    args.Freq0 = freq_min;
    args.FreqBand = freq_max - freq_min;
    args.dFreq = dfreq;
    args.f1dot0 = f1dot_min;
    args.f1dotBand = f1dot_max - f1dot_min;
    args.f2dot0 = f2dot_min;
    args.f2dotBand = f2dot_max - f2dot_min;
    args.refTimeShift = (ref_time - start_time) / semi_Tspan;
    args.tauFbin = tau.resamp_Fbin;
    args.tauFFT = tau.resamp_FFT;
    args.tauSpin = tau.resamp_spin;
    args.Tsft = TSFT;
    resamp_info = fevalstruct(@predictResampTimeAndMemory, args);
    times.cohres = Ncohres * Ndetectors * resamp_info.tauRS;
    extra.lg2NsampFFT = resamp_info.lg2NsampFFT;

  elseif strncmpi(Fmethod, "Demod", 5)

    ## estimate time using demodulation F-statistic algorithm
    times.cohres = Ncohres * (NSFTs / Nsegments) * tau.demod_psft;

  else
    error("%s: unknown F-statistic method '%s'", funcName, Fmethod);
  endif

  ## estimate time to add together coherent F-statistics
  times.semiparts = Nsemires * (Nsegments - 1) * tau.mean2F_add;

  ## estimate time to compute:
  ## - mean semicoherent F-statistics
  times.semires = Nsemires * tau.mean2F_div;

  ## estimate time to output results
  times.output = Nsemires * tau.output;

  ## estimate total run time
  times.total = sum(structfun(@sum, times));

endfunction
