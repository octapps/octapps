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

## Computes the coherent global correlation coordinates, as
## given in Pletsch, PRD 82 042002 (2010)
## Syntax:
##   coords         = GCTCoherentMetric("opt", val, ...)
##   [nu,...,nx,ny] = GCTCoherentMetric("opt", val, ...)
## where:
##   coords         = matrix of GCT coordinates; order matches that of GCTCoherentMetric()
##   nu,...         = GCT frequency and spindown coordinates
##   nx             = GCT equatorial-x sky coordinate
##   ny             = GCT equatorial-y sky coordinate
## Options:
##   "t0":          value of t0, an overall reference time
##   "T":           value of T, the coherent time span
##   "alpha":       row vector of right ascensions in radians
##   "delta":       row vector of declinations in radians
##   "fndot":       matrix of frequency and spindowns in SI units
##   "detector":    detector name, e.g. H1
##   "ephemerides": Earth/Sun ephemerides from loadEphemerides()
##   "ptolemaic":   use Ptolemaic orbital motion

function varargout = GCTCoordinates(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"t0", "real,scalar"},
               {"T", "real,strictpos,scalar"},
               {"alpha", "real,vector"},
               {"delta", "real,vector"},
               {"fndot", "real,matrix"},
               {"detector", "char"},
               {"ephemerides", "a:swig_ref", []},
               {"ptolemaic", "logical,scalar", false},
               []);
  smax = size(fndot, 1) - 1;

  ## check options
  assert(smax <= 2, "Only up to second spindown supported");
  assert(size(fndot, 2) > 0);
  assert(all(size(alpha) == [1, size(fndot, 2)]));
  assert(all(size(delta) == [1, size(fndot, 2)]));
  assert(isempty(strfind(detector, ",")), "Only a single detector is supported");

  ## load ephemerides if needed and not supplied
  if !ptolemaic && isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## create coordinate indices
  [ii{1:5}] = deal([]);
  ii([1:smax+1,4,5]) = num2cell(1:3+smax);
  [nu, nud, nudd, nx, ny] = deal(ii{:});

  ## get detector information
  multiIFO = new_MultiLALDetector;
  XLALParseMultiLALDetector(multiIFO, XLALCreateStringVector(detector));
  assert(multiIFO.length == 1, "Could not parse detector '%s'", detector);
  detLat = multiIFO.sites{1}.frDetector.vertexLatitudeRadians;
  detLong = multiIFO.sites{1}.frDetector.vertexLongitudeRadians;

  ## get position of GMT at reference time t0
  zeroLong = mod(XLALGreenwichMeanSiderealTime(LIGOTimeGPS(t0)), 2*pi);

  ## compute sky position vector in equatorial coordinates
  n = [cos(alpha).*cos(delta); sin(alpha).*cos(delta); sin(delta)];

  ## extend frequency/spindown vector up to second spindown with zeros
  fndot(end+1:3, :) = 0;
  f = fndot(1, :);
  fd = fndot(2, :);
  fdd = fndot(3, :);

  ## compute orbital derivatives in equatorial coordinates
  if !ptolemaic
    orbit_deriv = XLALComputeOrbitalDerivatives(smax+1, t0, ephemerides);
    xindot = native(orbit_deriv);
  else

    ## get orbital position of the Earth
    [_, tAutumn] = XLALGetEarthTimes(t0);

    ## compute various constants required for calculating derivatives
    Omegao = 2*pi / LAL_YRSID_SI;
    phio = -Omegao * tAutumn;
    Ro_cos_phio = LAL_AU_SI / LAL_C_SI * cos(phio);
    Ro_sin_phio = LAL_AU_SI / LAL_C_SI * sin(phio);
    ecl_to_equ = [1 0; 0 LAL_COSIEARTH; 0 LAL_SINIEARTH];

    ## compute Ptolemaic derivatives
    xindot = zeros(smax+2, 3);
    xindot(1, :) = ecl_to_equ * [Ro_cos_phio; Ro_sin_phio];
    xindot(2, :) = Omegao * ecl_to_equ * [-Ro_sin_phio; Ro_cos_phio];
    if smax > 0
      xindot(3, :) = Omegao^2 * ecl_to_equ * [-Ro_cos_phio; -Ro_sin_phio];
      if smax > 1
        xindot(4, :) = Omegao^3 * ecl_to_equ * [Ro_sin_phio; -Ro_cos_phio];
      endif
    endif

  endif

  ## compute dot product of orbital derivatives with sky position vector
  xindot_n = xindot * n;

  ## initialise output coordinates
  coord = zeros(3+smax, size(fndot, 2));

  ## compute GCT sky position coordinates
  tau_E = LAL_REARTH_SI / LAL_C_SI;
  alphaD = detLong + zeroLong;
  n_prefac = 2*pi .* f .* tau_E .* cos(detLat) .* cos(delta);
  coord(nx, :) = n_prefac .* cos(alpha - alphaD);
  coord(ny, :) = n_prefac .* sin(alpha - alphaD);

  ## compute GCT frequency coordinates
  nu_prefac = 2*pi * (T / 2).^(1:smax+1);
  xi_n = xindot_n(1, :);
  xid_n = xindot_n(2, :);
  coord(nu, :) = nu_prefac(1) * (f + f.*xid_n + fd.*xi_n);
  if !isempty(nud)
    xidd_n = xindot_n(3, :);
    coord(nud, :) = nu_prefac(2) * (1/2.*fd + 1/2.*f.*xidd_n + fd.*xid_n + 1/2.*fdd.*xi_n);
    if !isempty(nudd)
      xiddd_n = xindot_n(4, :);
      coord(nudd, :) = nu_prefac(3) * (1/6.*fdd + 1/6.*f.*xiddd_n + 1/2.*fd.*xidd_n + 1/2.*fdd.*xid_n);
    endif
  endif

  ## return coordinates, either as multiple output arguments or as a vector
  if nargout > 1
    varargout = mat2cell(coord, ones(1, size(coord, 1)), size(coord, 2));
  else
    varargout = {coord};
  endif

