## Copyright (C) 2013, 2015 Karl Wette
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

## Computes the coherent global correlation transform metric, as
## given in Pletsch, PRD 82 042002 (2010), which Taylor-expands the
## Earth's orbital motion.
## Syntax:
##   g = GCTCoherentTaylorMetric("opt", val, ...)
## where:
##   g = coherent GCT metric using Taylor-expanded phase model
## Options:
##   "smax":  number of spindowns (up to second spindown)
##   "tj":    value of tj, the mid-point of the coherent time span
##   "t0":    value of t0, an overall reference time
##   "T":     value of T, the coherent time span
##   "Omega": value of Omega, the Earth's angular rotation frequency
##            (default: 2*pi / (sidereal day in seconds)

function g = GCTCoherentTaylorMetric(varargin)

  ## parse options
  parseOptions(varargin,
               {"smax", "integer,strictpos,scalar"},
               {"tj", "real,scalar"},
               {"t0", "real,scalar"},
               {"T", "real,strictpos,scalar"},
               {"Omega", "real,strictpos,scalar", 7.29211585537707e-05},
               []);

  ## check options
  assert(smax <= 2, "Only up to second spindown supported");

  ## create coordinate indices
  [ii{1:5}] = deal([]);
  ii([1:smax+1,4,5]) = num2cell(1:3+smax);
  [nu, nud, nudd, nx, ny] = deal(ii{:});

  ## various constants for computing elements
  phi = Omega * T / 2;
  cos_phi = cos(phi);
  sin_phi = sin(phi);
  j0_phi = sin_phi / phi;   ## spherical Bessel functions
  j1_phi = sin_phi / phi^2 - cos_phi / phi;
  j2_phi = ( (3/phi^2 - 1) * sin_phi / phi ) - ( 3 * cos_phi / phi^2 );
  j3_phi = ( (15/phi^3 - 6/phi) * sin_phi / phi ) - ( (15/phi^2 - 1) * cos_phi / phi );
  cos_Omega_tj = cos(Omega * tj);
  sin_Omega_tj = sin(Omega * tj);
  tj_t0_T = ((tj - t0) / T).^(1:4);

  ## initial metric is NaNs to ensure each element is computed
  g = nan(3 + smax, 3 + smax);

  ## compute metric elements
  g(nu, nu) = 1/3;
  g(nu, nx) = g(nx, nu) = -j1_phi * sin_Omega_tj;
  g(nu, ny) = g(ny, nu) =  j1_phi * cos_Omega_tj;
  g(nx, nx) = 1/2 - 1/2 * j0_phi * cos_phi - j1_phi * sin_phi * cos_Omega_tj^2;
  g(nx, ny) = g(ny, nx) = -j1_phi * sin_phi * sin_Omega_tj * cos_Omega_tj;
  g(ny, ny) = 1/2 - 1/2 * j0_phi * cos_phi - j1_phi * sin_phi * sin_Omega_tj^2;
  if !isempty(nud)
    g(nu, nud) = g(nud, nu) = 4/3 * tj_t0_T(1);
    g(nud, nud) = 4/45 + 16/3 * tj_t0_T(2);
    g(nud, nx) = g(nx, nud) = -2/3 * j2_phi * cos_Omega_tj - 4 * j1_phi * tj_t0_T(1) * sin_Omega_tj;
    g(nud, ny) = g(ny, nud) = -2/3 * j2_phi * sin_Omega_tj + 4 * j1_phi * tj_t0_T(1) * cos_Omega_tj;
    if !isempty(nudd)
      g(nu, nudd) = g(nudd, nu) = 1/5 + 4 * tj_t0_T(2);
      g(nud, nudd) = g(nudd, nud) = 4/3 * tj_t0_T(1) + 16 * tj_t0_T(3);
      g(nudd, nudd) = 1/7 + 8 * tj_t0_T(2) + 48 * tj_t0_T(4);
      g(nudd, nx) = g(nx, nudd) = ( -3/5 * j1_phi + 2/5 * j3_phi ) * sin_Omega_tj - 4 * j2_phi ...
          * tj_t0_T(1) * cos_Omega_tj - 12 * j1_phi * tj_t0_T(2) * sin_Omega_tj;
      g(nudd, ny) = g(ny, nudd) = (  3/5 * j1_phi - 2/5 * j3_phi ) * cos_Omega_tj - 4 * j2_phi ...
          * tj_t0_T(1) * sin_Omega_tj + 12 * j1_phi * tj_t0_T(2) * cos_Omega_tj;
    endif
  endif

endfunction

## check GCT implementation against numerical metrics generated by Maxima script CheckGCTTaylorMetrics.wxm
%!function __test_gctcoh(tj, t0, T, gref)
%!  g = GCTCoherentTaylorMetric("smax", 2, "tj", tj, "t0", t0, "T", T, "Omega", 2*pi);
%!  assert(all(abs(g - gref) < 1e-14));

