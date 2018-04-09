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
## @deftypefn {Function File} {@var{S} =} contourc2struct ( @var{C} )
##
## Converts contour matrix @var{C} returned by contour
## functions into a easier-to-use array struct S
##
## @end deftypefn

function S = contourc2struct(C)

  S = struct;

  i = 0;
  while size(C, 2) > 0
    ++i;

    S(i).lev = C(1,1);

    n = C(2,1);
    assert(floor(n) == n);
    S(i).x = C(1,2:n+1);
    S(i).y = C(2,2:n+1);

    C = C(:,n+2:end);

  endwhile

endfunction

%!test
%!  [X, Y] = ndgrid(-10:10, -10:10);
%!  Z = X.^2 + Y.^2;
%!  C = contourc(Z);
%!  contourc2struct(C);
