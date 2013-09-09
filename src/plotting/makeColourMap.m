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

## Generate a colour map by interpolating colour intensities.
## Usage:
##   map   = makeColourMap(r, g, b, [n=64])
## where
##   map   = colour map
##   r,g,b = m-by-2 arrays of interpolation coefficients
##             [x1, c1; x2, c2; ...]
##           where x indexes the colour map, 0<=x<=1
##                 c is the red/gree/blue colour at x
##   n     = number of colour map entries

function map = makeColourMap(r, g, b, n=64)

  ## check input
  assert(ismatrix(r) && size(r, 2) == 2);
  assert(ismatrix(g) && size(g, 2) == 2);
  assert(ismatrix(b) && size(b, 2) == 2);
  assert(min(r(:, 1)) == 0 && max(r(:, 1)) == 1);
  assert(min(g(:, 1)) == 0 && max(g(:, 1)) == 1);
  assert(min(b(:, 1)) == 0 && max(b(:, 1)) == 1);
  assert(min(r(:, 2)) >= 0 && max(r(:, 2)) <= 1);
  assert(min(g(:, 2)) >= 0 && max(g(:, 2)) <= 1);
  assert(min(b(:, 2)) >= 0 && max(b(:, 2)) <= 1);
  assert(n > 0);

  ## generate colour map
  m = linspace(0, 1, n);
  mr = interp1(r(:, 1), r(:, 2), m);
  mg = interp1(g(:, 1), g(:, 2), m);
  mb = interp1(b(:, 1), b(:, 2), m);
  map = [mr(:), mg(:), mb(:)];
  map(!isfinite(map)) = 0;
  map(min(map) < 0) = 0;
  map(max(map) > 1) = 1;

endfunction
