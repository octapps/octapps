## Copyright (C) 2015 Karl Wette
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

## Return computing-cost functions and other parameters used by
## OptimalSolution4StackSlide() to compute optimal Einstein@Home
## search setups using the reduced supersky metric.
## Usage:
##   [cost_funs, params, guess] = CostFunctionsEaHSupersky("setup", "opt", val, ...)
## where
##   cost_funs = struct of computing-cost functions to pass to OptimalSolution4StackSlide()
##   params    = associated parameters, some of which are passed to OptimalSolution4StackSlide()
##   guess     = initial guess at solution to pass to OptimalSolution4StackSlide()
##   setup     = string name of previous E@H search on which to base search setup
## Search setup options:
##   "cost0":                total computing cost (in CPU seconds)
##   "TobsMax":              constraint on maximum total observation time [default: 1 year]
##   "ref_time":             reference time at which to compute metrics
##   "freq":                 frequency at which to compute metrics and parameter-space
##   "fkdot_bands":          frequency and spindown bandwidths
##   "detectors":            detectors to use when computing metrics and coherent cost
##   "det_motion":           type of detector motion [default: "spin+orbit", i.e. full ephemeris]
##   "total_Tspan":          total time span of segment list [default: 1 year]
##   "coh_duty":             duty cycle of data within each coherent segment [default: 1.0]
##   "inc_duty":             duty cycle of segments within total time spanned by segment list
##   "resampling":           use F-statistic 'resampling' instead of 'demod' timings for coherent cost [default: false]
##   "lattice":              template-bank lattice ("Zn", "Ans",..) [default: "Ans"]
##   "coh_c0_demod":         computational cost of F-statistic 'demod' per template per second [optional]
##   "coh_c0_resamp":        computational cost of F-statistic 'resampling' per template [optional]
##   "inc_c0":               computational cost of incoherent step per template per segment [optional]
##   "grid_interpolation":   whether to use interpolating or non-interpolating StackSlide (ie coarse-grids == fine-grid)
## Other options:
##   "verbose":              computing-cost functions print info messages when called [default: false]
##
function [cost_funs, params, guess] = CostFunctionsEaHSupersky(setup, varargin)

  ## load modules
  lal;
  lalpulsar;
  UnitsConstants;

  ## get default parameters and search setup
  params = guess = struct;
  switch setup

    case "S5R5"         ## E@H run 'S5R5_IV' parameters, from https://wiki.ligo.org/CW/SettingUpS5R4

      params.cost0 = 6*HOURS * 3;                  ## tauWU * min(numSkyPatches)
      params.TobsMax = 121 * 25*HOURS;             ## Nstack * Tstack

      params.freq = 50;                            ## FreqMin
      params.fkdot_bands(1) = 0.02079;             ## FreqBand
      params.fkdot_bands(2) = 2.2e-9;              ## f1dotBand
      params.detectors = "H1,L1";
      params.resampling = false;
      params.coh_c0_demod = 1.8e-07 / 1800;        ## tauF0 / Tsft
      params.inc_c0 = 6.135e-9;                    ## tauG0 from "S5GC1" (below)

      ## from gitmaster.atlas.aei.uni-hannover.de:einsteinathome/run-design-gw.git, commit 839be7c
      ## > props = AnalyseSegmentList(load("S5R5/AnalysisSegmentsS5R4.txt"), 2);
      params.ref_time = 864165816;                 ## props.mean_time
      params.coh_duty = 0.87364;                   ## mean(props.coh_duty)
      params.inc_duty = 0.47636;                   ## props.inc_duty
      params.total_Tspan = 22836793;               ## props.inc_Tspan

      guess.Nseg = 126.041666666667;
      guess.Tseg = 86400;
      guess.mc = 0.224885317242746;
      guess.mf = 3.797731029707;

    case "S5GC1"        ## E@H run 'S5GC1' parameters, from https://wiki.ligo.org/CW/EaHsetupS5GCE

      params.cost0 = 6*HOURS * 3;                  ## tauWU * min(numSkyPatches)
      params.TobsMax = 205 * 25*HOURS;             ## Nstack * Tstack

      params.freq = 50;                            ## FreqMin
      params.fkdot_bands(1) = 0.05;                ## FreqBand
      params.fkdot_bands(2) = 2.91e-09;            ## f1dotBand
      params.detectors = "H1,L1";
      params.resampling = false;
      params.coh_c0_demod = 7.215e-08 / 1800;      ## tauF0 / Tsft
      params.inc_c0 = 6.135e-09;                   ## tauG0

      ## from gitmaster.atlas.aei.uni-hannover.de:einsteinathome/run-design-gw.git, commit 839be7c
      ## > props = AnalyseSegmentList(load("S5RunsGC/AnalysisSegmentsS5R3u4.txt"), 2);
      params.ref_time = 853516276;                 ## props.mean_time
      params.coh_duty = 0.86892;                   ## mean(props.coh_duty)
      params.inc_duty = 0.32663;                   ## props.inc_duty
      params.total_Tspan = 56435059;               ## props.inc_Tspan

      guess.Nseg = 213.541666666667;
      guess.Tseg = 86400;
      guess.mc = 0.553338076176338;
      guess.mf = 27.3041066881259;

    case "S6Bucket"     ## E@H run 'S6Bucket' parameters, from https://wiki.ligo.org/CW/EaHsetupS6Bucket

      params.cost0 = 6*HOURS * 51;                 ## tauWU * min(numSkyPatches)
      params.TobsMax = 90 * 60*HOURS;              ## Nstack * Tstack

      params.freq = 50;                            ## FreqMin
      params.fkdot_bands(1) = 0.05;                ## FreqBand
      params.fkdot_bands(2) = 2.91e-09;            ## f1dotBand
      params.detectors = "H1,L1";
      params.resampling = false;
      params.coh_c0_demod = 7.4e-08 / 1800;        ## tauF0 / Tsft
      params.inc_c0 = 4.7e-09;                     ## tauG0

      ## from gitmaster.atlas.aei.uni-hannover.de:einsteinathome/run-design-gw.git, commit 839be7c
      ## > props = AnalyseSegmentList(load("S6Bucket+LV/S6GC1_T60h_v1_Segments.seg"), 2);
      params.ref_time = 960733655;                 ## props.mean_time
      params.coh_duty = 0.57955;                   ## mean(props.coh_duty)
      params.inc_duty = 0.84395;                   ## props.inc_duty
      props.total_Tspan = 22059873;                ## props.inc_Tspan

      guess.Nseg = 225;
      guess.Tseg = 86400;
      guess.mc = 0.0992523850405064;
      guess.mf = 3.69093754566403;

    otherwise
      error("%s: unknown default setup '%s'", funcName, name);

  endswitch

  ## parse options
  params = parseOptions(varargin,
                        params_optspec(params, "cost0", "real,strictpos,scalar"),
                        params_optspec(params, "TobsMax", "real,strictpos,scalar", 1.0*YEARS),
                        params_optspec(params, "ref_time", "real,strictpos,scalar"),
                        params_optspec(params, "freq", "real,strictpos,scalar"),
                        params_optspec(params, "fkdot_bands", "real,strictpos,vector"),
                        params_optspec(params, "detectors", "char"),
                        params_optspec(params, "det_motion", "char", "spin+orbit"),
                        params_optspec(params, "total_Tspan", "real,strictpos,scalar", 1.0*YEARS),
                        params_optspec(params, "coh_duty", "real,strictpos,scalar", 1.0),
                        params_optspec(params, "inc_duty", "real,strictpos,scalar", 1.0),
                        params_optspec(params, "resampling", "logical,scalar", false),
                        params_optspec(params, "lattice", "char", "Ans"),
                        params_optspec(params, "coh_c0_demod", "real,strictpos,scalar", 7.4e-08 / 1800),
                        params_optspec(params, "coh_c0_resamp", "real,strictpos,scalar", 2.8e-7),
                        params_optspec(params, "inc_c0", "real,strictpos,scalar", 4.7e-09),
                        params_optspec(params, "grid_interpolation", "logical,scalar", true),
                        {"verbose", "logical,scalar", false},
                        []);

  ## make closures of functions with 'params'
  cost_funs = struct( ...
                     "costFunCoh", @(Nseg, Tseg, mc=0.5) cost_coh_wparams(Nseg, Tseg, mc, params), ...
                     "costFunInc", @(Nseg, Tseg, mf=0.5) cost_inc_wparams(Nseg, Tseg, mf, params) ...
                     );

