## Copyright (C) 2013, 2015 Reinhard Prix
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

## Return computing-cost functions for use in OptimalSolution4StackSlide() to compute
## optimal StackSlide setup for a binary-CW searches (freq, Period, asini, tAsc, ecc, argp)
## assuming the "long segment regime" where Tseg >> P
##
## Usage:
##   cost_funs = CostFunctionsBinary("opt", val, ...)
## where
##   cost_funs = struct of computing-cost functions to pass to OptimalSolution4StackSlide()
##
## Search setup options: (using ScoX1 defaults)
##   "freqRange":     [min, max] of search frequency range [100, 300]
##   "asiniRange":    [min, max] of a*sini/c search range (default: [0.90000, 1.98000])
##   "tAscRange":     [min, max] of time of ascensino search range (default: [897753694.073760   897754294.073760])
##   "PeriodRange":   [min, max] of Period search range (default: [68023.5753600000, 68023.8345600000]
##   "eccRange":      [min, max] of eccentricity search range (default: [0, 0]
##   "argpRange":     [min, max] of argument(periapse) search range (default: [0, 0])
##
##   "detectors":     CSV list of detectors to use ("H1"=Hanford, "L1"=Livingston, "V1"=Virgo, ...)
##   "coh_duty":      duty cycle of data within each coherent segment
##
##   "resampling":    use F-statistic 'resampling' instead of 'demod' timings for coherent cost [default: false]
##   "lattice":       template-bank lattice ("Zn", "Ans",..) [default: "Ans"]
##   "coh_c0_demod":  computational cost of F-statistic 'demod' per template per second [optional]
##   "coh_c0_resamp": computational cost of F-statistic 'resampling' per template [optional]
##   "inc_c0":        computational cost of incoherent step per template per segment [optional]
##   "grid_interpolation": use interpolating StackSlide or non-interpolating (ie coarse-grids == fine-grid)
##
function cost_funs = CostFunctionsBinary ( varargin )

  ## parse options
  params = parseOptions(varargin,
                        {"freqRange", "real,strictpos,vector", [100, 300] },
                        {"asiniRange", "real,strictpos,vector", [0.90000, 1.98000]},
                        {"tAscRange", "real,strictpos,vector", [897753694.073760, 897754294.073760]},
                        {"PeriodRange", "real,strictpos,vector", [68023.5753600000, 68023.8345600000] },
                        {"eccRange", "real,positive,vector", [0, 0] },
                        {"argpRange", "real,vector", [0, 2*pi]},
                        {"detectors", "char", "H1,L1"},
                        {"coh_duty", "real,strictpos,vector", 1 },
                        {"resampling", "logical,scalar", false},
                        {"coh_c0_demod", "real,strictpos,scalar", 7.4e-08 / 1800},
                        {"coh_c0_resamp", "real,strictpos,scalar", 1e-7},
                        {"inc_c0", "real,strictpos,scalar", 4.7e-09},
                        {"grid_interpolation", "logical,scalar", true},
                        {"lattice", "char", "Ans"},
                        []);

  ## make closures of functions with 'params'
  cost_funs = struct( ...
                      "costFunCoh", @(Nseg, Tseg, mc=0.5) cost_coh_wparams ( Nseg, Tseg, mc, params ), ...
                      "costFunInc", @(Nseg, Tseg, mf=0.5) cost_inc_wparams ( Nseg, Tseg, mf, params ) ...
                    );

endfunction ## CostFunctionsBinary()
## Recompute ScoX1 solution from Leaci&Prix(2015) paper, Table II, corrected for xi=MeanHist(An*) instead of 0.5
## and lack of duty-cycle usage in cost function
%!test
%!  UnitsConstants;
%!  refParams.Nseg = 40;
%!  refParams.Tseg = 8.0 * DAYS;
%!  refParams.mc   = 0.5;
%!  refParams.mf   = 0.5;
%!  Tsft = 240;
%!
%!  costFuns = CostFunctionsBinary ( ...
%!                                  "freqRange", [20, 430],
%!                                  "detectors", "H1,L1",
%!                                  "resampling", false, ...
%!                                  "coh_c0_demod", 4e-8 / Tsft, ...
%!                                  "inc_c0", 5e-9, ...
%!                                  "lattice", "Ans" ...
%!                                );
%!  cost0 = 12 * EM2014;
%!  TobsMax = 360 * DAYS;
%!  TsegMax = 10 * DAYS;
%!
%!  sol = OptimalSolution4StackSlide ( "costFuns", costFuns, "cost0", cost0, "TobsMax", TobsMax, "TsegMax", TsegMax, "stackparamsGuess", refParams );
%!
%!  tol = -1e-2;
%!  assert ( sol.mc, 0.740353478526876, tol );	%% values corrected for xi=MeanHist(An*) instead of 0.5
%!  assert ( sol.mf, 0.0441091639769692, tol );
%!  assert ( sol.Nseg, 40.4819540406797, tol );
%!  assert ( sol.Tseg, 768342.357405575, tol );
%!  assert ( sol.cr, 22.3794305395332, tol );

