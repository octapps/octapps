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
