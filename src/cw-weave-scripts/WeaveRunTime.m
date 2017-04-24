#!/usr/bin/env octapps_run
##
## Estimate the run time of 'lalapps_Weave'.
## Usage:
##   [total, times] = WeaveRunTime("opt", val, ...)
## Options:
##   setup_file:
##     Weave setup file, from which to extract various parameters
##   Nsegments,detectors,ref_time,start_time,coh_Tspan,semi_Tspan:
##     Alternatives to 'setup_file'; give number of segments, comma-
##     separated list of detectors, GPS reference/start time, time
##     span of coherent segments, and total time span of semicoherent
##     search
##   result_file:
##     Weave result file, from which to extract various parameters
##   freq_min/max,dfreq,f1dot_min/max,f2dot_min/max,NSFTs,Fmethod:
##     Alternatives to 'result_file'; give minimum/maximum frequency,
##     frequency spacing, minimum/maximum 1st/2nd spindown, total
##     number of SFTs, and F-statistic method used by search
##   Ncohres,Nsemires:
##     Alternatives to 'result_file'; give number of coherent and
##     semicoherent results computed by search
##   tau_...:
##     Fundamental timing constants; time to compute, in seconds:
##       tau_demod_psft:
##         F-statistic using demod, per template per SFT
##       tau_resamp_{Fbin,FFT,spin}:
##         F-statistic using resampling, per template per detector
##       tau_mean2F_{add,div}:
##         mean F-statistic, per template
## Outputs:
##   time_total:
##     estimate of total CPU run time (seconds)
##   times.cohres:
##     estimate of CPU time (seconds) to compute coherent F-statistics
##   times.semiparts:
##     estimate of CPU time (seconds) to add together F-statistics
##   times.semires:
##     estimate of CPU time (seconds) to compute:
##     - mean semicoherent F-statistic

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

function [time_total, times] = WeaveRunTime(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"Nsegments", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"detectors", "char,+exactlyone:setup_file", []},
               {"ref_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"start_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"coh_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"semi_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"result_file", "char", []},
               {"freq_min", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"dfreq", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f1dot_min", "real,positive,scalar,+exactlyone:result_file", []},
               {"f1dot_max", "real,positive,scalar,+exactlyone:result_file", []},
               {"f2dot_min", "real,positive,scalar,+exactlyone:result_file", []},
               {"f2dot_max", "real,positive,scalar,+atmostone:result_file", 0},
               {"NSFTs", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Fmethod", "char,+exactlyone:result_file", []},
               {"Ncohres", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Nsemires", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"tau_demod_psft", "real,strictpos,scalar", 5.1e-9},
               {"tau_resamp_Fbin", "real,strictpos,scalar", 6.1e-8},
               {"tau_resamp_FFT", "real,strictpos,vector", [1.5e-08, 3.4e-8]},
               {"tau_resamp_spin", "real,strictpos,scalar", 7.7e-8},
               {"tau_mean2F_add", "real,strictpos,scalar", 3.8e-10},
               {"tau_mean2F_div", "real,strictpos,scalar", 4.8e-10},
               {"TSFT", "integer,strictpos,scalar", 1800},
               []);

  ## initialise variables
  times = struct;

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = fitsread(setup_file);
    assert(isfield(setup, "segments"));
    segs = setup.segments.data;
    segment_list = [ [segs.start_s] + 1e-9*[segs.start_ns]; [segs.end_s] + 1e-9*[segs.end_ns] ]';
    segment_props = AnalyseSegmentList(segment_list);
    Nsegments = segment_props.num_segments;
    detectors = strjoin(setup.primary.header.detect, ",");
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

  ## compute various parameters
  Ndetectors = length(strsplit(detectors, ","));

  ## estimate time to compute coherent F-statistics
  if any(strfind(Fmethod, "Resamp"))

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
    args.tauFbin = tau_resamp_Fbin;
    args.tauFFT = tau_resamp_FFT;
    args.tauSpin = tau_resamp_spin;
    args.Tsft = TSFT;
    resamp_info = fevalstruct(@predictResampTimeAndMemory, args);
    times.cohres = Ncohres * Ndetectors * resamp_info.tauRS;

  elseif any(strfind(Fmethod, "Demod"))

    ## estimate time using demodulation F-statistic algorithm
    times.cohres = Ncohres * NSFTs * tau_demod_psft;

  else
    error("%s: unknown F-statistic method '%s'", funcName, Fmethod);
  endif

  ## estimate time to add together coherent F-statistics
  times.semiparts = tau_mean2F_add * Nsemires * (Nsegments - 1);

  ## estimate time to compute:
  ## - mean semicoherent F-statistics
  times.semires = tau_mean2F_div * Nsemires;

  ## estimate total run time
  time_total = sum(structfun(@sum, times));

endfunction