## Recompute ScoX1 solution from Leaci&Prix(2015) paper, Table III, corrected for xi=MeanHist(An*) instead of 0.5
%!test
%!  UnitsConstants;
%!  refParams.Nseg = 40;
%!  refParams.Tseg = 8.0 * DAYS;
%!  refParams.mc   = 0.5;
%!  refParams.mf   = 0.5;
%!
%!  costFuns = CostFunctionsBinary ( ...
%!                                  "freqRange", [20, 630],
%!                                  "detectors", "H1,L1",
%!                                  "resampling", true, ...
%!                                  "coh_c0_resamp", 3e-7,
%!                                  "inc_c0", 5e-9, ...
%!                                  "lattice", "Ans" ...
%!                                );
%!  cost0 = 12 * EM2014;
%!  TobsMax = 360 * DAYS;
%!  TsegMax = 10 * DAYS;
%!
%!  sol = OptimalSolution4StackSlide ( "costFuns", costFuns, "cost0", cost0, "TobsMax", TobsMax, "TsegMax", TsegMax, "stackparamsGuess", refParams );
%!
%!  tol = -1e-2;
%!  assert ( sol.mc, 0.037677, tol );
%!  assert ( sol.mf, 0.031533, tol );
%!  assert ( sol.Nseg, 36, tol );
%!  assert ( sol.Tseg, 864000, tol );
%!  assert ( sol.cr, 1.5931, tol );

## Recompute ScoX1 solution from Leaci&Prix(2015) paper, Table IV, corrected for xi=MeanHist(An*) instead of 0.5
%!test
%!  UnitsConstants;
%!  refParams.Nseg = 40;
%!  refParams.Tseg = 8.0 * DAYS;
%!  refParams.mc   = 0.5;
%!  refParams.mf   = 0.5;
%!
%!  costFuns = CostFunctionsBinary ( ...
%!                                  "freqRange", [20, 200],
%!                                  "eccRange", [0, 0.087],
%!                                  "detectors", "H1,L1",
%!                                  "resampling", true, ...
%!                                  "coh_c0_resamp", 3e-7,
%!                                  "inc_c0", 5e-9, ...
%!                                  "lattice", "Ans" ...
%!                                );
%!  cost0 = 12 * EM2014;
%!  TobsMax = 360 * DAYS;
%!  TsegMax = 10 * DAYS;
%!
%!  sol = OptimalSolution4StackSlide ( "costFuns", costFuns, "cost0", cost0, "TobsMax", TobsMax, "TsegMax", TsegMax, "stackparamsGuess", refParams );
%!
%!  tol = -1e-2;
%!  assert ( sol.mc, 1.1838, tol );
%!  assert ( sol.mf, 0.53792, tol );
%!  assert ( sol.Nseg, 36, tol );
%!  assert ( sol.Tseg, 864000, tol );
%!  assert ( sol.cr, 2.6405, tol );


function [cost, Nt, lattice] = cost_coh_wparams ( Nseg, Tseg, mc, params )
  ## coherent cost function

  ## check input parameters
  [err, Nseg, Tseg, mc] = common_size(Nseg, Tseg, mc);
  assert(err == 0);

  cost = Nt = zeros ( size ( Nseg )  );
  for i = 1:length(Nseg(:))

    if ( params.grid_interpolation )
      NsegCoh = 1;
    else
      NsegCoh = Nseg(i);
    endif

    Nt(i) = numTemplates ( NsegCoh, Tseg(i), mc(i), params );

    Ndet = length(strsplit(params.detectors, ","));
    if ( params.resampling )
      cost(i)  = Nseg(i) * Nt(i) * Ndet * params.coh_c0_resamp;
    else
      cost(i)  = Nseg(i) * Nt(i) * Ndet * (params.coh_c0_demod * Tseg(i) * params.coh_duty);
    endif

  endfor

  lattice = params.lattice;

  return;

endfunction ## cost_coh_wparams()


function [cost, Nt, lattice] = cost_inc_wparams ( Nseg, Tseg, mf, params )
  ## incoherent cost function

  ## check input parameters
  [err, Nseg, Tseg, mf] = common_size(Nseg, Tseg, mf);
  assert(err == 0);

  cost = Nt = zeros ( size ( Nseg )  );
  for i = 1:length(Nseg(:))
    Nt(i)   = numTemplates ( Nseg(i), Tseg(i), mf(i), params );
    cost(i) = Nseg(i) * Nt(i) * params.inc_c0;
  endfor

  lattice = params.lattice;

  return;

