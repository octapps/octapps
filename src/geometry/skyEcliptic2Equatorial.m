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

## Convert a sky-position given in terms of 'longitude' and 'latitude'
## angles into a unit vector vn = [nx, ny, nz] in the same reference frame
## (ie either in equatorial or ecliptic system).
##
## Usage:
##   skyEqu = skyEcliptic2Equatorial ( skyEcl )
##
## convert input sky-position in ecliptic reference frame into equatorial frame
##
## Input 3-vectors are interpreted as sky-vectors vn = [nx, ny, nz] (un-normalized),
## while 2-vectors are interpreted as sky angles [longitude, latitude],
## and the output uses the same format as the input (ie vector --> vector, angles-->angles).
## Multiple values can be input as column-vectors, ie Nx3 for vectors vn, Nx2 for angles
## [simple wrapper for skyRotateFrame()]

function skyEqu = skyEcliptic2Equatorial ( skyEcl )

  UnitsConstants;
  skyEqu = skyRotateFrame ( skyEcl, +IEARTH, [ 1; 0; 0] );	## rotation ecliptic->equatorial
  return;

endfunction

%!test
%! Ntrials = 10;
%! LongLatEclIn = [ unifrnd(0, 2*pi, Ntrials, 1 ), unifrnd(-pi/2, pi/2, Ntrials, 1 ) ];
%! vnEclIn = unifrnd(-1, 1, Ntrials, 3 );
%!
%! LongLatEqu1 = skyEcliptic2Equatorial ( LongLatEclIn );
%! vnEqu1 = skyEcliptic2Equatorial ( vnEclIn );
%!
%! LongLatEclOut = skyEquatorial2Ecliptic ( LongLatEqu1 );
%! vnEclOut 	 = skyEquatorial2Ecliptic ( vnEqu1 );
%!
%! err1 = max ( abs ( LongLatEclIn - LongLatEclOut )(:) );
%! err2 = max ( abs ( vnEclIn - vnEclOut )(:) );
%! assert ( (err1 < 1e-14) && (err2 < 1e-14 ) );

