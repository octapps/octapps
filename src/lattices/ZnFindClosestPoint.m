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
## @deftypefn {Function File} {@var{close} =} ZnFindClosestPoint ( @var{x} )
##
## return the closest point of the (hypercubic) Zn-lattice to the given point @var{x} in R^n
## based on Chap.20.2 in Conway&Sloane (1999). This is the most trivial case.
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function close = ZnFindClosestPoint ( x )

  [ dim, numPoints ] = size ( x );

  ## all we need to do is round the point to integers in all dimensions
  close = round ( x );

  return;

endfunction

%!test
%!  x = rand(3, 100000);
%!  dx = x - ZnFindClosestPoint(x);
%!  assert(max(sqrt(dot(dx, dx))) <= ZnCoveringRadius(3));
