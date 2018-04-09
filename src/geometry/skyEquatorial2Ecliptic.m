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
## @deftypefn {Function File} {@var{skyEcl} =} skyEquatorial2Ecliptic ( @var{skyEq} )
##
## Convert a sky-position given in terms of 'longitude' and 'latitude'
## angles into a unit vector @code{vn = [nx, ny, nz]} in the same reference frame
## (ie either in equatorial or ecliptic system).
##
## convert input sky-position in equatorial reference frame into ecliptic frame
##
## Input 3-vectors are interpreted as sky-vectors @code{vn = [nx, ny, nz]} (un-normalized),
## while 2-vectors are interpreted as sky angles [longitude, latitude],
## and the output uses the same format as the input (ie vector --> vector, angles-->angles).
## Multiple values can be input as column-vectors, ie Nx3 for vectors vn, Nx2 for angles
## @heading Note
## simple wrapper for @command{skyRotateFrame()}
##
## @end deftypefn

function skyEcl = skyEquatorial2Ecliptic ( skyEqu )

  UnitsConstants;
  skyEcl = skyRotateFrame ( skyEqu, -IEARTH, [ 1; 0; 0] );      ## rotation equatorial->ecliptic
  return;

endfunction

%!test
%! LongLatEqu = [ 1.5, -0.5; 2.6, 0.7 ];
%! LongLatEclCheck = [ 1.469781, -0.907669; 2.385547, 0.449178 ];       ## converted using frostydrew.org/utilities.dc/convert/tool-eq_coordinates/
%! LongLatEcl = skyEquatorial2Ecliptic ( LongLatEqu );
%! err = max ( abs ( LongLatEcl - LongLatEclCheck )(:) );
%! assert ( err < 1e-5 );
