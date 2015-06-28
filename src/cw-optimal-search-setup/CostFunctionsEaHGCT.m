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

## Return computing-cost functions used by OptimalSolution4StackSlide()
## to compute optimal Einstein@Home search setups for the GCT code.
## Used to compute the E@H S5GC1 solution given in Prix&Shaltev,PRD85,
## 084010(2012) Table~II.
## Usage:
##   cost_funs = CostFunctionsEaHGCT("opt", val, ...)
## where
##   cost_funs = struct of computing-cost functions to pass to OptimalSolution4StackSlide()
## Options:
##   "fracSky":       fraction of sky covered by search
##   "fmin":          minimum frequency covered by search (in Hz)
##   "fmax":          maximum frequency covered by search (in Hz)
##   "tau_min":       minimum spindown age, determines spindown ranges
##   "Ndet":          number of detectors
##   "resampling":    use F-statistic 'resampling' instead of 'demod' for coherent cost [default: false]
##   "coh_c0_demod":  computational cost of F-statistic 'demod' per template per second [optional]
##   "coh_c0_resamp": computational cost of F-statistic 'resampling' per template [optional]
##   "inc_c0":        computational cost of incoherent step per template per segment [optional]
##   "grid_interpolation": whether to use interpolating or non-interpolating StackSlide (ie coarse-grids == fine-grid)
##
function cost_funs = CostFunctionsEaHGCT(varargin)

  ## parse options
  params = parseOptions(varargin,
                        {"fracSky", "real,strictpos,scalar", 1/3},
                        {"fmin", "real,strictpos,scalar", 50},
                        {"fmax", "real,strictpos,scalar", 50.05},
                        {"tau_min", "real,strictpos,scalar", 600 * 365 * 86400},
                        {"Ndet", "integer,strictpos,scalar", 2},
                        {"resampling", "logical,scalar", false},
                        {"coh_c0_demod", "real,strictpos,scalar", 7.4e-08 / 1800},
                        {"coh_c0_resamp", "real,strictpos,scalar", 1e-7},
                        {"inc_c0", "real,strictpos,scalar", 4.7e-09},
                        {"grid_interpolation", "logical,scalar", true},
                        []);

  ## make closures of functions with 'params'
  cost_funs = struct( ...
                     "costFunCoh", @(Nseg, Tseg, mc=0.5, lattice="Zn") cost_coh_wparams(Nseg, Tseg, mc, lattice, params), ...
                     "costFunInc", @(Nseg, Tseg, mf=0.5, lattice="Zn") cost_inc_wparams(Nseg, Tseg, mf, lattice, params) ...
                     );

endfunction


function ret = jn ( n, x )
  %% spherical bessel function j_n(x), using expression in terms of
  %% ordinary Bessel functions J_n(x) from wikipedia:
  %% http://en.wikipedia.org/wiki/Bessel_function#Spherical_Bessel_functions:_jn.2C_yn
  ret = sqrt ( pi ./ (2 * x )) .* besselj ( n + 1/2, x );
endfunction ## jn()

function ret = detg1 ( phi )
  %% explicit expression Eq(57) in Pletsch(2010):
  ret = 1/135 * ( 1 - 6 * jn(1,phi).^2 - jn(0,phi) .* cos(phi) ) .* ( 1 - 10 * jn(2,phi).^2 - jn(1,phi) .* sin(phi) - jn(0,phi) .* cos(phi) );
  %% missing correction term deduced from maxima-evaluation
  corr = 1/135 * jn(1,phi) .* sin(phi) .* ( 1 - jn(0,phi) .* cos(phi) - 6 * jn(1,phi).^2 );
  ret -= corr;
endfunction ## detg1()

function ret = detg2 ( phi )
  %% derived using Maxima:
  ret = (8.*jn(0,phi).*jn(1,phi).*cos(phi).*sin(phi))/23625+(16.*jn(1,phi).*jn(3,phi).^2.*sin(phi))/3375+(16.*jn(1,phi).^3.*sin(phi))/7875-(8.*jn(1,phi).*sin(phi))/23625+(4.*jn(0,phi).^2.*cos(phi).^2)/23625+(8.*jn(0,phi).*jn(3,phi).^2.*cos(phi))/3375+(8.*jn(0,phi).*jn(2,phi).^2.*cos(phi))/4725+(8.*jn(0,phi).*jn(1,phi).^2.*cos(phi))/7875-(8.*jn(0,phi).*cos(phi))/23625+(16.*jn(2,phi).^2.*jn(3,phi).^2)/675-(8.*jn(3,phi).^2)/3375+(16.*jn(1,phi).^2.*jn(2,phi).^2)/1575-(8.*jn(2,phi).^2)/4725 -(8.*jn(1,phi).^2)/7875+4/23625;