endfunction

function optspec = params_optspec(params, name, type, defvalue=[])
  if isfield(params, name)
    optspec = {name, type, getfield(params, name)};
  elseif !isempty(defvalue)
    optspec = {name, type, defvalue};
  else
    optspec = {name, type};
  endif
endfunction

function Nt = rssky_num_templates(Nseg, Tseg, mis, params)

  ## do not page output
  pso = page_screen_output(0, "local");

  ## load modules
  UnitsConstants;

  ## check input
  assert(isscalar(Nseg) && Nseg >= 0.95);
  assert(isscalar(Tseg) && Tseg > 0);
  assert(isscalar(mis) && mis > 0);
  assert(ischar(params.lattice));
  assert(isstruct(params));

  ## minimum computable value for Tseg
  Tseg_min = 0.95*DAYS;
  assert(Tseg >= Tseg_min, "%s: Tseg=%g days is less than minimum=%g days", funcName(), Tseg/DAYS, Tseg_min/DAYS);

  ## only keep parameters needed to compute metrics
  verbose = params.verbose;
  lattice = params.lattice;
  params = struct( ...
                  "ref_time", params.ref_time, ...
                  "freq", params.freq, ...
                  "fkdot_bands", params.fkdot_bands, ...
                  "inc_duty", params.inc_duty, ...
                  "total_Tspan", params.total_Tspan, ...
                  "detectors", params.detectors, ...
                  "det_motion", params.det_motion ...
                  );

  ## cached ephemerides
  persistent ephemerides;
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## cache of previously-computed metrics
  persistent cache;
  if isempty(cache)
    cache = struct;
  endif

  ## loop up cache based on hash of stringified parameters
  param_str = stringify(params);
  cache_key = strcat("key_", md5sum(param_str, true));
  if !isfield(cache, cache_key)
    cache.(cache_key) = struct;
    cache.(cache_key).param_str = "";
  endif
  if !strcmp(param_str, cache.(cache_key).param_str)
    cache.(cache_key).param_str = param_str;
    cache.(cache_key).metrics = {};
    if verbose
      printf("(new cache) ");
    endif
  endif

  ## metric cache indices and interpolation grid
  Nseg_ii = unique(max(1, round(Nseg) + (-1:1)));
  Nseg_interp = Nseg_ii;

  ## Tseg metric cache indices and interpolation grid
  Tseg_step = 0.25*DAYS;
  Tseg_jj = unique(max(1, round(Tseg / Tseg_step) + (-1:1)));
  Tseg_interp = max(Tseg_min, Tseg_jj * Tseg_step);

  ## compute interpolation grid for number of templates
  Nt_interp = zeros(length(Nseg_interp), length(Tseg_interp));
  cache_hits = 0;
  for i = 1:length(Nseg_interp)
    for j = 1:length(Tseg_interp)

      ## try to find metric in cache
      if all([Nseg_ii(i), Tseg_jj(j)] <= size(cache.(cache_key).metrics)) && !isempty(cache.(cache_key).metrics{Nseg_ii(i), Tseg_jj(j)})

        ## retrieve metric from cache
        rssky_metric = cache.(cache_key).metrics{Nseg_ii(i), Tseg_jj(j)};
        ++cache_hits;

      else

        ## create segment list
        segment_list = CreateSegmentList(params.ref_time, Nseg_interp(i), Tseg_interp(j), [], params.inc_duty);

        ## compute metric
        rssky_metric = CreateSuperskyMetrics(
                                             "spindowns", length(params.fkdot_bands) - 1,
                                             "segment_list", segment_list,
                                             "ref_time", params.ref_time,
                                             "fiducial_freq", params.freq + params.fkdot_bands(1),
                                             "detectors", params.detectors,
                                             "detector_motion", params.det_motion,
                                             "ephemerides", ephemerides
                                             );

        ## add metric to cache
        cache.(cache_key).metrics{Nseg_ii(i), Tseg_jj(j)} = rssky_metric;

      endif

      ## compute number of templates
      fkdot_param_space = abs([params.fkdot_bands(2:end); params.fkdot_bands(1)]);
      Nt_interp(i, j) = NumberOfLatticeBankTemplates(
                                                     "lattice", lattice,
                                                     "metric", rssky_metric,
                                                     "max_mismatch", mis,
                                                     "param_space", {"rssky", fkdot_param_space},
                                                     "padding", false
                                                     );

    endfor
  endfor
  if verbose && cache_hits > 0
    printf("(%i/%i cache hits) ", cache_hits, numel(Nt_interp));
  endif

  ## compute interpolated number of templates at requested Nseg and Tseg
  Nt = interp2(Tseg_interp, Nseg_interp, Nt_interp, Tseg, max(1, Nseg), "spline");
  assert(!isnan(Nt), "%s: could not evaluate Nt(Nseg=%g, Tseg=%g)", funcName, Nseg, Tseg);

