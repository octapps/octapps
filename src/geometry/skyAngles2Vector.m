## Copyright (C) 2016 Reinhard Prix
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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{vn} =} skyAngles2Vector ( [ @var{longitude}, @var{latitude} ] )
##
## Convert a sky-position given in terms of @var{longitude} and @var{latitude}'
## angles into a unit vector @code{vn = [nx, ny, nz]} in the same reference frame
## (ie either in equatorial or ecliptic system).
##
## inputs @{longitude, @var{latitude}@} are allowed to be vectors, ie the input
## LongLat must be of size N x 2.
## returns unit-vector @code{vn = [ nx, ny, nz ]} of column-vectors nx,ny,nz
##
## @end deftypefn

function vn = skyAngles2Vector ( LongLat )

  [r, c] = size ( LongLat );
  assert ( c == 2, "Invalid input, LongLat must be N x 2, got %d x %d\n", r, c );

  long = LongLat(:, 1);
  lat  = LongLat(:, 2);
  minLong = min(long);
  maxLong = max(long);
  assert ( (minLong >= 0) && (maxLong <= 2*pi), "Suspicious input range for longitude not within [0, 2pi]: [%g, %g]\n", minLong, maxLong );
  minLat = min(lat);
  maxLat = max(lat);
  assert ( (minLat >= -pi/2) && (maxLat <= pi/2), "Suspicious input range for latitude not within [-pi, pi]: [%g, %g]\n", minLat, maxLat );

  ## compute unit vector
  cosLong = cos(long);
  sinLong = sin(long);
  cosLat  = cos(lat);
  sinLat  = sin(lat);
  vn = [ cosLong .* cosLat, sinLong .* cosLat, sinLat ];
  return;

endfunction

%!test
%! Ntrials = 1000;
%! LongLatIn = [ unifrnd(0, 2*pi, Ntrials, 1 ), unifrnd(-pi/2, pi/2, Ntrials, 1) ];
%! vn = skyAngles2Vector ( LongLatIn );
%! LongLatOut = skyVector2Angles ( vn );
%! maxerr = max ( abs ( LongLatIn(:) - LongLatOut(:) ) );
%! assert ( maxerr < 1e-6 );
