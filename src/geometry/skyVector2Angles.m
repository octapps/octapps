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
## @deftypefn {Function File} {@var{LongLat} =} skyVector2Angles ( @var{vSky} )
##
## Convert a sky-position given in terms of a 3-vector into 'longitude' and 'latitude'
## angles in the same reference frame (ie either in equatorial or ecliptic system).
##
## input @var{vSky} must be a N x 3 vector (N>=1), returns matrix
## of the form [ longitude, latitude ] with column-vectors
## longitude in [0, 2pi] and latitude in [-pi, pi]
##
## @heading Note
##
## the input vector doesn't need to be normalized
## @end deftypefn

function LongLat = skyVector2Angles ( vSky )

  ## check input
  [r, c] = size ( vSky );
  assert ( c == 3, "Invalid input vector must be N x 3, found %d x %d instead\n", r, c );

  ## normalize input vectors
  norms = sqrt ( sumsq ( vSky, 2 ) );
  normSky = norms(:) * ones(1,3);
  vSky = vSky ./ normSky;

  ## convert back to sky angles 'longitude' and 'latitude'
  long  = atan2 ( vSky(:,2), vSky(:,1) );       ## range = [-pi, pi]
  long ( long < 0 ) += 2 * pi;

  lat = asin ( vSky(:, 3) );    ## range is [-pi/2, pi/2]
  LongLat = [ long, lat ];

  return;

endfunction

%!test
%! Ntrials = 1000;
%! vnIn = randPointInNSphere ( 3, ones ( 1, Ntrials ) )';
%! LongLat = skyVector2Angles ( vnIn );
%! vnOut = skyAngles2Vector ( LongLat );
%! maxerr = max ( abs ( vnIn(:) - vnOut(:) ) );
%! assert ( maxerr < 1e-6 );
