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

## Generate colour maps where the "luma" (brightness) decreases
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

  ## Rec. 601 luma coefficients
  lr = 0.299;
  lg = 0.587;
  lb = 0.114;

  ## target minimum and maximum intensities
  iM = 1.0;
  im = 0.35;

  ## choose interpolation constants
  rx = gx = bx = ry = gy = by = iM;
  switch name
    case "red-yellow"
      x = lb;
      y = lb + lg;
      bx = by = gy = im;
    case "red-magenta"
      x = lg;
      y = lg + lb;
      gx = gy = by = im;
    case "green-yellow"
      x = lb;
      y = lb + lr;
      bx = by = ry = im;
    case "blue-magenta"
      x = lg;
      y = lg + lr;
      gx = gy = ry = im;
    case "green-cyan"
      x = lr;
      y = lr + lb;
      rx = ry = by = im;
    case "blue-cyan"
      x = lr;
      y = lr + lg;
      rx = ry = gy = im;
    otherwise
      error("%s: unknown colour map name '%s'", funcName, name);
  endswitch

  ## create interpolation matrices
  r = [0, iM; x, rx; y, ry; 1, im];
  g = [0, iM; x, gx; y, gy; 1, im];
  b = [0, iM; x, bx; y, by; 1, im];

  ## generate colour map
  map = makeColourMap(r, g, b, n);

endfunction


%!test greyScaleReady("red-yellow");
%!test greyScaleReady("red-magenta");
%!test greyScaleReady("green-yellow");
%!test greyScaleReady("blue-magenta");
%!test greyScaleReady("green-cyan");
%!test greyScaleReady("blue-cyan");


%!demo
%!  [x, y] = ndgrid(-49:49, -49:49);
%!  img = round(100*exp(-(x.^2 + y.^2)/1250));
%!  img(:, 50:99) = repmat((100:-1:2)', 1, 50);
%!  names = {"red-yellow", "red-magenta", "green-yellow", "blue-magenta", "green-cyan", "blue-cyan"};
%!  map = [];
%!  for n = 1:6
%!    map = [map; greyScaleReady(names{n}, 100)];
%!  endfor
%!  figure(1);
%!  colormap(map);
%!  for n = 1:6
%!    subplot(2, 3, n);
%!    image((n-1)*100 + img);
%!    axis off;
%!    title(sprintf("greyScaleReady(\"%s\")", names{n}));
%!  endfor
