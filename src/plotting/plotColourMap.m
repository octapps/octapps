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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{lum} =} plotColourMap ( @var{map}, [ @var{name} ] )
##
## Visualise a colour @var{map}.
##
## @heading Arguments
##
## @table @var
## @item map
## colour map
##
## @item name
## optional colour @var{map} name
##
## @item lum
## luma of colour map
##
## @end table
##
## @end deftypefn

function plotColourMap(map, name="")

  ## check input
  assert(ismatrix(map) && size(map, 2) == 3);
  assert(min(map) >= 0 && max(map) <= 1);

  ## Rec. 601 luma coefficients
  lr = 0.299;
  lg = 0.587;
  lb = 0.114;

  ## calculate colour map components and luma
  n = size(map,1);
  x = linspace(0, 1, n);
  r = map(:, 1);
  g = map(:, 2);
  b = map(:, 3);
  lum = r * 0.299 + g * 0.587 + b * 0.114;
  if nargout == 0
    return
  endif

  ## visualise colour map
  clf reset;
  subplot(1, 2, 1);
  image(1:n, x, repmat(1:n, n, 1)');
  axis([1, n, 0, 1], "ticy", "xy");
  colormap(map);
  if !isempty(name)
    xlabel(sprintf("Colour map '%s'", name));
  else
    xlabel("Colour map");
  endif
  ylabel("Colour map index");

  ## plot colour map components and luma
  subplot(1, 2, 2);
  plot(x, map(:,1), "r-", x, map(:,2), "g-", x, map(:,3), "b-", x, lum, "k-");
  legend("Red", "Green", "Blue", "Luma");
  xlabel("Colour map index");
  ylabel("Intensity");

endfunction

%!test
%!  plotColourMap(colormap());
