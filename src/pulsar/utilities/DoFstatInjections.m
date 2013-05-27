## Copyright (C) 2013 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Perform full software injections in generated SFTs using LALPulsar functions.
##   results = DoFstatInjections(...)
## Options (starred options are returned in results):
##   ref_time: reference time in GPS seconds
##   start_time: start time in GPS seconds (default: ref_time - 0.5*time_span)
##   time_span: observation time-span in seconds
##   detectors: comma-separated list of detector names
##   ephemerides: Earth/Sun ephemerides from loadEphemerides()
##   sft_time_span: SFT time-span in seconds (default: 1800)
##   sft_overlap: SFT overlap in seconds (default: 0)
##  *inj_h0: injected h0 strain amplitude (default: 1.0)
##  *inj_cosi: injected cosine of inclination angle (default: random)
##  *inj_psi: injected polarisation angle (default: random)
##  *inj_phi0: injected initial phase (default: random)
##  *inj_alpha: injected right ascension (default: random)
##  *inj_delta: injected declination (default: random)
##  *inj_fndot: injected frequency/spindowns (default: 100 Hz)
##   inj_band_pad: padding to add to SFTs either side of injections (default: 0.1 Hz)
##  *sch_alpha: searched right ascension (default: same as injected)
##  *sch_delta: searched declination (default: same as injected)
##  *sch_fndot: searched frequency/spindowns (default: same as injected)

