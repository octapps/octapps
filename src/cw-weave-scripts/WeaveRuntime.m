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

## Estimate the runtime of 'lalapps_Weave'.
## Usage:
##   time_total = WeaveRuntime("opt", val, ...)
## where:
##   time_total:
##     estimated total runtime (seconds)
## Options:
##   setup_file:
##     Weave setup file, from which to extract various parameters
##   Nsegments,detectors,coh_Tspan:
##     Alternatives to 'setup_file'; give number of segments,
##     comma-separated list of detectors, and time span of coherent
##     segments
##   result_file:
##     Weave result file, from which to extract various parameters
##   freq_min,freq_max,dfreq,f1dot_max,f1dot_max,NSFTs,Fmethod:
##     Alternatives to 'result_file'; give minimum/maximum frequency,
##     frequency spacing, maximum 1st/2nd spindown, total number
##     of SFTs, and F-statistic method used by search
##   Ncohres,Nsemires:
##     Alternatives to 'result_file'; give number of coherent and
##     semicoherent results computed by search
##   tau_...:
##     Fundamental timing constants; time to compute, in seconds:
##       tau_demod_psft:
##         F-statistic using demod, per template per SFT
##       tau_resamp_{spin,FFT,Fbin}:
##         F-statistic using resampling, per template per detector
##       tau_mean2F_{add,div}:
##         mean F-statistic, per template

function time_total = WeaveRuntime(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"detectors", "char,+exactlyone:setup_file", []},
               {"Nsegments", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"coh_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"result_file", "char", []},
               {"freq_min", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"dfreq", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f1dot_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f2dot_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"NSFTs", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Fmethod", "char,+exactlyone:result_file", []},
               {"Ncohres", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Nsemires", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"tau_demod_psft", "real,strictpos,scalar", []},
               {"tau_resamp_spin", "real,strictpos,scalar", []},
               {"tau_resamp_FFT", "real,strictpos,scalar", []},
               {"tau_resamp_Fbin", "real,strictpos,scalar", []},
               {"tau_mean2F_add", "real,strictpos,scalar", 4.7e-9},   ## TODO: time these properly
               {"tau_mean2F_div", "real,strictpos,scalar", 4.7e-9},   ## TODO: time these properly
               {"TSFT", "integer,strictpos,scalar", 1800},
               []);

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = fitsread(setup_file);
    detectors = strjoin(setup.primary.header.detect, ",");
    assert(isfield(setup, "segments"));
    segs = setup.segments.data;
    segment_list = [ [segs.start_s] + 1e-9*[segs.start_ns]; [segs.end_s] + 1e-9*[segs.end_ns] ]';
    segment_props = AnalyseSegmentList(segment_list);
    Nsegments = segment_props.num_segments;
    coh_Tspan = segment_props.coh_mean_Tspan;
  endif

  ## if given, load result file and extract various parameters
  if !isempty(result_file)
    result = fitsread(result_file);
    freq_min = result.primary.header.minrng_freq;
    freq_max = result.primary.header.maxrng_freq;
    dfreq = result.primary.header.dfreq;
    f1dot_max = getoptfield(0, result.primary.header, "maxrng_f1dot");
    f2dot_max = getoptfield(0, result.primary.header, "maxrng_f2dot");
    NSFTs = result.primary.header.nsfts;
    Fmethod = result.primary.header.fmethod;
    Ncohres = result.primary.header.ncohres;
    Nsemires = result.primary.header.nsemires;
  endif

  ## compute various parameters
  Ndetectors = length(strsplit(detectors, ","));

  ## estimate F-statistic computation time per template
  args = struct;
  args.Tcoh = (NSFTs * TSFT) / (Nsegments * Ndetectors);
  args.Tspan = coh_Tspan;
  args.FreqMax = freq_max;
  args.FreqBand = freq_max - freq_min;
  args.dFreq = dfreq;
  args.f1dotMax = f1dot_max;
  args.f2dotMax = f2dot_max;
  args.tauLDsft = tau_demod_psft;
  args.tauSpin = tau_resamp_spin;
  args.tauFFT = tau_resamp_FFT;
  args.tauFbin = tau_resamp_Fbin;
  args.Tsft = TSFT;
  [time_resamp_perres_perdet, time_demod_perres] = fevalstruct(@estimateFstatTime, args, "stripempty", true);

  ## estimate time to compute coherent F-statistics
  if any(strfind(Fmethod, "Resamp"))
    time_2F = time_resamp_perres_perdet * Ncohres * Ndetectors;
  elseif any(strfind(Fmethod, "Demod"))
    time_2F = time_demod_perres * Ncohres;
  else
    error("%s: unknown F-statistic method '%s'", funcName, Fmethod);
  endif

  ## estimate time to compute mean semicoherent F-statistics
  time_mean2F = tau_mean2F_add * Nsemires * (Nsegments - 1) + tau_mean2F_div * Nsemires;

  ## estimate total run time
  time_total = time_2F + time_mean2F;

endfunction
