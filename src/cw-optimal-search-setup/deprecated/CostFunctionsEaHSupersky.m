## Copyright (C) 2017 Reinhard Prix
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
## Search setup options [defaults: given by "setup"]:
##   "cost0":                total computing cost, in CPU seconds
##   "TobsMax":              constraint on maximum total observation time, in seconds
##   "ref_time":             reference time at which to compute metrics, in GPS seconds
##   "freq":                 frequency at which to compute metrics and parameter-space, in Hz
##   "fkdot_bands":          frequency and spindown bandwidths, in Hz/s^k
##   "detectors":            CSV list of detectors to use when computing metrics and coherent cost (e.g. "H1,L1,...")
##   "coh_duty":             duty cycle of data within each coherent segment
##   "inc_duty":             duty cycle of segments within total time spanned by segment list
##   "resampling":           use F-statistic 'resampling' instead of 'demod' timings for coherent cost [default: false]
##   "coh_c0_demod":         computational cost of F-statistic 'demod' per template per second
##   "coh_c0_resamp":        computational cost of F-statistic 'resampling' per template
##   "inc_c0":               computational cost of incoherent step per template per segment
## Other options:
##   "det_motion":           type of detector motion [default: "spin+orbit", i.e. full ephemeris]
##   "lattice":              template-bank lattice ("Zn", "Ans",..) [default: "Ans"]
##   "grid_interpolation":   whether to use interpolating or non-interpolating StackSlide, i.e. coherent grids equal incoherent grid [default: true]
##   "debugLevel":           control level of debug output [default: 0]
function [cost_funs, params, guess] = CostFunctionsEaHSupersky(setup, varargin)

  ## load modules
  lal;
  lalpulsar;
  UnitsConstants;

  ## get default parameters and search setup
  defpar = guess = struct;
  switch setup

    case "S5R5"         ## E@H run 'S5R5_IV' parameters, from https://wiki.ligo.org/CW/SettingUpS5R4

      defpar.cost0 = 6*HOURS * 3;                  ## tauWU * min(numSkyPatches)
      defpar.Nseg = 121;                           ## Nstack
      defpar.Tseg = 25*HOURS;                      ## Tstack

      defpar.freq = 50;                            ## FreqMin
      defpar.fkdot_bands(1) = 0.02079;             ## FreqBand
      defpar.fkdot_bands(2) = 2.2e-9;              ## f1dotBand
      defpar.detectors = "H1,L1";
      defpar.coh_c0_demod = 1.8e-07 / 1800;        ## tauF0 / Tsft
      defpar.inc_c0 = 6.135e-9;                    ## tauG0 from "S5GC1" (below)

      defpar.resampling = false;
      defpar.coh_c0_resamp = 2.8e-7;

      ## from gitmaster.atlas.aei.uni-hannover.de:einsteinathome/run-design-gw.git, commit 839be7c
      ## > props = AnalyseSegmentList(load("S5R5/AnalysisSegmentsS5R4.txt"), 2);
      defpar.ref_time = 864165816;                 ## props.mean_time
      defpar.coh_duty = 0.87364;                   ## mean(props.coh_duty)
      defpar.inc_duty = 0.47636;                   ## props.inc_duty

      guess.EaH_Nseg = defpar.Nseg;
      guess.EaH_Tseg = defpar.Tseg;

      guess.Nseg = 126.041666666667;
      guess.Tseg = 86400;
      guess.mCoh = 0.225075907869835;
      guess.mInc = 3.80777662870061;
      guess.costCoh = 3.616526662088050e+03;
      guess.costInc = 6.118347286167773e+04;

    case "S5GC1"        ## E@H run 'S5GC1' parameters, from https://wiki.ligo.org/CW/EaHsetupS5GCE

      defpar.cost0 = 6*HOURS * 3;                  ## tauWU * min(numSkyPatches)
      defpar.Nseg = 205;                           ## Nstack
      defpar.Tseg = 25*HOURS;                      ## Tstack

      defpar.freq = 50;                            ## FreqMin
      defpar.fkdot_bands(1) = 0.05;                ## FreqBand
      defpar.fkdot_bands(2) = 2.91e-09;            ## f1dotBand
      defpar.detectors = "H1,L1";
      defpar.coh_c0_demod = 7.215e-08 / 1800;      ## tauF0 / Tsft
      defpar.inc_c0 = 6.135e-09;                   ## tauG0

      defpar.resampling = false;
      defpar.coh_c0_resamp = 2.8e-7;

      ## from gitmaster.atlas.aei.uni-hannover.de:einsteinathome/run-design-gw.git, commit 839be7c
      ## > props = AnalyseSegmentList(load("S5RunsGC/AnalysisSegmentsS5R3u4.txt"), 2);
      defpar.ref_time = 853516276;                 ## props.mean_time
      defpar.coh_duty = 0.86892;                   ## mean(props.coh_duty)
      defpar.inc_duty = 0.32663;                   ## props.inc_duty

      guess.EaH_Nseg = defpar.Nseg;
      guess.EaH_Tseg = defpar.Tseg;

      guess.Nseg = 213.541666666667;
      guess.Tseg = 86400;
      guess.mCoh = 0.553416808369889;
      guess.mInc = 27.3159208108329;
      guess.costCoh = 1.286769338961998e+03;
      guess.costInc = 6.351323059461516e+04;

    case "S6Bucket"     ## E@H run 'S6Bucket' parameters, from https://wiki.ligo.org/CW/EaHsetupS6Bucket

      defpar.cost0 = 6*HOURS * 51;                 ## tauWU * min(numSkyPatches)
      defpar.Nseg = 90;                            ## Nstack
      defpar.Tseg = 60*HOURS;                      ## Tstack

      defpar.freq = 50;                            ## FreqMin
      defpar.fkdot_bands(1) = 0.05;                ## FreqBand
      defpar.fkdot_bands(2) = 2.91e-09;            ## f1dotBand
      defpar.detectors = "H1,L1";
      defpar.coh_c0_demod = 7.4e-08 / 1800;        ## tauF0 / Tsft
      defpar.inc_c0 = 4.7e-09;                     ## tauG0

      defpar.resampling = false;
      defpar.coh_c0_resamp = 2.8e-7;

      ## from gitmaster.atlas.aei.uni-hannover.de:einsteinathome/run-design-gw.git, commit 839be7c
      ## > props = AnalyseSegmentList(load("S6Bucket+LV/S6GC1_T60h_v1_Segments.seg"), 2);
      defpar.ref_time = 960733655;                 ## props.mean_time
      defpar.coh_duty = 0.57955;                   ## mean(props.coh_duty)
      defpar.inc_duty = 0.84395;                   ## props.inc_duty

      guess.EaH_Nseg = defpar.Nseg;
      guess.EaH_Tseg = defpar.Tseg;

      guess.Nseg = 225;
      guess.Tseg = 86400;
      guess.mCoh = 0.0801888897004475;
      guess.mInc = 1.91866346519774;
      guess.costCoh = 4.419339894056540e+04;
      guess.costInc = 1.057406584954869e+06;

    otherwise
      error("%s: unknown default setup '%s'", funcName, setup);

  endswitch

  ## parse options
  params = parseOptions(varargin,
                        {"cost0", "real,strictpos,scalar", defpar.cost0},
                        {"TobsMax", "real,strictpos,scalar", defpar.Nseg * defpar.Tseg},
                        {"ref_time", "real,strictpos,scalar", defpar.ref_time},
                        {"freq", "real,strictpos,scalar", defpar.freq},
                        {"fkdot_bands", "real,strictpos,vector", defpar.fkdot_bands},
                        {"detectors", "char", defpar.detectors},
                        {"coh_duty", "real,strictpos,scalar", defpar.coh_duty},
                        {"inc_duty", "real,strictpos,scalar", defpar.inc_duty},
                        {"resampling", "logical,scalar", defpar.resampling},
                        {"coh_c0_demod", "real,strictpos,scalar", defpar.coh_c0_demod},
                        {"coh_c0_resamp", "real,strictpos,scalar", defpar.coh_c0_resamp},
                        {"inc_c0", "real,strictpos,scalar", defpar.inc_c0},
                        [],
                        {"det_motion", "char", "spin+orbit"},
                        {"lattice", "char", "Ans"},
                        {"grid_interpolation", "logical,scalar", true},
                        {"debugLevel", "integer,positive,scalar", 0},
                        []);
  clear defpar;
  global debugLevel; debugLevel = params.debugLevel;

  ## make closures of functions with 'params'
  cost_funs = struct( "grid_interpolation", params.grid_interpolation, ...
                      "lattice", params.lattice, ...
                      "f", @(Nseg, Tseg, mCoh=0.5, mInc=0.5) cost_wparams(Nseg, Tseg, mCoh, mInc, params) ...
                    );