endfunction ## cost_inc_wparams()


%% ------------------------------------------------------------
function [Nt, NtSlice, nDim, fMid] = numTemplates ( Nseg, Tseg, misMax, params )
  %% 'adaptive' template counts, allowing for variable number of dimensions as a function of frequency,
  %% by summing fixed-dimension template counts over 'numFreqSlices' slices in frequency
  %%
  %% returns a cell-arrarys of {NtSlice, nDim} over all frequency slices with mid-frequencies fMid

  [err, Nseg, Tseg, misMax] = common_size( Nseg, Tseg, misMax );
  assert ( err == 0 );

  Tspan = Nseg .* Tseg;
  FreqSlice = 4;	%% adapt to dimensionality in freq steps
  numFreqSlices = ceil ( (max(params.freqRange) - min(params.freqRange)) / FreqSlice );
  fbar = linspace ( min(params.freqRange), max(params.freqRange), numFreqSlices + 1 );

  nDim = cell ( 1, numFreqSlices );
  NtSlice = cell ( 1, numFreqSlices );
  fMid = fbar(1:end-1) + 0.5*diff(fbar);
  Nt = 0;
  for i = 1 : numFreqSlices
    params_i = params;
    params_i.freqRange = [fbar(i), fbar(i+1)];
    [ NtSlice{i}, nDim{i} ] = numTemplatesFixedDim ( Nseg, Tseg, misMax, params_i );
    Nt += NtSlice{i};
  endfor

  return;
endfunction

function [ Nt, nDim ] = numTemplatesFixedDim ( Nseg, Tseg, misMax, params )
  %% compute 'continuous' template count, assuming a template bank with fixed number of
  %% dimensions over all the parameter space (estimated at the mean frequency given)
  %%
  %% Note: currently assuming a 'ScoX1-like' parameter space, where only 'Om' and {ecc,argp}
  %% can be either resolved or unresolved, while asini and tAsc are assumed to be always resolved.

  [err, Nseg, Tseg, misMax] = common_size( Nseg, Tseg, misMax );
  assert ( err == 0 );

  Tspan = Nseg .* Tseg;

  params.OmRange = 2*pi ./ fliplr(params.PeriodRange);
  pSMidFreq = params;
  pSMidFreq.freqRange = mean(params.freqRange);	%% use this 'fiducial' frequency to estimate dimensionality
  [fbar, Nt_a, Nt_tAsc, Nt_Om, Nt_ecc, Nt_argp] = numTemplatesPerDim ( pSMidFreq, Tspan, misMax );
  assert ( Nt_a > 1 );
  assert ( Nt_tAsc > 1 );

  ii3d = ( (Nt_Om <= 1)  & (Nt_ecc <= 1) );
  ii4d = ( (Nt_Om > 1)   & (Nt_ecc <= 1) );
  ii5d = ( (Nt_Om <= 1)  & (Nt_ecc > 1)  );
  ii6d = ( (Nt_Om > 1)   & (Nt_ecc > 1)  );

  thick6 = LatticeNormalizedThickness ( 6, params.lattice );
  thick5 = LatticeNormalizedThickness ( 5, params.lattice );
  thick4 = LatticeNormalizedThickness ( 4, params.lattice );
  thick3 = LatticeNormalizedThickness ( 3, params.lattice );

  Om0 = mean(params.OmRange);
  %% ----- 6D template counts
  Nt(ii6d) = (thick6 * pi^6 / (360*sqrt(2))) * Nseg(ii6d) .* Tseg(ii6d).^2 .* misMax(ii6d).^(-3) ...
             * MaxMin(params.freqRange, 6) ...
             * MaxMin(params.asiniRange, 5) ...
             * MaxMin(params.tAscRange, 1) ...
             * MaxMin(params.OmRange, 2) ...
             * MaxMin(params.eccRange, 2) ...
             * MaxMin(params.argpRange, 1);

  Nt(ii5d) = (thick5 * pi^5 / (40*sqrt(3))) * Om0 * Tseg(ii5d) .* misMax(ii5d).^(-2.5) ...
             * MaxMin(params.freqRange, 5) ...
             * MaxMin(params.asiniRange,4) ...
             * MaxMin(params.tAscRange,1) ...
             * MaxMin(params.eccRange,2) ...
             * MaxMin(params.argpRange,1);

  Nt(ii4d) = (thick4 * pi^4 / (36*sqrt(2))) * Nseg(ii4d) .* Tseg(ii4d).^2 .* misMax(ii4d).^(-2) ...
             * MaxMin(params.freqRange, 4) ...
             * MaxMin(params.asiniRange, 3) ...
             * MaxMin(params.tAscRange, 1) ...
             * MaxMin(params.OmRange, 2);

  Nt(ii3d) = (thick3 * pi^3 / sqrt(27)) * Om0 * Tseg(ii3d) .* misMax(ii3d).^(-1.5) ...
             * MaxMin(params.freqRange, 3) ...
             * MaxMin(params.asiniRange, 2) ...
             * MaxMin(params.tAscRange, 1);


  nDim = zeros ( size ( Nt ));
  nDim(ii3d) = 3;
  nDim(ii4d) = 4;
  nDim(ii5d) = 5;
  nDim(ii6d) = 6;
  return;