function results = DoFstatInjections(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"ref_time", "real,strictpos,scalar"},
               {"start_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephemerides", "a:swig_ref", []},
               {"sft_time_span", "real,strictpos,scalar", 1800},
               {"sft_overlap", "real,positive,scalar", 0},
               {"inj_h0", "real,strictpos,scalar", 1.0},
               {"inj_cosi", "real,scalar", -1 + 2*rand()},
               {"inj_psi", "real,scalar", 2*pi*rand()},
               {"inj_phi0", "real,scalar", 2*pi*rand()},
               {"inj_alpha", "real,scalar", 2*pi*rand()},
               {"inj_delta", "real,scalar", asin(-1 + 2*rand())},
               {"inj_fndot", "real,vector", [100]},
               {"sch_alpha", "real,vector", []},
               {"sch_delta", "real,vector", []},
               {"sch_fndot", "real,matrix", []},
               []);

  ## use injection parameters as search parameters, if not given
  if isempty(sch_alpha)
    sch_alpha = inj_alpha;
  endif
  if isempty(sch_delta)
    sch_delta = inj_delta;
  endif
  if isempty(sch_fndot)
    sch_fndot = inj_fndot;
  endif

  ## check options
  assert(size(inj_fndot, 2) == 1);
  assert(size(sch_fndot, 1) == size(sch_fndot, 1));
  num_sch = size(sch_fndot, 2);
  assert(num_sch > 0);
  assert(all(size(sch_alpha) == [1, num_sch]));
  assert(all(size(sch_delta) == [1, num_sch]));

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## create reference and start times
  refTime = new_LIGOTimeGPS(ref_time);
  if isempty(start_time)
    start_time = ref_time - 0.5 * time_span;
  endif
  startTime = new_LIGOTimeGPS(start_time);

  ## create results struct
  results = struct;
  results.inj_h0 = inj_h0;
  results.inj_cosi = inj_cosi;
  results.inj_psi = inj_psi;
  results.inj_phi0 = inj_phi0;
  results.inj_alpha = inj_alpha;
  results.inj_delta = inj_delta;
  results.inj_fndot = inj_fndot;
  results.sch_alpha = sch_alpha;
  results.sch_delta = sch_delta;
  results.sch_fndot = sch_fndot;
  results.sch_twoF = zeros(1, num_sch);

  ## create and fill sources input vector for CWMakeFakeData()
  MFDsources = CreatePulsarParamsVector(1);
  MFDsources.data{1}.Amp.h0   = inj_h0;
  MFDsources.data{1}.Amp.cosi = inj_cosi;
  MFDsources.data{1}.Amp.psi  = inj_psi;
  MFDsources.data{1}.Amp.phi0 = inj_phi0;
  MFDsources.data{1}.Doppler.Alpha = inj_alpha;
  MFDsources.data{1}.Doppler.Delta = inj_delta;
  MFDsources.data{1}.Doppler.fkdot = zeros(size(MFDsources.data{1}.Doppler.fkdot));
  MFDsources.data{1}.Doppler.fkdot(1:length(inj_fndot)) = inj_fndot;
  MFDsources.data{1}.Doppler.refTime = refTime;

  ## create and fill input parameters struct for ComputeFStat()
  CFSparams = new_ComputeFParams;
  CFSparams.Dterms = 16;
  CFSparams.SSBprec = SSBPREC_RELATIVISTICOPT;
  CFSparams.buffer = [];
  CFSparams.useRAA = false;
  CFSparams.bufferedRAA = false;
  CFSparams.edat = ephemerides;
  CFSparams.returnAtoms = false;
  CFSparams.returnSingleF = false;
  CFSparams.upsampling = 1;

  ## parse detector names, and check length of SFT noise sqrt(Sh) vector
  detNames = CreateStringVector(strsplit(detectors, ","){:});

  ## generate SFT timestamps
  multiTimestamps = MakeMultiTimestamps(startTime, time_span, sft_time_span, sft_overlap, detNames.length);

  ## determine range of frequencies spanned by injections and searches
  min_freq = min([inj_fndot(1), sch_fndot(1, :)]);
  max_freq = max([inj_fndot(1), sch_fndot(1, :)]);

  ## if injection includes spindowns, determine what frequency band they cover
  if length(inj_fndot) > 1

    ## compute range of frequencies covered at beginning and end of SFTs
    dfreqs = [];
    spins = [inj_fndot(2:end), sch_fndot(2:end, :)];
    orders = (1:length(inj_fndot)-1)';
    inv_facts = 1 ./ factorial(orders);
    for i = 1:size(spins, 2)
      dfreqs = [dfreqs, ...
                sum(spins(:, i) .* inv_facts .* (start_time - ref_time).^orders), ...
                sum(spins(:, i) .* inv_facts .* (start_time + time_span - ref_time).^orders)];
    endfor

    ## add spindown range to frequency range
    min_freq += min(dfreqs);
    max_freq += max(dfreqs);

  endif

  ## add the maximum frequency modulation due to the orbital Doppler modulation
  dfreq_orbit = 2*pi * LAL_AU_SI / LAL_C_SI / LAL_YRSID_SI * max_freq;
  min_freq -= dfreq_orbit;
  max_freq += dfreq_orbit;

  ## add the minimum number of bins requires by ComputeFStat()
  min_freq -= CFSparams.Dterms / sft_time_span;
  max_freq += CFSparams.Dterms / sft_time_span;

  ## round frequencies down/up to nearest SFT bin, and add a few more bins for safety
  min_freq = (floor(min_freq * sft_time_span) - 5) / sft_time_span;
  max_freq = (floor(max_freq * sft_time_span) + 5) / sft_time_span;

  ## create and fill input parameters struct for CWMakeFakeData()
  MFDparams = new_CWMFDataParams;
  MFDparams.fMin = min_freq;
  MFDparams.Band = max_freq - min_freq;
  ParseMultiDetectorInfo(MFDparams.detInfo, detNames, []);
  MFDparams.multiTimestamps = multiTimestamps;
  MFDparams.randSeed = 0;

  ## run CWMakeFakeData() to generate SFTs with injections
  multiSFTs = CWMakeFakeMultiData([], [], MFDsources, MFDparams, ephemerides);

  ## generate multi-detector states
  multiIFO = ExtractMultiLALDetectorFromSFTs(multiSFTs);
  multiTS = ExtractMultiTimestampsFromSFTs(multiSFTs);
  Tsft = 1.0 / multiSFTs.data{1}.data{1}.deltaF;
  tOffset = 0.5 * Tsft;
  detStates = GetMultiDetectorStates(multiTS, multiIFO, ephemerides, tOffset);

  ## create ComputeFStat() input and output structs
  Doppler = new_PulsarDopplerParams;
  Fcomp = new_Fcomponents;

  ## run ComputeFStat() for each injection point
  CFSbuffer = new_ComputeFBuffer;
  for i = 1:num_sch

    ## fill input Doppler parameters struct for ComputeFStat()
    Doppler.Alpha = sch_alpha(i);
    Doppler.Delta = sch_delta(i);
    Doppler.fkdot = zeros(size(Doppler.fkdot));
    Doppler.fkdot(1:size(sch_fndot, 1)) = sch_fndot(:, i);
    Doppler.refTime = refTime;

    ## run ComputeFStat()
    ComputeFStat(Fcomp, Doppler, multiSFTs, [], detStates, CFSparams, CFSbuffer);

    ## return F-statistic values
    results.sch_twoF(i) = 2 * Fcomp.F;

  endfor
  EmptyComputeFBuffer(CFSbuffer);

  ## change any NaNs in F-statistic to Infs
  results.sch_twoF(isnan(results.sch_twoF)) = inf;

endfunction
