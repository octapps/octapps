## Copyright (C) 2008 Reinhard Prix
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
## @deftypefn {Function File} {@var{coveringRadius} =} AnCoveringRadius ( @var{dim} )
##
## Return covering-radius for the An lattice in n dimensions
## referring to lattice-definition corresponding to the generator
## returned by getAnsLatticeGenerator.m, i.e. Chap.4, Eq.(52) in Conway&Sloane(1999):
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function coveringRadius = AnCoveringRadius ( dim )

  ## covering Radius of An is given in Chap.4, Eq.(54) in CS99
  rho = 1/sqrt(2);      ## packing radius
  a = round ( (dim + 1)/2 );
  coveringRadius = rho * sqrt ( 2 * a .* (dim + 1 - a) ./ (dim + 1) );

  return;

endfunction

%!assert(AnCoveringRadius(1) > 0)
%!assert(AnCoveringRadius(2) > 0)
%!assert(AnCoveringRadius(3) > 0)
%!assert(AnCoveringRadius(4) > 0)
%!assert(AnCoveringRadius(5) > 0)
