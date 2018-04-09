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
## @deftypefn {Function File} {@var{ret} =} AnsNumVoronoiFacets ( @var{dim} )
##
## Return the number of Voronoi-facets for An* lattice, which corresponds
## to the maximal number of facets of an n-dimension parallelohedron (see CS99),
## namely 2 ( 2^@var{dim} - 1 )
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function ret = AnsNumVoronoiFacets ( dim )

  ret = 2 * ( 2.^dim - 1 );

  return;

endfunction

%!assert(AnsNumVoronoiFacets(1) > 0)
%!assert(AnsNumVoronoiFacets(2) > 0)
%!assert(AnsNumVoronoiFacets(3) > 0)
%!assert(AnsNumVoronoiFacets(4) > 0)
%!assert(AnsNumVoronoiFacets(5) > 0)
