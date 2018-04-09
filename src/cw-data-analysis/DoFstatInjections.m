## Copyright (C) 2013, 2014 Karl Wette
## Copyright (C) 2013, 2014 Paola Leaci
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

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{results}, @var{multiSFTs}, @var{multiTser} ] =} DoFstatInjections ( @var{opt}, @var{val}, @dots{} )
##
## Perform full software injections in generated SFTs using LALPulsar functions.
##
## @heading Arguments
##
## @table @var
## @item result
## results structure
##
## @item multiSFTs
## multi-vector of SFTs containing simulated signal
##
## @item multiTser
## multi-time series vector containing simulated signal
##
## @end table
##
## @heading Options (starred options are returned in results)
##
## @table @code
## @item ref_time
## reference time in GPS seconds
##
## @item start_time
## start time in GPS seconds (default: ref_time - 0.5*time_span)
##
## @item time_span
## observation time-span in seconds
##
## @item detectors
## comma-separated list of detector names
##
## @item det_sqrt_PSD
## sqrt(single-sided noise PSD) to assume for each detector
##
## @item ephemerides
## Earth/Sun ephemerides from @command{loadEphemerides()}
##
## @item sft_time_span
## SFT time-span in seconds (default: 1800)
##
## @item sft_overlap
## SFT overlap in seconds (default: 0)
##
## @item sft_noise_window
## number of bins used when estimating SFT noise (default: 50)
##
## @item inj_sqrt_PSD
## inject Gaussian random noise with sqrt(single-sided noise PSD) for each detector
##
## @item *inj_h0
## injected h0 strain amplitude (default: 1.0)
##
## @item *inj_cosi
## injected cosine of inclination angle (default: random)
##
## @item *inj_psi
## injected polarisation angle (default: random)
##
## @item *inj_phi0
## injected initial phase (default: random)
##
## @item *inj_alpha
## injected right ascension (default: random)
##
## @item *inj_delta
## injected declination (default: random)
##
## @item *inj_fndot
## injected frequency/spindowns (default: 100 Hz)
##
## @item *sch_alpha
## searched right ascension (default: same as injected)
##
## @item *sch_delta
## searched declination (default: same as injected)
##
## @item *sch_fndot
## searched frequency/spindowns (default: same as injected)
##
## @item OrbitParams
## option that needs to be set to 'true' to be able to specify the orbital parameters (default: false)
##
## @item *inj_orbitasini
## injected orbital projected semi-major axis (normalised by the speed of light) in seconds (default: random)
##
## @item *inj_orbitEcc
## injected orbital eccentricity (default: random)
##
## @item *inj_orbitTpSSB
## injected (SSB) time of periapsis passage (in seconds) (default: random)
##
## @item *inj_orbitPeriod
## injected orbital period (seconds) (default: random)
##
## @item *inj_orbitArgp
## injected argument of periapsis (radians) (default: random)
##
## @item *sch_orbitasini
## searched orbital projected semi-major axis (normalised by the speed of light) in seconds (default: same as injected)
##
## @item *sch_orbitEcc
## searched orbital eccentricity (default: same as injected)
##
## @item *sch_orbitTpSSB
## searched (SSB) time of periapsis passage (in seconds) (default: same as injected)
##
## @item *sch_orbitPeriod
## searched orbital period (seconds) (default: same as injected)
##
## @item *sch_orbitArgp
## searched argument of periapsis (radians) (default: same as injected)
##
## @item Dterms
## number of Dirichlet terms to use in @command{ComputeFstat()} (default: number used by optimised hotloops)
##
## @end table
##
## @end deftypefn

