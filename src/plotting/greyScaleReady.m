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

## Generate colour maps where the mean RGB intensity decreases
## linearly as a function of colour map index; these maps should
## therefore be printable in grey-scale. Colours range from white
## to the first colour of "name", via the second colour of "name".
##   map  = greyScaleReady("name", [n=64])
## where
##   map  = colour map
##   name = one of: "red-yellow", "red-magenta", "green-yellow",
##                  "blue-magenta", "green-cyan", "blue-cyan"
##   n    = number of colour map entries

function map = greyScaleReady(name, n=64)

  ## check input
  assert(ischar(name));
  assert(n > 0);

  ## create interpolation matrices
  a = [0 1; 1 1];
  b = [0 1; 0.5 1; 1 0];
  c = [0 1; 0.5 0; 1 0];

  ## generate colour map
  switch name
    case "red-yellow"
      map = makeColourMap(a, b, c, n);
    case "red-magenta"
      map = makeColourMap(a, c, b, n);
    case "green-yellow"
      map = makeColourMap(b, a, c, n);
    case "blue-magenta"
      map = makeColourMap(b, c, a, n);
    case "green-cyan"
      map = makeColourMap(c, a, b, n);
    case "blue-cyan"
      map = makeColourMap(c, b, a, n);
    otherwise
      error("%s: unknown colour map name '%s'", funcName, name);
  endswitch

endfunction
