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
## @deftypefn {Function File} {@var{ret} =} getAnsLatticeProperties ( @var{dim} )
##
## Return a struct holding important properties of An* lattice in n-dimensions
## from Chap.4, Sect.6.6 in Conway&Sloane(1999):
##
## @end deftypefn

function ret = getAnsLatticeProperties ( dim )

  ret.generator = AnsGenerator ( dim );
  ret.packingRadius = AnsPackingRadius ( dim );
  ret.coveringRadius = AnsCoveringRadius ( dim );
  ret.volume = AnsVolume ( dim );
  ret.thickness = AnsThickness ( dim );
  ret.normalizedThickness = AnsNormalizedThickness ( dim );
  ret.minimalVectors = AnsMinimalVectors ( dim );
  ret.kissingNumber = AnsKissingNumber ( dim );
  ret.numVoronoiFacets = AnsNumVoronoiFacets ( dim );
  return;

endfunction ## getAnsLatticeProperties()

%!assert(isstruct(getAnsLatticeProperties(1)))
%!assert(isstruct(getAnsLatticeProperties(2)))
%!assert(isstruct(getAnsLatticeProperties(3)))
%!assert(isstruct(getAnsLatticeProperties(4)))
%!assert(isstruct(getAnsLatticeProperties(5)))