endfunction

function [fbar, Nt_a, Nt_tAsc, Nt_Om, Nt_ecc, Nt_argp] = numTemplatesPerDim ( paramSpace, Tspan, misMax = 0.1, numFreqSlices = 100 )
  %% [freq, Nt_a, Nt_tAsc, Nt_Om, Nt_ecc, Nt_argp] = numTemplatesPerDim ( paramSpace, Tspan, misMax = 0.1, numFreqSlices = 100 )

  %% astrophysical parameters-space extents
  Da    = MaxMin ( paramSpace.asiniRange, 1 );
  DtAsc = MaxMin ( paramSpace.tAscRange, 1);
  DOm   = MaxMin ( paramSpace.OmRange, 1);
  Decc  = MaxMin ( paramSpace.eccRange, 1);
  Dargp = MaxMin ( paramSpace.argpRange, 1);

  %% metric extents for max-mismatch
  [fbar, d_a, d_tAsc, d_Om, d_ecc, d_argp] = metricBinarySpacings ( paramSpace, Tspan, misMax, numFreqSlices );

  Nt_a    = Da ./ d_a;
  Nt_tAsc = DtAsc ./ d_tAsc;
  Nt_Om   = DOm ./ d_Om;
  Nt_ecc  = Decc ./ d_ecc;
  Nt_argp = Dargp ./ d_argp;

  return;
endfunction

function [fbar, d_a, d_tAsc, d_Om, d_ecc, d_argp] = metricBinarySpacings ( paramSpace, Tspan, misMax, numFreqSlices = 100 )
  %% [fbar, d_a, d_tAsc, d_Om, d_ecc, d_argp] = metricBinarySpacings ( paramSpace, Tspan, misMax )

  %% estimate number of templates at 'average' location, should yield best estimate for total number of templates
  asini = mean(paramSpace.asiniRange);
  Om = mean(paramSpace.OmRange);
  ecc = mean(paramSpace.eccRange);

  fbar = unique (linspace ( min(paramSpace.freqRange), max(paramSpace.freqRange), numFreqSlices) );

  [g_aa, g_tata, g_OmOm, g_ee, g_ww] = binaryMetricLS ( Tspan, fbar, asini, Om, ecc );

  d_a    =  2 * sqrt(misMax) ./ sqrt ( g_aa );
  d_tAsc =  2 * sqrt(misMax) ./ sqrt ( g_tata );
  d_Om   =  2 * sqrt(misMax) ./ sqrt ( g_OmOm );
  d_ecc  =  2 * sqrt(misMax) ./ sqrt ( g_ee );
  if ( g_ww > 0 )
    d_argp =  2 * sqrt(misMax) ./ sqrt ( g_ww );
  else
    d_argp = NA;
  endif

  return;
endfunction

function [g_aa, g_tata, g_OmOm, g_ee, g_ww] = binaryMetricLS ( Tspan, fbar, asini, Om, ecc )
  %%  [g_aa, g_tata, g_OmOm, g_ee, g_ww] = binaryMetricLS ( Tspan, fbar, asini, Om, ecc )

  [err, Tspan, fbar, asini, Om] = common_size( Tspan, fbar, asini, Om );
  assert ( err == 0 );

  g_aa   = 2*pi^2 * fbar.^2;
  g_tata = 2*pi^2 * ( fbar .* asini .* Om ).^2;
  g_OmOm = pi^2/6 * ( fbar .* asini .* Tspan ).^2;
  g_ee   = pi^2/2 * ( fbar .* asini ).^2;
  g_ww   = ecc.^2 .* g_ee;

  return;

endfunction

function res = MaxMin ( range, pow )
  %% res = MaxMin ( range, pow )
  %% returns max(range)^pow - min(range)^pow;
  res = max(range).^pow - min(range).^pow;
  return;
endfunction