%!test __test_gctcoh(-1/2, 0, 1, ...
%!                   [ ...
%!                     0.33333333333333,-0.66666666666666,1.2,0,-0.31830988618379; ...
%!                     -0.66666666666666,1.422222222222222,-2.666666666666666,0.20264236728467,0.63661977236758; ...
%!                     1.2,-2.666666666666666,5.142857142857143,-0.60792710185402,-1.079730338135965; ...
%!                     0,0.20264236728467,-0.60792710185402,0.5,0; ...
%!                     -0.31830988618379,0.63661977236758,-1.079730338135965,0,0.5; ...
%!                   ]);

%!test __test_gctcoh(0, 0, 1, ...
%!                   [ ...
%!                     0.33333333333333,0,0.2,0,0.31830988618379; ...
%!                     0,0.088888888888888,0,-0.20264236728467,0; ...
%!                     0.2,0,0.14285714285714,0,0.12480067958459; ...
%!                     0,-0.20264236728467,0,0.5,0; ...
%!                     0.31830988618379,0,0.12480067958459,0,0.5; ...
%!                   ]);

%!test __test_gctcoh(1/3, 1/2, 2.5, ...
%!                   [ ...
%!                     0.33333333333333,-0.088888888888888,0.21777777777777,-0.014039475036123,-0.0081056946913869; ...
%!                     -0.088888888888888,0.11259259259259,-0.093629629629629,-0.036633359944481,0.072096915013279; ...
%!                     0.21777777777777,-0.093629629629629,0.17936084656084,-0.025350712749409,-0.051935118925438; ...
%!                     -0.014039475036123,-0.036633359944481,-0.025350712749409,0.4959471526543,0.0070197375180618; ...
%!                     -0.0081056946913869,0.072096915013279,-0.051935118925438,0.0070197375180618,0.48784145796291; ...
%!                   ]);

## check determinant of GCT metric implementation against expressions by Prix&Shaltev from CostFunctionsEaHGCT()
%!function ret = jn ( n, x )
%!  ## spherical bessel function j_n(x), using expression in terms of
%!  ## ordinary Bessel functions J_n(x) from wikipedia:
%!  ## http://en.wikipedia.org/wiki/Bessel_function#Spherical_Bessel_functions:_jn.2C_yn
%!  ret = sqrt ( pi ./ (2 * x )) .* besselj ( n + 1/2, x );

%!function ret = detg1 ( phi )
%!  ## explicit expression Eq(57) in Pletsch(2010):
%!  ret = 1/135 * ( 1 - 6 * jn(1,phi).^2 - jn(0,phi) .* cos(phi) ) .* ( 1 - 10 * jn(2,phi).^2 - jn(1,phi) .* sin(phi) - jn(0,phi) .* cos(phi) );
%!  ## missing correction term deduced from maxima-evaluation
%!  corr = 1/135 * jn(1,phi) .* sin(phi) .* ( 1 - jn(0,phi) .* cos(phi) - 6 * jn(1,phi).^2 );
%!  ret -= corr;

%!function ret = detg2 ( phi )
%!  ## derived using Maxima:
%!  ret = (8.*jn(0,phi).*jn(1,phi).*cos(phi).*sin(phi))/23625+(16.*jn(1,phi).*jn(3,phi).^2.*sin(phi))/3375+(16.*jn(1,phi).^3.*sin(phi))/7875-(8.*jn(1,phi).*sin(phi))/23625+(4.*jn(0,phi).^2.*cos(phi).^2)/23625+(8.*jn(0,phi).*jn(3,phi).^2.*cos(phi))/3375+(8.*jn(0,phi).*jn(2,phi).^2.*cos(phi))/4725+(8.*jn(0,phi).*jn(1,phi).^2.*cos(phi))/7875-(8.*jn(0,phi).*cos(phi))/23625+(16.*jn(2,phi).^2.*jn(3,phi).^2)/675-(8.*jn(3,phi).^2)/3375+(16.*jn(1,phi).^2.*jn(2,phi).^2)/1575-(8.*jn(2,phi).^2)/4725 -(8.*jn(1,phi).^2)/7875+4/23625;

%!test
%!  T = 1:10;
%!  GCT_det = arrayfun(@(T) det(GCTCoherentTaylorMetric("smax", 1, "tj", 0, "t0", 0, "T", T, "Omega", 2*pi)), T);
%!  GCT_det_ref = arrayfun(@(T) detg1(2*pi*T/2), T);
%!  assert(all(abs(GCT_det - GCT_det_ref) < 1e-10));

%!test
%!  T = 1:10;
%!  GCT_det = arrayfun(@(T) det(GCTCoherentTaylorMetric("smax", 2, "tj", 0, "t0", 0, "T", T, "Omega", 2*pi)), T);
%!  GCT_det_ref = arrayfun(@(T) detg2(2*pi*T/2), T);
%!  assert(all(abs(GCT_det - GCT_det_ref) < 1e-10));
