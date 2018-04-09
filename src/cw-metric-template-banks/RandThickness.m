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
## @deftypefn {Function File} {@var{ret} =} RandThickness ( @var{dim}, @var{falseDismissal} )
##
## Return the thickness of an @var{dim}-dimensional random-template
## grid with given @var{falseDismissal} probability
##
## @heading Note
## can handle vector input in @var{dim}
##
## @end deftypefn

function ret = RandThickness ( dim, falseDismissal )

  ret = - log(falseDismissal) * ones ( size(dim) );

endfunction

%!assert(RandThickness(1, 0.05) > 0)
%!assert(RandThickness(2, 0.05) > 0)
%!assert(RandThickness(3, 0.05) > 0)
%!assert(RandThickness(4, 0.05) > 0)
%!assert(RandThickness(5, 0.05) > 0)