endfunction ## detg2()

function ret = refinement ( s, Nseg )

  gam1 = sqrt ( 5 * Nseg.^2 - 4 );	%% Eq.(77) in Pletsch(2010)
  switch ( s )
    case 1
      ret = gam1;
    case 2
      ret = gam1 .* sqrt ( (35 * Nseg.^4 - 175 * Nseg.^2  + 143)/3 );%% Eq.(96) in Pletsch(2010), 'fixed' to give gam(1)=1
    otherwise
      error ("Invalid value of s: '%f' given, allowed are {1,2}\n", s );
  endswitch

  return;

endfunction ## refinement()

function ret = func_Nt_given_s ( s, Nseg, Tseg, mis, lattice, params )
  ## number of templates Nt for given search-parameters {Nseg, Tseg, mis} and spindown-order 's'
  ## using Eqs.(56) and (82) in Pletsch(2010)
  C_SI 		= 299792458;		%% Speed of light in vacuo, m s^-1
  DAYSID_SI	= 86164.09053;		%% Mean sidereal day, s
  REARTH_SI	= 6.378140e6;		%% Earth equatorial radius, m
  OmE = 2*pi / DAYSID_SI;
  tauE = REARTH_SI / C_SI;

  n = 3 + s;	%% 2 x sky + 1 x Freq + s x spindowns

  rho0 = LatticeNormalizedThickness ( n, lattice ) * mis^(-n/2);
  phi = OmE .* Tseg / 2;	%%  Eq.(49) in Pletsch(2010)

  fracSky = params.fracSky;	%% WU covers only a fraction of the sky
  fmin = params.fmin;
  fmax = params.fmax;
  tau_min = params.tau_min;

  switch ( s )

      case 1
        %% Eq.(56) in Pletsch(2010)
        prefact = rho0 * pi^5 * tauE^2 / (2 * tau_min ) * ( fmax^4 - fmin^4 );
        Ntc 	= fracSky * prefact * sqrt(detg1(phi)) .* Tseg.^3;

      case 2
        prefact = rho0  * pi^6 * tauE^2 / (15 * tau_min.^3) * ( fmax^5 - fmin^5 );
        Ntc 	= fracSky * prefact * sqrt(detg2(phi)) .* Tseg.^6;

      otherwise
        error ("Invalid value of s: '%f' given, allowed are {1,2}\n", s );
    endswitch

    refine = refinement ( s, Nseg );

    ret = Ntc * refine;

  return;
endfunction ## func_Nt_given_s()


function [Nt, s] = func_Nt ( Nseg, Tseg, mis, lattice, params )
  ## number of templates Nt for given search-parameters 'Nseg,Tseg,mis' and
  ## maximization over spindown-order 's'
  ## using Eqs.(56) and (82) in Pletsch(2010)
  Nt_s = ones (1, 2);
  for k = 1:2
    Nt_s(k) = func_Nt_given_s ( k, Nseg, Tseg, mis, lattice, params );
  endfor

  [Nt, s] = max ( Nt_s );

  return;

endfunction # func_Nt()

function [cost, s] = cost_coh_wparams ( Nseg, Tseg, mc, lattice, params )

  [err, Nseg, Tseg, mc] = common_size( Nseg, Tseg, mc);
  assert ( err == 0 );
  cost = zeros ( size ( Nseg ) );

  for i = 1:length(Nseg(:))

    if ( params.grid_interpolation )
      [Ntc, s] = func_Nt ( 1, Tseg(i), mc(i), lattice, params );
    else
      [Ntc, s] = func_Nt ( Nseg(i), Tseg(i), mc(i), lattice, params );
    endif

    if ( params.resampling )
      cost(i) = Nseg(i) * Ntc * params.Ndet * params.coh_c0_resamp;
    else
      cost(i) = Nseg(i) * Ntc * params.Ndet * (params.coh_c0_demod * Tseg(i));
    endif

  endfor

  return;

endfunction ## cost_coh()

function [cost, s] = cost_inc_wparams ( Nseg, Tseg, mf, lattice, params )

  [err, Nseg, Tseg, mf] = common_size( Nseg, Tseg, mf);
  assert ( err == 0 );
  cost = zeros ( size ( Nseg ) );

  for i = 1:length(Nseg(:))
    [Ntf, s] = func_Nt ( Nseg(i), Tseg(i), mf(i), lattice, params );

    cost(i) = Nseg(i) * Ntf * params.inc_c0;
  endfor

  return;

endfunction ## cost_inc()
