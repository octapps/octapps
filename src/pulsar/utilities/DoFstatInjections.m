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

## Perform full software injections in generated SFTs using LALPulsar functions.
##   [results, multiSFTs, multiTser] = DoFstatInjections("opt", val, ...)
##
## where:
##   result    = results structure
##   multiSFTs = multi-vector of SFTs containing simulated signal
##   multiTser = multi-time series vector containing simulated signal
## Options (starred options are returned in results):
##   ref_time: reference time in GPS seconds
##   start_time: start time in GPS seconds (default: ref_time - 0.5*time_span)
##   time_span: observation time-span in seconds
##   detectors: comma-separated list of detector names
##   detSqrtSn: vector of noise levels [as sqrt(single-sided PSD)] for each detector
##   ephemerides: Earth/Sun ephemerides from loadEphemerides()
##   sft_time_span: SFT time-span in seconds (default: 1800)
##   sft_overlap: SFT overlap in seconds (default: 0)
##   sft_band: SFT band-width in Hz (default: automatically determined)
##             - Minimum and maximum SFT frequencies SFT_min_freq and
##               SFT_max_freq are returned in results
##   sft_noise_window: number of bins used when estimating SFT noise (default: 50)
##  *inj_h0: injected h0 strain amplitude (default: 1.0)
##  *inj_cosi: injected cosine of inclination angle (default: random)
##  *inj_psi: injected polarisation angle (default: random)
##  *inj_phi0: injected initial phase (default: random)
##  *inj_alpha: injected right ascension (default: random)
##  *inj_delta: injected declination (default: random)
##  *inj_fndot: injected frequency/spindowns (default: 100 Hz)
##  *sch_alpha: searched right ascension (default: same as injected)
##  *sch_delta: searched declination (default: same as injected)
##  *sch_fndot: searched frequency/spindowns (default: same as injected)
##  OrbitParams: option that needs to be set to 'true' to be able to specify the orbital parameters (default: false)
##  *inj_orbitasini: injected orbital projected semi-major axis (normalised by the speed of light) in seconds (default: random)
##  *inj_orbitEcc: injected orbital eccentricity (default: random)
##  *inj_orbitTpSSB: injected (SSB) time of periapsis passage (in seconds) (default: random)
##  *inj_orbitPeriod: injected orbital period (seconds) (default: random)
##  *inj_orbitArgp: injected argument of periapsis (radians) (default: random)
##  *sch_orbitasini: searched orbital projected semi-major axis (normalised by the speed of light) in seconds (default: same as injected)
##  *sch_orbitEcc: searched orbital eccentricity (default: same as injected)
##  *sch_orbitTpSSB: searched (SSB) time of periapsis passage (in seconds) (default: same as injected)
##  *sch_orbitPeriod: searched orbital period (seconds) (default: same as injected)
##  *sch_orbitArgp: searched argument of periapsis (radians) (default: same as injected)
##  dopplermax: maximal possible doppler-effect (default: 1.05e-4)
##  Dterms: number of Dirichlet terms to use in ComputeFstat() (default: number used by optimised hotloops)
##  randSeed: seed used for generating random noise (default: generate random seed)

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
               {"detSqrtSn", "real,positive,vector", []},
               {"ephemerides", "a:swig_ref", []},
               {"sft_time_span", "real,strictpos,scalar", 1800},
               {"sft_overlap", "real,positive,scalar", 0},
               {"sft_band", "real,strictpos,scalar", []},
               {"sft_noise_window", "integer,strictpos,scalar", 50},
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
               {"dopplermax", "real,scalar",1.05e-4},
               {"Dterms", "integer,strictpos,scalar", lalpulsarcvar.OptimisedHotloopDterms},
               {"randSeed", "integer,strictpos,scalar", floor(unifrnd(0, 2^32 - 1))},
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

  ## parse detector names and check size of detSqrtSn
  detNames = CreateStringVector(strsplit(detectors, ","){:});
  if !isempty(detSqrtSn)
    assert(isscalar(detSqrtSn) || length(detSqrtSn) == detNames.length);
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
  if OrbitParams
    MFDsources.data{1}.Doppler.asini = inj_orbitasini;
    MFDsources.data{1}.Doppler.ecc = inj_orbitEcc;
    MFDsources.data{1}.Doppler.tp = inj_orbitTpSSB;
    MFDsources.data{1}.Doppler.period = inj_orbitPeriod;
    MFDsources.data{1}.Doppler.argp = inj_orbitArgp;
  endif

  ## generate SFT timestamps
  multiTimestamps = MakeMultiTimestamps(startTime, time_span, sft_time_span, sft_overlap, detNames.length);

  if isempty(sft_band)

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
    dfreq_orbitSourcePl = dopplermax * max_freq;
    max_freq += dfreq_orbitSourcePl;
    dfreq_orbitSourceMn = dopplermax * min_freq;
    min_freq -= dfreq_orbitSourceMn;

    ## add the minimum number of bins requires by ComputeFstat()
    min_freq -= Dterms / sft_time_span;
    max_freq += Dterms / sft_time_span;

    ## round frequencies down/up to nearest SFT bin, and add a few more bins for safety
    min_freq = (floor(min_freq * sft_time_span) - 5) / sft_time_span;
    max_freq = (floor(max_freq * sft_time_span) + 5) / sft_time_span;

  else

    ## use the supplied band around the injection frequency
    min_freq = inj_fndot(1,1) - 0.5*sft_band;
    max_freq = inj_fndot(1,1) + 0.5*sft_band;

  endif

  ## save frequency range in results
  results.SFT_min_freq = min_freq;
  results.SFT_max_freq = max_freq;

  ## create and fill input parameters struct for CWMakeFakeData()
  MFDparams = new_CWMFDataParams;
  MFDparams.fMin = min_freq;
  MFDparams.Band = max_freq - min_freq;
  ParseMultiLALDetector(MFDparams.multiIFO, detNames);
  MFDparams.multiNoiseFloor.length = detNames.length;
  if !isempty(detSqrtSn)
    MFDparams.multiNoiseFloor.sqrtSn(1:detNames.length) = detSqrtSn;
  endif
  MFDparams.multiTimestamps = multiTimestamps;
  MFDparams.randSeed = randSeed;

  ## run CWMakeFakeData() to generate SFTs with injections
  [multiSFTs, multiTser] = CWMakeFakeMultiData([], [], MFDsources, MFDparams, ephemerides);

  ## if SFTs contain noise, calculate noise weights
  if isempty(detSqrtSn)
    multiWeights = [];
  else
    SFTrngmed = NormalizeMultiSFTVect(multiSFTs, sft_noise_window);
    multiWeights = ComputeMultiNoiseWeights(SFTrngmed, sft_noise_window, 0);
    clear SFTrngmed;
  endif

  ## setup F-statistic input struct for ComputeFstat()
  Fstatin = SetupFstat_Demod(multiSFTs, multiWeights, ephemerides, SSBPREC_RELATIVISTICOPT, Dterms, lalpulsarcvar.DEMODHL_BEST);

  ## run ComputeFstat() for each injection point
  Fstatres = [];
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
    Fstatres = ComputeFstat(Fstatres, Fstatin, Doppler, 0, 1, FSTATQ_2F + FSTATQ_2F_PER_DET);
    results.sch_twoF(i) = Fstatres.twoF;
    for n = 1:size(results.sch_twoFPerDet, 1)
      results.sch_twoFPerDet(n, :) = reshape(Fstatres.twoFPerDet(n-1), 1, []);
    endfor

  endfor

