## Copyright (C) 2011 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {@var{F} =} AntennaPattern ( @var{a}, @var{b}, @var{x}, @var{y}, @var{zeta} )
##
## Calculate the antenna pattern of an interferometer
##
## @heading Arguments
##
## @table @var
## @item F
## antenna pattern
##
## @item a
## @itemx b
## detector null vectors in equatorial coordinates
##
## @item x
## @itemx y
## polarisation null vectors in equatorial coordinates
##
## @item zeta
## angle between interferometer arms in radians
##
## @end table
##
## @end deftypefn

function F = AntennaPattern(a, b, x, y, zeta)

  ## make sure input are the same size
  if isscalar(zeta)
    zeta .*= ones(1, size(a, 2));
  elseif !(isvector(zeta) && length(zeta) == size(a, 2))
    error("%s: zeta is not the right size", funcName);
  endif
  assert(all(size(a) == size(b)));
  assert(all(size(b) == size(x)));
  assert(all(size(x) == size(y)));

  ## antenna pattern
  F = sin(zeta) .* ( dot(a,x,1).*dot(b,y,1) + dot(a,y,1).*dot(b,x,1) );

endfunction

%!assert(AntennaPattern([1,0,0], [0,1,0], [0.5,0.5,0], [0.5,-0.5,0], pi/2), [0,0,0], 1e-3)