endfunction

function [cost, Ntc, lattice] = cost_coh_wparams(Nseg, Tseg, mc, params)

  ## do not page output
  pso = page_screen_output(0, "local");

  ## load modules
  UnitsConstants;

  ## check input parameters
  [err, Nseg, Tseg, mc] = common_size(Nseg, Tseg, mc);
  assert(err == 0);

  ## number of detectors
  Ndet = length(strsplit(params.detectors, ","));

  for i = 1:length(Nseg(:))

    ## print progress message
    if params.verbose
      printf("cost_coh( Nseg=%g, Tseg=%g days, mc=%g ) = ", Nseg(i), Tseg(i)/DAYS, mc(i));
    endif

    if params.resampling
      ## resampling cost per template, assuming "enough" frequency bins
      c0T = params.coh_c0_resamp * Ndet;
    else
      ## demod cost per template
      c0T = params.coh_c0_demod * Ndet * params.coh_duty * Tseg(i);
    endif

    ## number of templates per segment
    if ( params.grid_interpolation )
      Ntc(i) = rssky_num_templates(1, Tseg(i), mc(i), params);
    else
      Ntc(i) = rssky_num_templates(Nseg(i), Tseg(i), mc(i), params);
    endif

    ## total coherent cost
    cost(i) = Nseg(i) * Ntc(i) * c0T;

    ## print progress message
    if params.verbose
      printf("%0.4e\n", cost(i));
    endif

  endfor

  ## return type of lattice
  lattice = params.lattice;