endfunction

%!shared common_args
%! common_args = {"ref_time", 731163327, "start_time", 850468953, "time_span", 86400, "detectors", "H1,L1", "detSqrtSn", 1.0, "sft_time_span", 1800, ...
%!                "sft_overlap", 0, "sft_noise_window", 50, "inj_h0", 0.55, "inj_cosi", 0.31, "inj_psi", 0.22, "inj_phi0", 1.82, "inj_alpha", 3.92, ...
%!                "inj_delta", 0.83, "inj_fndot", [200; 1e-9], "Dterms", 8, "randSeed", 1234};

%!test
%! try
%!   lal; lalpulsar;
%! catch
%!   disp("*** LALSuite modules not available; skipping test ***"); return;
%! end_try_catch
%! res = DoFstatInjections(common_args{:}, "OrbitParams", false);
%! assert(res.inj_alpha == res.sch_alpha);
%! assert(res.inj_delta == res.sch_delta);
%! assert(res.inj_fndot == res.sch_fndot);
%! ref_twoF = 4089.4; ref_twoFPerDet = [2273.0; 1820.7];
%! assert(abs(res.sch_twoF - ref_twoF) < 0.05 * ref_twoF);
%! assert(abs(res.sch_twoFPerDet - ref_twoFPerDet) < 0.05 * ref_twoFPerDet);

%!test
%! try
%!   lal; lalpulsar;
%! catch
%!   disp("*** LALSuite modules not available; skipping test ***"); return;
%! end_try_catch
%! res = DoFstatInjections(common_args{:}, "OrbitParams", true, "inj_orbitasini", 2.94, "inj_orbitPeriod", 10800, ...
%!                         "inj_orbitEcc", 0, "inj_orbitTpSSB", 1/3, "inj_orbitArgp", 5.2, "dopplermax", 2e-3);
%! assert(res.inj_alpha == res.sch_alpha);
%! assert(res.inj_delta == res.sch_delta);
%! assert(res.inj_fndot == res.sch_fndot);
%! assert(res.inj_orbitasini == res.sch_orbitasini);
%! assert(res.inj_orbitEcc == res.sch_orbitEcc);
%! assert(res.inj_orbitTpSSB == res.sch_orbitTpSSB);
%! assert(res.inj_orbitPeriod == res.sch_orbitPeriod);
%! assert(res.inj_orbitArgp == res.sch_orbitArgp);
%! ref_twoF = 15.798; ref_twoFPerDet = [2.1192; 20.6255];
%! assert(abs(res.sch_twoF - ref_twoF) < 0.05 * ref_twoF);
%! assert(abs(res.sch_twoFPerDet - ref_twoFPerDet) < 0.05 * ref_twoFPerDet);
