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
## @deftypefn {Function File} {@var{ret} =} RandNormalizedThickness ( @var{dim}, @var{falseDismissal} )
##
## Return the normalized thickness of an 'dim'-dimensional random-template
## grid with given falseDismissal probability
##
## @heading Note
## can handle vector input in @var{dim}
##
## @end deftypefn

function ret = RandNormalizedThickness ( dim, falseDismissal )
  ## compute the normalized thickness, i.e. number of templates per
  ## volume for unity covering radius [ie mismatch^(1/2)], as
  ## a function of dimension and falseDismissal probability

  ret = - log(falseDismissal) ./ UnitHypersphereVolume ( dim );

endfunction

%!assert(RandNormalizedThickness(1, 0.05) > 0)
%!assert(RandNormalizedThickness(2, 0.05) > 0)
%!assert(RandNormalizedThickness(3, 0.05) > 0)
%!assert(RandNormalizedThickness(4, 0.05) > 0)
%!assert(RandNormalizedThickness(5, 0.05) > 0)
