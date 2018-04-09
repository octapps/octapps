## Copyright (C) 2014 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {@var{cost_funs} =} CostFunctionsEaHGCT ( @var{opt}, @var{val}, @dots{} )
##
## Return computing-cost functions used by @command{OptimalSolution4StackSlide_v2()}
## to compute optimal Einstein@@Home search setups for the GCT code.
## Used to compute the E@@H S5GC1 solution given in Prix&Shaltev,PRD85,
## 084010(2012) Table~II.
##
## @heading Arguments
##
## @table @var
## @item cost_funs
## struct of computing-cost functions to pass to @command{OptimalSolution4StackSlide_v2()}
##
## @end table
##
## @heading Options
##
## @heading Options
##
## @table @code
## @item fracSky
## fraction of sky covered by search
##
## @item fmin
## minimum frequency covered by search (in Hz)
##
## @item fmax
## maximum frequency covered by search (in Hz)
##
## @item tau_min
## minimum spindown age, determines spindown ranges
##
## @item detectors
## CSV list of @var{detectors} to use ("H1"=Hanford, "L1"=Livingston, "V1"=Virgo, @var{...})
##
## @item coh_duty
## duty cycle of data within each coherent segment
##
## @item resampling
## use F-statistic @var{resampling} instead of 'demod' for coherent cost [default: false]
##
## @item lattice
## template-bank @var{lattice} ("Zn", "Ans",..) [default: "Zn"]
##
## @item coh_c0_demod
## computational cost of F-statistic 'demod' per template per second [optional]
##
## @item coh_c0_resamp
## computational cost of F-statistic @var{resampling} per template [optional]
##
## @item inc_c0
## computational cost of incoherent step per template per segment [optional]
##
## @item grid_interpolation
## whether to use interpolating or non-interpolating StackSlide (ie coherent-grids == incoherent-grid)
##
## @end table
##
## @end deftypefn

function cost_funs = CostFunctionsEaHGCT(varargin)

  ## parse options
  params = parseOptions(varargin,
                        {"fracSky", "real,strictpos,scalar", 1/3},
                        {"fmin", "real,strictpos,scalar", 50},
                        {"fmax", "real,strictpos,scalar", 50.05},
                        {"tau_min", "real,strictpos,scalar", 600 * 365 * 86400},
                        {"detectors", "char", "H1,L1" },
                        {"coh_duty", "real,strictpos,vector", 1 },
                        {"resampling", "logical,scalar", false},
                        {"coh_c0_demod", "real,strictpos,scalar", 7.4e-08 / 1800},
                        {"coh_c0_resamp", "real,strictpos,scalar", 1e-7},
                        {"inc_c0", "real,strictpos,scalar", 4.7e-09},
                        {"grid_interpolation", "logical,scalar", true},
                        {"lattice", "char", "Zn"},
                        []);

  ## make closures of functions with 'params'
  cost_funs = struct( "grid_interpolation", params.grid_interpolation, ...
                      "lattice", params.lattice, ...
                      "f", @(Nseg, Tseg, mCoh=0.5, mInc=0.5) cost_wparams(Nseg, Tseg, mCoh, mInc, params) ...
                    );

endfunction

function ret = jn ( n, x )
  ## spherical bessel function j_n(x), using expression in terms of
  ## ordinary Bessel functions J_n(x) from wikipedia:
  ## http://en.wikipedia.org/wiki/Bessel_function#Spherical_Bessel_functions:_jn.2C_yn
  ret = sqrt ( pi ./ (2 * x )) .* besselj ( n + 1/2, x );
endfunction ## jn()

function ret = detg1 ( phi )
  ## explicit expression Eq(57) in Pletsch(2010):
  ret = 1/135 * ( 1 - 6 * jn(1,phi).^2 - jn(0,phi) .* cos(phi) ) .* ( 1 - 10 * jn(2,phi).^2 - jn(1,phi) .* sin(phi) - jn(0,phi) .* cos(phi) );
  ## missing correction term deduced from maxima-evaluation
  corr = 1/135 * jn(1,phi) .* sin(phi) .* ( 1 - jn(0,phi) .* cos(phi) - 6 * jn(1,phi).^2 );
  ret -= corr;
endfunction ## detg1()

function ret = detg2 ( phi )
  ## derived using Maxima:
  ret = (8.*jn(0,phi).*jn(1,phi).*cos(phi).*sin(phi))/23625+(16.*jn(1,phi).*jn(3,phi).^2.*sin(phi))/3375+(16.*jn(1,phi).^3.*sin(phi))/7875-(8.*jn(1,phi).*sin(phi))/23625+(4.*jn(0,phi).^2.*cos(phi).^2)/23625+(8.*jn(0,phi).*jn(3,phi).^2.*cos(phi))/3375+(8.*jn(0,phi).*jn(2,phi).^2.*cos(phi))/4725+(8.*jn(0,phi).*jn(1,phi).^2.*cos(phi))/7875-(8.*jn(0,phi).*cos(phi))/23625+(16.*jn(2,phi).^2.*jn(3,phi).^2)/675-(8.*jn(3,phi).^2)/3375+(16.*jn(1,phi).^2.*jn(2,phi).^2)/1575-(8.*jn(2,phi).^2)/4725 -(8.*jn(1,phi).^2)/7875+4/23625;
endfunction ## detg2()

function ret = refinement ( s, Nseg )

  gam1 = sqrt ( 5 * Nseg.^2 - 4 );      ## Eq.(77) in Pletsch(2010)
  switch ( s )
    case 1
      ret = gam1;
    case 2
      ret = gam1 .* sqrt ( (35 * Nseg.^4 - 175 * Nseg.^2  + 143)/3 );## Eq.(96) in Pletsch(2010), 'fixed' to give gam(1)=1
    otherwise
      error ("Invalid value of s: '%f' given, allowed are {1,2}\n", s );
  endswitch

  return;