endfunction

function Nt = rssky_num_templates(Nseg, Tseg, mis, params, padding)

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
  lattice = params.lattice;
  metric_params = struct( ...
                          "ref_time", params.ref_time, ...
                          "freq", params.freq, ...
                          "fkdot_bands", params.fkdot_bands, ...
                          "inc_duty", params.inc_duty, ...
                          "detectors", params.detectors, ...
                          "det_motion", params.det_motion ...
                        );

  ## metric cache indices and interpolation grid
  Nseg_ii = unique(max(1, round(Nseg) + (-1:1)));
  Nseg_interp = Nseg_ii;

  ## Tseg metric cache indices and interpolation grid
  Tseg_step = 0.25*DAYS;
  Tseg_jj = unique(max(1, round(Tseg / Tseg_step) + (-1:1)));
  Tseg_interp = max(Tseg_min, Tseg_jj * Tseg_step);

  ## compute interpolation grid for number of templates
  Nt_interp = zeros(length(Nseg_interp), length(Tseg_interp));
  for i = 1:length(Nseg_interp)
    for j = 1:length(Tseg_interp)

      ## create segment list
      segment_list = CreateSegmentList(metric_params.ref_time, Nseg_interp(i), Tseg_interp(j), [], metric_params.inc_duty);

      ## compute metric
      DebugPrintf( 3, "%s: computing metrics for Nseg=%g, Tseg=%g ... ", funcName, Nseg_interp(i), Tseg_interp(j));
      metrics = ComputeSuperskyMetrics(
                    "spindowns", length(metric_params.fkdot_bands) - 1,
                    "segment_list", segment_list,
                    "ref_time", metric_params.ref_time,
                    "fiducial_freq", metric_params.freq + metric_params.fkdot_bands(1),
                    "detectors", metric_params.detectors,
                    "detector_motion", metric_params.det_motion
                  );
      DebugPrintf ( 3, "done\n");
      rssky_metric = native(metrics.semi_rssky_metric);

      ## calculate bounding box of metric
      if padding
        bbox_metric = reshape(metricBoundingBox(rssky_metric, max_mismatch), [], 1);
      else
        bbox_metric = zeros(size(rssky_metric, 1), 1);
      endif

      ## calculate parameter-space volume
      vol = 2 * (pi + 4*bbox_metric(2) + bbox_metric(1)*bbox_metric(2));
      vol *= prod(reshape(abs(metric_params.fkdot_bands), [], 1) + bbox_metric(3:end));

      ## compute number of templates
      Nt_interp(i, j) = NumberOfLatticeBankTemplates(
                                                     "lattice", lattice,
                                                     "metric", rssky_metric,
                                                     "max_mismatch", mis,
                                                     "param_vol", vol
                                                     );

    endfor
  endfor

  ## compute interpolated number of templates at requested Nseg and Tseg
  Nt = interp2(Tseg_interp, Nseg_interp, Nt_interp, Tseg, max(1, Nseg), "spline");
  assert(!isnan(Nt), "%s: could not evaluate Nt(Nseg=%g, Tseg=%g)", funcName, Nseg, Tseg);

