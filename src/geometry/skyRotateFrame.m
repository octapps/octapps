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
## @deftypefn {Function File} {@var{skyOut} =} skyRotateFrame ( @var{skyIn}, @var{angle}, @var{axis} )
##
## Convert a sky-position given in terms of 'longitude' and 'latitude'
## angles into a unit vector @code{vn = [nx, ny, nz]} in the same reference frame
## (ie either in equatorial or ecliptic system).
##
## convert input sky-position by rotating the reference by @var{angle} around 3-vector @var{axis}'
##
## Input 3-vectors are interpreted as sky-vectors @code{vn = [nx, ny, nz]} (un-normalized),
## while 2-vectors are interpreted as sky angles @code{[longitude, latitude]},
## and the output uses the same format as the input (ie vector --> vector, angles-->angles).
## Multiple values can be input as column-vectors, ie Nx3 for vectors vn, Nx2 for angles
##
## @end deftypefn

function skyOut = skyRotateFrame ( skyIn, angle, axis )

  ## check input
  [ r, c ] = size ( skyIn );
  assert ( (c == 2) || (c == 3), "Invalid input vector 'skyIn' must be either Nx2 (for sky-angles) or Nx3 (for sky-vectors), got %d x %d\n", r, c );

  haveAngles = ( c == 2 );
  ## if angles input, convert them to vectors first
  if ( haveAngles )
    vnIn = skyAngles2Vector ( skyIn );
  else
    vnIn = skyIn;
  endif
  rotM = rotationMatrix ( angle, axis );        ## rotation matrix in-->out
  vnOut = rotM * vnIn';
  vnOut = vnOut';       ## return in N x 3 format

  ## return in same 'coordinates' as input: sky-vector or sky-angles
  if ( haveAngles )
    skyOut = skyVector2Angles ( vnOut );
  else
    skyOut = vnOut;
  endif

  return;

endfunction

%!assert(skyRotateFrame([0.1, 2.3, 4.5], 1.234, [9.8, 7.6, 5.4]), [3.0863, -1.0902, 3.8518], 1e-3)