function [results, multiSFTs, multiTser] = DoFstatInjections(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"ref_time", "real,strictpos,scalar"},
               {"start_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"det_sqrt_PSD", "real,positive,vector,+atmostone:inj_sqrt_PSD", []},
               {"ephemerides", "a:swig_ref", []},
               {"sft_time_span", "real,strictpos,scalar", 1800},
               {"sft_overlap", "real,positive,scalar", 0},
               {"sft_noise_window", "integer,strictpos,scalar", 50},
               {"inj_sqrt_PSD", "real,positive,vector,+atmostone:det_sqrt_PSD", []},
               {"inj_h0", "real,positive,scalar", 1.0},
               {"inj_cosi", "real,scalar", -1 + 2*rand()},
               {"inj_psi", "real,scalar", 2*pi*rand()},
               {"inj_phi0", "real,scalar", 2*pi*rand()},
               {"inj_alpha", "real,scalar", 2*pi*rand()},
               {"inj_delta", "real,scalar", asin(-1 + 2*rand())},
               {"inj_fndot", "real,vector", [100]},
               {"sch_alpha", "real,vector", []},
               {"sch_delta", "real,vector", []},
               {"sch_fndot", "real,matrix", []},
               {"OrbitParams", "logical,scalar", false},
               {"inj_orbitasini", "real,scalar", unifrnd(1.0,3.0)},
               {"inj_orbitEcc", "real,scalar", unifrnd(0.0,1.0)},
               {"inj_orbitTpSSB", "real,strictpos,scalar", unifrnd(6e8,6.5e8)},
               {"inj_orbitPeriod", "real,scalar", unifrnd(3600.0,86400.0)},
               {"inj_orbitArgp", "real,scalar", unifrnd(0.0,2*pi)},
               {"sch_orbitasini", "real,vector", []},
               {"sch_orbitEcc", "real,vector", []},
               {"sch_orbitTpSSB", "real,vector", []},
               {"sch_orbitPeriod", "real,vector", []},
               {"sch_orbitArgp", "real,vector", []},
               {"Dterms", "integer,strictpos,scalar", 8},
               {"randSeed", "integer,strictpos,scalar", floor(unifrnd(1, 2^32 - 1))},
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
  if OrbitParams
    if isempty(sch_orbitasini)
      sch_orbitasini = inj_orbitasini;
    endif
    if isempty(sch_orbitEcc)
      sch_orbitEcc = inj_orbitEcc;
    endif
    if isempty(sch_orbitTpSSB)
      sch_orbitTpSSB = inj_orbitTpSSB;
    endif
    if isempty(sch_orbitPeriod)
      sch_orbitPeriod = inj_orbitPeriod;
    endif
    if isempty(sch_orbitArgp)
      sch_orbitArgp = inj_orbitArgp;
    endif
  endif

  ## check options
  assert(size(inj_fndot, 2) == 1);
  assert(size(inj_fndot, 1) == size(sch_fndot, 1));
  num_sch = size(sch_fndot, 2);
  assert(num_sch > 0);
  assert(all(size(sch_alpha) == [1, num_sch]));
  assert(all(size(sch_delta) == [1, num_sch]));
  if OrbitParams
    assert(all(size(sch_orbitasini) == [1, num_sch]));
    assert(all(size(sch_orbitEcc) == [1, num_sch]));
    assert(all(size(sch_orbitTpSSB) == [1, num_sch]));
    assert(all(size(sch_orbitPeriod) == [1, num_sch]));
    assert(all(size(sch_orbitArgp) == [1, num_sch]));
  endif

  ## parse detector names and PSDs
  detNames = XLALCreateStringVector(strsplit(detectors, ","){:});
  if !isempty(det_sqrt_PSD)
    assumeSqrtSX = new_MultiNoiseFloor;
    assumeSqrtSX.length = detNames.length;
    assumeSqrtSX.sqrtSn(1:detNames.length) = det_sqrt_PSD;
  else
    assumeSqrtSX = [];
  endif
  if !isempty(inj_sqrt_PSD)
    injectSqrtSX = new_MultiNoiseFloor;
    injectSqrtSX.length = detNames.length;
    injectSqrtSX.sqrtSn(1:detNames.length) = inj_sqrt_PSD;
  else
    injectSqrtSX = [];
  endif

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
  if OrbitParams
    results.inj_orbitasini = inj_orbitasini;
    results.inj_orbitEcc = inj_orbitEcc;
    results.inj_orbitTpSSB = inj_orbitTpSSB;
    results.inj_orbitPeriod = inj_orbitPeriod;
    results.inj_orbitArgp = inj_orbitArgp;
    results.sch_orbitasini = sch_orbitasini;
    results.sch_orbitEcc = sch_orbitEcc;
    results.sch_orbitTpSSB = sch_orbitTpSSB;
    results.sch_orbitPeriod = sch_orbitPeriod;
    results.sch_orbitArgp = sch_orbitArgp;
  endif
  results.sch_twoF = zeros(1, num_sch);
  results.sch_twoFPerDet = zeros(detNames.length, num_sch);

  ## create and fill CW sources vector
  sources = XLALCreatePulsarParamsVector(1);
  sources.data{1}.Amp.h0   = inj_h0;
  sources.data{1}.Amp.cosi = inj_cosi;
  sources.data{1}.Amp.psi  = inj_psi;
  sources.data{1}.Amp.phi0 = inj_phi0;
  sources.data{1}.Doppler.Alpha = inj_alpha;
  sources.data{1}.Doppler.Delta = inj_delta;
  sources.data{1}.Doppler.fkdot = zeros(size(sources.data{1}.Doppler.fkdot));
  sources.data{1}.Doppler.fkdot(1:length(inj_fndot)) = inj_fndot;
  sources.data{1}.Doppler.refTime = refTime;
  if OrbitParams
    sources.data{1}.Doppler.asini = inj_orbitasini;
    sources.data{1}.Doppler.ecc = inj_orbitEcc;
    sources.data{1}.Doppler.tp = inj_orbitTpSSB;
    sources.data{1}.Doppler.period = inj_orbitPeriod;
    sources.data{1}.Doppler.argp = inj_orbitArgp;
  endif

  ## generate SFT timestamps
  multiTimestamps = XLALMakeMultiTimestamps(startTime, time_span, sft_time_span, sft_overlap, detNames.length);

  ## create fake SFT catalog, and determine end time
  fakeSFTcat = XLALMultiAddToFakeSFTCatalog([], detNames, multiTimestamps);
  endTime = fakeSFTcat.data{end-1}.header.epoch;

  ## work out the covering frequency band
  spinRange = new_PulsarSpinRange;
  spinRange.refTime = refTime;
  spinRange.fkdot = spinRange.fkdotBand = zeros(size(spinRange.fkdot));
  all_fndot = [inj_fndot, sch_fndot];
  spinRange.fkdot(1:length(inj_fndot)) = min(all_fndot, [], 2);
  spinRange.fkdotBand(1:length(inj_fndot)) = range(all_fndot, 2);
  if OrbitParams
    binary_max_asini  = max([inj_orbitasini, sch_orbitasini]);
    binary_min_period = min([inj_orbitPeriod, sch_orbitPeriod]);
    binary_max_ecc    = max([inj_orbitEcc, sch_orbitEcc]);
  else
    binary_max_asini = binary_min_period = binary_max_ecc = 0;
  endif
  [min_freq, max_freq] = XLALCWSignalCoveringBand(startTime, endTime, spinRange, binary_max_asini, binary_min_period, binary_max_ecc);
  results.SFT_min_freq = min_freq;
  results.SFT_max_freq = max_freq;

  ## setup F-statistic input struct
  optionalArgs = new_FstatOptionalArgs(lalpulsar.FstatOptionalArgsDefaults);
  optionalArgs.randSeed = randSeed;
  optionalArgs.Dterms = Dterms;
  optionalArgs.injectSources = sources;
  optionalArgs.injectSqrtSX = injectSqrtSX;
  optionalArgs.assumeSqrtSX = assumeSqrtSX;
  optionalArgs.runningMedianWindow = sft_noise_window;
  Fstatin = XLALCreateFstatInput ( fakeSFTcat, min_freq, max_freq, 0, ephemerides, optionalArgs );

  ## run ComputeFstat() for each injection point
  Fstatres = 0;
  Doppler = new_PulsarDopplerParams;
  for i = 1:num_sch

    ## fill input Doppler parameters struct for ComputeFstat()
    Doppler.Alpha = sch_alpha(i);
    Doppler.Delta = sch_delta(i);
    Doppler.fkdot = zeros(size(Doppler.fkdot));
    Doppler.fkdot(1:size(sch_fndot, 1)) = sch_fndot(:, i);
    Doppler.refTime = refTime;
    if OrbitParams
      Doppler.asini = sch_orbitasini(i);
      Doppler.ecc = sch_orbitEcc(i);
      Doppler.tp = sch_orbitTpSSB(i);
      Doppler.period = sch_orbitPeriod(i);
      Doppler.argp = sch_orbitArgp(i);
    endif

    ## run ComputeFstat() and return F-statistic values
    Fstatres = XLALComputeFstat ( Fstatres, Fstatin, Doppler, 1, FSTATQ_2F + FSTATQ_2F_PER_DET);
    results.sch_twoF(i) = Fstatres.twoF;
    for n = 1:size(results.sch_twoFPerDet, 1)
      results.sch_twoFPerDet(n, :) = reshape(Fstatres.twoFPerDet(n-1), 1, []);
    endfor

  endfor

endfunction

## common arguments for tests
%!shared common_args
%!  common_args = {"ref_time", 731163327, "start_time", 850468953, "time_span", 86400, "detectors", "H1,L1", ...
%!                 "sft_time_span", 1800, "sft_overlap", 0, "sft_noise_window", 50, ...
%!                 "inj_h0", 0.55, "inj_cosi", 0.31, "inj_psi", 0.22, "inj_phi0", 1.82, "inj_alpha", 3.92, ...
%!                 "inj_delta", 0.83, "inj_fndot", [200; 1e-9], "Dterms", 8, "randSeed", 1234};

## test isolated signal, no noise (but assumed PSD levels)
%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  res = DoFstatInjections(common_args{:}, "det_sqrt_PSD", 1.0, "OrbitParams", false);
%!  assert(res.inj_alpha == res.sch_alpha);
%!  assert(res.inj_delta == res.sch_delta);
%!  assert(res.inj_fndot == res.sch_fndot);
%!  ref_twoF = 4240.3; ref_twoFPerDet = [2314.9; 1925.4];
%!  assert(abs(res.sch_twoF - ref_twoF) < 0.05 * ref_twoF);
%!  assert(abs(res.sch_twoFPerDet - ref_twoFPerDet) < 0.05 * ref_twoFPerDet);

## test isolated signal, with Gaussian noise
%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  res = DoFstatInjections(common_args{:}, "inj_sqrt_PSD", 1.0, "OrbitParams", false);
%!  assert(res.inj_alpha == res.sch_alpha);
%!  assert(res.inj_delta == res.sch_delta);
%!  assert(res.inj_fndot == res.sch_fndot);
%!  ref_twoF = 4287.7; ref_twoFPerDet = [2245.4; 2045.1];
%!  assert(abs(res.sch_twoF - ref_twoF) < 0.05 * ref_twoF);
%!  assert(abs(res.sch_twoFPerDet - ref_twoFPerDet) < 0.05 * ref_twoFPerDet);

## test binary signal, no noise (but assumed PSD levels)
%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  res = DoFstatInjections(common_args{:}, "det_sqrt_PSD", 1.0, "OrbitParams", true, ...
%!                          "inj_orbitasini", 1e-5, "inj_orbitPeriod", 10800, ...
%!                          "inj_orbitEcc", 0, "inj_orbitTpSSB", 0.3, "inj_orbitArgp", 5.2);
%!  assert(res.inj_alpha == res.sch_alpha);
%!  assert(res.inj_delta == res.sch_delta);
%!  assert(res.inj_fndot == res.sch_fndot);
%!  assert(res.inj_orbitasini == res.sch_orbitasini);
%!  assert(res.inj_orbitEcc == res.sch_orbitEcc);
%!  assert(res.inj_orbitTpSSB == res.sch_orbitTpSSB);
%!  assert(res.inj_orbitPeriod == res.sch_orbitPeriod);
%!  assert(res.inj_orbitArgp == res.sch_orbitArgp);
%!  ref_twoF = 4240.3; ref_twoFPerDet = [2314.9; 1925.4];
%!  assert(abs(res.sch_twoF - ref_twoF) < 0.05 * ref_twoF);
%!  assert(abs(res.sch_twoFPerDet - ref_twoFPerDet) < 0.05 * ref_twoFPerDet);