endfunction

function [costCoh, costInc] = cost_wparams(Nseg, Tseg, mCoh, mInc, params)
  ## coherent + incoherent cost functions

  ## do not page output
  pso = page_screen_output(0, "local");

  ## check input parameters
  [err, Nseg, Tseg, mCoh, mInc] = common_size(Nseg, Tseg, mCoh, mInc);
  assert(err == 0);

  if ( ! params.grid_interpolation )
    assert ( isempty ( mCoh ) || ( mCoh == mInc ) );
  endif

  ## number of detectors
  Ndet = length(strsplit(params.detectors, ","));
  costCoh = costInc = NtCoh = NtInc = zeros ( size ( Nseg )  );
  numCases = length(Nseg(:));

  for i = 1:numCases
    NtInc(i) = rssky_num_templates(Nseg(i), Tseg(i), mInc(i), params, false);
  endfor
  if ( params.grid_interpolation )
    for i = 1:numCases
      NtCoh(i) = rssky_num_templates(1, Tseg(i), mCoh(i), params, false);
    endfor
  else
    NtCoh = NtInc;
  endif

  ## coherent cost per template
  if params.resampling
    ## resampling cost per template, assuming "enough" frequency bins
    c0T = params.coh_c0_resamp * Ndet;
  else
    ## demod cost per template
    c0T = params.coh_c0_demod * Ndet * params.coh_duty * Tseg;
  endif

  costCoh = Nseg .* NtCoh .* c0T;
  costInc = Nseg .* NtInc .* params.inc_c0;

