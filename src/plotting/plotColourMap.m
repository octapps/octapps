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

## Visualise a color map.
## Usage:
##   plotColourMap(map)
## where
##   map = colour map

function plotColourMap(map)

  ## check input
  assert(ismatrix(map) && size(map, 2) == 3);
  assert(min(map) >= 0 && max(map) <= 1);

  ## visualise colour map
  clf reset;
  subplot(1,2,1);
  n = size(map,1);
  image(1:n, linspace(0, 1, n), repmat(1:n, n, 1)');
  axis([1, n, 0, 1], "ticy", "xy");
  colormap(map);
  xlabel("Colour");
  ylabel("Colour map index");
  subplot(1,2,2);
  x = linspace(0, 1, n);
  plot(x, map(:,1), "r-", x, map(:,2), "g-", x, map(:,3), "b-", x, mean(map,2), "k-");
  legend("Red", "Green", "Blue", "Mean");
  xlabel("Colour map index");
  ylabel("Intensity");

endfunction
