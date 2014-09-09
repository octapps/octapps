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


## Dedicated test-function for OptimalSolution4StackSlide(), which would have been too long&messy
## to include as an octave test.
## Recomputes the E@H S5GC1 solution given in Prix&Shaltev,PRD85,084010(2012) Table~II
## and compares with reference result. This function either passes or fails depending on the result.
function sol = testEaH()

  refParams.Nseg = 205;
  refParams.Tseg = 25 * 3600;	## 25(!) hours
  refParams.mc   = 0.5;
  refParams.mf   = 0.5;

  cost_co = cost_coh(refParams.Nseg, refParams.Tseg, refParams.mc );
  cost_ic = cost_inc(refParams.Nseg, refParams.Tseg, refParams.mf );
  cost0 = cost_co + cost_ic;
  Tobs0 = 365 * 86400;

  sol = OptimalSolution4StackSlide ( "costFunCoh", @cost_coh, "costFunInc", @cost_inc, "cost0", cost0, "Tobs0", Tobs0, "stackparamsGuess", refParams );

  tol = -1e-3;
  assert ( sol.mc, 0.1443, tol );
  assert ( sol.mf, 0.1660, tol );
  assert ( sol.Nseg, 527.7, tol );
  assert ( sol.Tseg, 59762, tol );
  assert ( sol.cr, 0.8691, tol );

  return;
endfunction


%%
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

function ret = func_Nt_given_s ( s, Nseg, Tseg, mis )
  ## number of templates Nt for given search-parameters {Nseg, Tseg, mis} and spindown-order 's'
  ## using Eqs.(56) and (82) in Pletsch(2010)
  C_SI 		= 299792458;		%% Speed of light in vacuo, m s^-1
  DAYSID_SI	= 86164.09053;		%% Mean sidereal day, s
  REARTH_SI	= 6.378140e6;		%% Earth equatorial radius, m
  OmE = 2*pi / DAYSID_SI;
  tauE = REARTH_SI / C_SI;
  days = 86400;
  years = 365 * days;


  n = 3 + s;	%% 2 x sky + 1 x Freq + s x spindowns

  %% rho0 = AnsNormalizedThickness ( n ) * mis ^(-n/2);
  rho0 = ZnNormalizedThickness ( n ) * mis^(-n/2);
  phi = OmE .* Tseg / 2;	%%  Eq.(49) in Pletsch(2010)

  ## ---------- S5GC1: ----------
  numSkyPatches = 3;
  tau_min = 600*years;
  fmin 	= 50;
  fmax 	= 50.05;

  %% WU covers only a fraction of the sky:
  fracSky = 1/numSkyPatches;

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


function [Nt, s] = func_Nt ( Nseg, Tseg, mis )
  ## number of templates Nt for given search-parameters 'Nseg,Tseg,mis' and
  ## maximization over spindown-order 's'
  ## using Eqs.(56) and (82) in Pletsch(2010)
  Nt_s = ones (1, 2);
  for k = 1:2
    Nt_s(k) = func_Nt_given_s ( k, Nseg, Tseg, mis );
  endfor

  [Nt, s] = max ( Nt_s );

  return;

endfunction # func_Nt()

function cost = cost_coh ( Nseg, Tseg, mis )
  c0 = 7e-8;
  Tsft=1800;
  NDet = 2;

  [err, Nseg, Tseg, mis] = common_size( Nseg, Tseg, mis);
  assert ( err == 0 );

  for i = 1:length(Nseg(:))
    c0T = c0 * NDet * (Tseg(i) / Tsft);

    [Ntc, si] = func_Nt ( 1, Tseg(i), mis(i) );

    cost(i) = Nseg(i) * Ntc * c0T;
  endfor

  return;

endfunction ## cost_coh()

function [cost, s] = cost_inc ( Nseg, Tseg, mis )

  c0 = 6e-9;

  [err, Nseg, Tseg, mis] = common_size( Nseg, Tseg, mis);
  assert ( err == 0 );

  for i = 1:length(Nseg(:))
    [Ntf, s] = func_Nt ( Nseg(i), Tseg(i), mis(i) );

    cost(i) = Nseg(i) * Ntf * c0;
  endfor

  return;

endfunction ## cost_inc()

%!test
%!  testEaH();