endfunction

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  [cost_funs, params, guess] = CostFunctionsEaHSupersky("S5R5", "debugLevel", 0);
%!  tol = -1e-2;	## relative error
%!  [costCoh, costInc] = cost_funs.f(guess.Nseg, guess.Tseg, guess.mCoh, guess.mInc);
%!  assert ( costCoh, guess.costCoh, tol );
%!  assert ( costInc, guess.costInc, tol );
%!
%!  sp_v2 = OptimalSolution4StackSlide_v2 ("costFuns", cost_funs, ...
%!                                  "cost0", params.cost0, ...
%!                                  "TobsMax", params.TobsMax, ...
%!                                  "TsegMin", 86400, ...
%!                                  "maxiter", 4, ...
%!                                  "stackparamsGuess", guess, ...
%!                                  "debugLevel", 1);
%!
%!  assert ( sp_v2.Nseg, 54.871, tol );
%!  assert ( sp_v2.Tseg, 86400, tol );
%!  assert ( sp_v2.mCoh, 0.077245, tol );
%!  assert ( sp_v2.mInc, 0.29725, tol );

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  [cost_funs, params, guess] = CostFunctionsEaHSupersky("S5GC1", "debugLevel", 0);
%!  tol = -1e-2;
%!  [costCoh, costInc] = cost_funs.f(guess.Nseg, guess.Tseg, guess.mCoh, guess.mInc);
%!  assert ( costCoh, guess.costCoh, tol );
%!  assert ( costInc, guess.costInc, tol );
%!
%!  sp_v2 = OptimalSolution4StackSlide_v2("costFuns", cost_funs, ...
%!                                  "cost0", params.cost0, ...
%!                                  "TobsMax", params.TobsMax, ...
%!                                  "TsegMin", 86400, ...
%!                                  "stackparamsGuess", guess, ...
%!                                  "maxiter", 10, ...
%!                                  "debugLevel", 1);
%!
%!  assert ( sp_v2.Nseg, 32.811, tol );
%!  assert ( sp_v2.Tseg, 86400, tol );
%!  assert ( sp_v2.mCoh, 0.071517, tol );
%!  assert ( sp_v2.mInc, 0.32054, tol );

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  [cost_funs, params, guess] = CostFunctionsEaHSupersky("S6Bucket", "debugLevel", 0);
%!  tol = -1e-2;
%!  [costCoh, costInc] = cost_funs.f(guess.Nseg, guess.Tseg, guess.mCoh, guess.mInc);
%!  assert ( costCoh, guess.costCoh, tol );
%!  assert ( costInc, guess.costInc, tol );
%!
%!  sp_v2 = OptimalSolution4StackSlide_v2("costFuns", cost_funs, ...
%!                                  "cost0", params.cost0, ...
%!                                  "TobsMax", params.TobsMax, ...
%!                                  "TsegMin", 86400, ...
%!                                  "stackparamsGuess", guess, ...
%!                                  "maxiter", 4, ...
%!                                  "debugLevel", 1);
%!
%!  assert ( sp_v2.Nseg, 123.00, tol );
%!  assert ( sp_v2.Tseg, 86400, tol );
%!  assert ( sp_v2.mCoh, 0.036052, tol );
%!  assert ( sp_v2.mInc, 0.29625, tol );
