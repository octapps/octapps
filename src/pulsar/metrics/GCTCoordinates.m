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
##   coords         = GCTCoherentMetric(...)
##   [nu,...,nx,ny] = GCTCoherentMetric(...)
## where:
##   coords         = vector of GCT coordinates; order matches that of GCTCoherentMetric()
##   nu,...         = GCT frequency and spindown coordinates
##   nx             = GCT equatorial-x sky coordinate
##   ny             = GCT equatorial-y sky coordinate
## Options:
##   "t0":          value of t0, an overall reference time
##   "T":           value of T, the coherent time span
##   "alpha":       right ascension in radians
##   "delta":       declination in radians
##   "fndot":       frequency and spindowns in SI units
##   "detector":    detector name, e.g. H1
##   "ephemerides": Earth/Sun ephemerides from loadEphemerides()

function varargout = GCTCoordinates(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"t0", "real,scalar"},
               {"T", "real,strictpos,scalar"},
               {"alpha", "real,scalar"},
               {"delta", "real,scalar"},
               {"fndot", "real,vector"},
               {"detector", "char"},
               {"ephemerides", "a:swig_ref", []},
               []);
  smax = length(fndot) - 1;

  ## check options
  assert(smax <= 2, "Only up to second spindown supported");
  assert(isempty(strfind(detector, ",")), "Only a single detector is supported");

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## create coordinate indices
  [ii{1:5}] = deal([]);
  ii([1:smax+1,4,5]) = num2cell(1:3+smax);
  [nu, nud, nudd, nx, ny] = deal(ii{:});

  ## get detector information
  detInfo = new_MultiDetectorInfo;
  ParseMultiDetectorInfo(detInfo, CreateStringVector(detector), []);
  assert(detInfo.length == 1, "Could not parse detector '%s'", detector);
  detLat = detInfo.sites{1}.frDetector.vertexLatitudeRadians;
  detLong = detInfo.sites{1}.frDetector.vertexLongitudeRadians;

  ## get position of GMT at reference time t0
  zeroLong = mod(GreenwichMeanSiderealTime(LIGOTimeGPS(t0)), 2*pi);

  ## compute sky position vector
  n = [cos(alpha)*cos(delta), sin(alpha)*cos(delta), sin(delta)];

  ## extend frequency/spindown vector up to second spindown with zeros
  fndot(end+1:3) = 0;
  f = fndot(1);
  fd = fndot(2);
  fdd = fndot(3);

  ## compute dot product of orbital derivatives with sky position vector
  orbit_deriv = ComputeOrbitalDerivatives(smax+1, t0, ephemerides);
  xindot_n = zeros(orbit_deriv.length, 1);
  for i = 1:orbit_deriv.length
    xindot_n(i) = dot(orbit_deriv.data(i, :), n);
  endfor

  ## compute GCT sky position coordinates
  tau_E = LAL_REARTH_SI / LAL_C_SI;
  alphaD = zeroLong + detLong;
  n_prefac = 2*pi * f * tau_E * cos(detLat) * cos(delta);
  coord(nx) = n_prefac * cos(alpha - alphaD);
  coord(ny) = n_prefac * sin(alpha - alphaD);

  ## compute GCT frequency coordinates
  nu_prefac = 2*pi * (T / 2).^(1:smax+1);
  xi_n = xindot_n(1);
  xid_n = xindot_n(2);
  coord(nu) = nu_prefac(1) * (f + f*xid_n + fd*xi_n);
  if !isempty(nud)
    xidd_n = xindot_n(3);
    coord(nud) = nu_prefac(2) * (1/2*fd + 1/2*f*xidd_n + fd*xid_n + 1/2*fdd*xi_n);
    if !isempty(nudd)
      xiddd_n = xindot_n(4);
      coord(nudd) = nu_prefac(3) * (1/6*fdd + 1/6*f*xiddd_n + 1/2*fd*xidd_n + 1/2*fdd*xid_n);
    endif
  endif

  ## return coordinates, either as multiple output arguments or as a vector
  if nargout > 1
    varargout = mat2cell(coord, 1, ones(1, length(coord)));
  else
    varargout = {coord};
  endif

endfunction