endfunction ## refinement()

function ret = func_Nt_given_s ( s, Nseg, Tseg, mis, params )
  ## number of templates Nt for given search-parameters {Nseg, Tseg, mis} and spindown-order 's'
  ## using Eqs.(56) and (82) in Pletsch(2010)
  C_SI          = 299792458;            ## Speed of light in vacuo, m s^-1
  DAYSID_SI     = 86164.09053;          ## Mean sidereal day, s
  REARTH_SI     = 6.378140e6;           ## Earth equatorial radius, m
  OmE = 2*pi / DAYSID_SI;
  tauE = REARTH_SI / C_SI;

  n = 3 + s;    ## 2 x sky + 1 x Freq + s x spindowns

  rho0 = LatticeNormalizedThickness ( n, params.lattice ) * mis^(-n/2);
  phi = OmE .* Tseg / 2;        ##  Eq.(49) in Pletsch(2010)

  fracSky = params.fracSky;     ## WU covers only a fraction of the sky
  fmin = params.fmin;
  fmax = params.fmax;
  tau_min = params.tau_min;

  switch ( s )

    case 1
      ## Eq.(56) in Pletsch(2010)
      prefact = rho0 * pi^5 * tauE^2 / (2 * tau_min ) * ( fmax^4 - fmin^4 );
      Ntc     = fracSky * prefact * sqrt(detg1(phi)) .* Tseg.^3;

    case 2
      prefact = rho0  * pi^6 * tauE^2 / (15 * tau_min.^3) * ( fmax^5 - fmin^5 );
      Ntc     = fracSky * prefact * sqrt(detg2(phi)) .* Tseg.^6;

    otherwise
      error ("Invalid value of s: '%f' given, allowed are {1,2}\n", s );
  endswitch

  refine = refinement ( s, Nseg );

  ret = Ntc * refine;

  return;
endfunction ## func_Nt_given_s()

function [Nt, s] = func_Nt ( Nseg, Tseg, mis, params )
  ## number of templates Nt for given search-parameters 'Nseg,Tseg,mis' and
  ## maximization over spindown-order 's'
  ## using Eqs.(56) and (82) in Pletsch(2010)
  Nt_s = ones (1, 2);
  for k = 1:2
    Nt_s(k) = func_Nt_given_s ( k, Nseg, Tseg, mis, params );
  endfor

  [Nt, s] = max ( Nt_s );

  return;

endfunction ## func_Nt()

function [costCoh, costInc] = cost_wparams ( Nseg, Tseg, mCoh, mInc, params )

  [err, Nseg, Tseg, mCoh, mInc] = common_size( Nseg, Tseg, mCoh, mInc);
  assert ( err == 0 );

  if ( ! params.grid_interpolation )
    assert ( isempty ( mCoh ) || ( mCoh == mInc ) );
  endif

  Ndet = length(strsplit(params.detectors, ","));
  costCoh = costInc = NtCoh = NtInc = zeros ( size ( Nseg )  );
  numCases = length(Nseg(:));

  for i = 1:numCases
    [ NtInc(i), s] = func_Nt ( Nseg(i), Tseg(i), mInc(i), params );
  endfor

  if ( params.grid_interpolation )
    for i = 1:numCases
      [NtCoh(i), s] = func_Nt ( 1, Tseg(i), mCoh(i), params );
    endfor
  else
    NtCoh = NtInc;
  endif

  if ( params.resampling )
    costCoh = Nseg .* NtCoh .* Ndet .* params.coh_c0_resamp;
  else
    costCoh = Nseg .* NtCoh .* Ndet .* (params.coh_c0_demod .* Tseg * params.coh_duty);
  endif
  costInc = Nseg .* NtInc * params.inc_c0;

  return;

endfunction ## cost_coh_wparams()

## Recomputes the E@H S5GC1 solution given in Prix&Shaltev,PRD85,084010(2012) Table~II
## and compares with reference result. This function either passes or fails depending on the result.
%!test
%!
%!  refParams.Nseg = 205;
%!  refParams.Tseg = 25 * 3600; ## 25(!) hours
%!  refParams.mCoh   = 0.5;
%!  refParams.mInc   = 0.5;
%!
%!  costFuns = CostFunctionsEaHGCT( ...
%!                                  "fracSky", 1/3, ...
%!                                  "fmin", 50, ...
%!                                  "fmax", 50.05, ...
%!                                  "tau_min", 600 * 365 * 86400, ...
%!                                  "detectors", "H1,L1", ...
%!                                  "resampling", false, ...
%!                                  "coh_c0_demod", 7e-8 / 1800, ...
%!                                  "inc_c0", 6e-9 ...
%!                                );
%!
%!  [ costCoh, costInc ] = costFuns.f(refParams.Nseg, refParams.Tseg, refParams.mCoh, refParams.mInc );
%!  cost0 = costCoh + costInc;
%!  TobsMax = 365 * 86400;
%!
%!  sol_v2 = OptimalSolution4StackSlide_v2 ( "costFuns", costFuns, "cost0", cost0, "TobsMax", TobsMax, "TsegMin", 3600, "stackparamsGuess", refParams, "debugLevel", 1 );
%!
%!  tol = -1e-3;
%!  assert ( sol_v2.mCoh, 0.14458, tol );
%!  assert ( sol_v2.mInc, 0.16639, tol );
%!  assert ( sol_v2.Nseg, 527.86, tol );
%!  assert ( sol_v2.Tseg, 5.9743e+04, tol );