endfunction

%!shared alpha_ref, delta_ref, fndot_ref, gctco_ref
%!  alpha_ref = [1.1604229, 3.4494408, 0.3384569, 3.2528905, 4.2220307, 4.0216501, 4.4586725, 2.6643348, 4.5368049, 4.1968573, 1.0090024, 2.3518049, 6.1686511, 2.7418963, 5.7136839, 4.8999429, 3.5196677, 3.5462285];
%!  delta_ref = [0.1932254, 0.1094716,-0.9947154, 0.0326421, 0.8608284,-0.5364847,-0.7566707, 0.3503306,-0.5262539,-0.7215617,-0.2617862,-0.4193604,-1.0175479, 0.4204785,-0.2233229,-0.2677687,-0.1032384, 1.4105888];
%!  fndot_ref = [6.2948e-3, 1.3900e-3, 7.4630e-3, 3.4649e-3, 8.1318e-3, 4.6111e-3, 9.9765e-3, 2.4069e-3, 8.0775e-3, 6.0784e-3, 1.2569e-3, 8.3437e-3, 8.1557e-3, 4.2130e-3, 7.0748e-4, 4.0846e-3, 3.1204e-3, 3.8858e-3;
%!               0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000,-1.859e-10,-1.7734e-9,-6.7179e-9,-7.6231e-9,-5.9919e-9,-4.7396e-9,-8.0516e-9,-4.0123e-9,-9.1149e-9,-5.3355e-9,-2.0422e-9,-7.7313e-9;
%!               0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 2.596e-17, 9.455e-17, 1.913e-17, 6.869e-17, 2.286e-17, 1.743e-17];
%!  gctco_ref = [1.7085e+3, 3.7728e+2, 2.0258e+3, 9.4045e+2, 2.2072e+3, 1.2517e+3, 2.7081e+3, 6.5316e+2, 2.1921e+3, 1.6492e+3, 3.4180e+2, 2.2644e+3, 2.2141e+3, 1.1432e+3, 1.9251e+2, 1.1085e+3, 8.4669e+2, 1.0548e+3;
%!               5.9246e-4,-1.4654e-4, 2.8904e-4,-3.4929e-4,-3.5437e-4,-4.7675e-4,-1.0908e+0,-1.0396e+1,-3.9393e+1,-4.4699e+1,-3.5128e+1,-2.7784e+1,-4.7212e+1,-2.3520e+1,-5.3450e+1,-3.1288e+1,-1.1973e+1,-4.5325e+1;
%!               1.1578e-6, 1.3190e-7,-1.0014e-6, 4.9297e-7,-7.7033e-8,-6.1422e-7,-1.6373e-6, 4.2624e-6, 2.0069e-5, 2.8420e-5,-2.3158e-5, 8.9556e-6, 2.1817e-3, 7.9903e-3, 1.5984e-3, 5.8097e-3, 1.9400e-3, 1.4695e-3;
%!              -3.6487e-4, 1.5648e-4,-4.5766e-4, 3.9855e-4, 3.5389e-4, 3.3329e-4, 3.1139e-4, 2.1393e-4, 2.4068e-4, 3.1537e-4,-8.8979e-5, 5.3265e-4,-4.7878e-4, 3.8238e-4,-6.0843e-5,-2.6785e-5, 3.4619e-4, 6.8646e-5;
%!              -6.1033e-4, 2.8379e-5,-9.7554e-5,-6.8342e-6, 4.9697e-4, 3.1150e-4, 7.7475e-4,-1.4815e-4, 7.6708e-4, 4.2007e-4,-1.0776e-4,-6.9694e-4, 1.1868e-4,-2.2309e-4, 5.1034e-5, 4.5261e-4, 8.8260e-5, 1.9457e-5];

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  gctco = GCTCoordinates("t0", 987654321, "T", 86400, "alpha", alpha_ref, "delta", delta_ref, "fndot", fndot_ref, "detector", "L1", "ptolemaic", false);
%!  assert(all(abs(gctco - gctco_ref) < 1e-4 * abs(gctco_ref)));