endfunction

function [cost, Ntf, lattice] = cost_inc_wparams(Nseg, Tseg, mf, params)

  ## do not page output
  pso = page_screen_output(0, "local");

  ## load modules
  UnitsConstants;

  ## check input parameters
  [err, Nseg, Tseg, mf] = common_size(Nseg, Tseg, mf);
  assert(err == 0);

  for i = 1:length(Nseg(:))

    ## print progress message
    if params.verbose
      printf("cost_inc( Nseg=%g, Tseg=%g days, mf=%g ) = ", Nseg(i), Tseg(i)/DAYS, mf(i));
    endif

    ## incoherent cost per template
    c0T = params.inc_c0 * Nseg(i);

    ## number of templates
    Ntf(i) = rssky_num_templates(Nseg(i), Tseg(i), mf(i), params);

    ## total incoherent cost
    cost(i) = Ntf(i) * c0T;

    ## print progress message
    if params.verbose
      printf("%0.4e\n", cost(i));
    endif

  endfor

  ## return type of lattice
  lattice = params.lattice;

endfunction


%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  [cost_funs, params, guess] = CostFunctionsEaHSupersky("S5R5", "verbose", true);
%!  cost_c = 3.622659282697512e+03; cost_f = 6.117734023987012e+04;
%!  assert(abs(cost_funs.costFunCoh(guess.Nseg, guess.Tseg, guess.mc) - cost_c) < 1e-6);
%!  assert(abs(cost_funs.costFunInc(guess.Nseg, guess.Tseg, guess.mf) - cost_f) < 1e-6);
%!  sp = OptimalSolution4StackSlide("costFuns", cost_funs, ...
%!                                  "cost0", params.cost0, ...
%!                                  "TobsMax", params.TobsMax, ...
%!                                  "TsegMin", 86400, ...
%!                                  "stackparamsGuess", guess, "verbose", true);
%!  assert(abs(sp.coef_c.cost - cost_c) < 1e-6);
%!  assert(abs(sp.coef_f.cost - cost_f) < 1e-6);

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  [cost_funs, params, guess] = CostFunctionsEaHSupersky("S5GC1", "verbose", true);
%!  cost_c = 1.287135543221262e+03; cost_f = 6.351286439032721e+04;
%!  assert(abs(cost_funs.costFunCoh(guess.Nseg, guess.Tseg, guess.mc) - cost_c) < 1e-6);
%!  assert(abs(cost_funs.costFunInc(guess.Nseg, guess.Tseg, guess.mf) - cost_f) < 1e-6);
%!  sp = OptimalSolution4StackSlide("costFuns", cost_funs, ...
%!                                  "cost0", params.cost0, ...
%!                                  "TobsMax", params.TobsMax, ...
%!                                  "TsegMin", 86400, ...
%!                                  "stackparamsGuess", guess, "verbose", true);
%!  assert(abs(sp.coef_c.cost - cost_c) < 1e-6);
%!  assert(abs(sp.coef_f.cost - cost_f) < 1e-6);

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  [cost_funs, params, guess] = CostFunctionsEaHSupersky("S6Bucket", "verbose", true);
%!  cost_c = 2.884721571610171e+04; cost_f = 1.072752775973491e+06;
%!  assert(abs(cost_funs.costFunCoh(guess.Nseg, guess.Tseg, guess.mc) - cost_c) < 1e-6);
%!  assert(abs(cost_funs.costFunInc(guess.Nseg, guess.Tseg, guess.mf) - cost_f) < 1e-6);
%!  sp = OptimalSolution4StackSlide("costFuns", cost_funs, ...
%!                                  "cost0", params.cost0, ...
%!                                  "TobsMax", params.TobsMax, ...
%!                                  "TsegMin", 86400, ...
%!                                  "stackparamsGuess", guess, "verbose", true);
%!  assert(abs(sp.coef_c.cost - cost_c) < 1e-6);
%!  assert(abs(sp.coef_f.cost - cost_f) < 1e-6);
