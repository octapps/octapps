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
## @deftypefn {Function File} {@var{packingRadius} =} AnsPackingRadius ( @var{dim} )
##
## Return the packing-radius for An* lattice in n dimensions,
## from Chap.4, Eq.(79) in Conway&Sloane(1999)
## referring to lattice-definition corresponding to the generator
## returned by @command{AnsLatticeGenerator()}, i.e. Chap.4, Eq.(76) of CS99
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function packingRadius = AnsPackingRadius ( dim )

  packingRadius = 0.5 * sqrt ( dim ./ ( dim + 1 ) );

  return;

endfunction ## AnsPackingRadius()

%!assert(AnsPackingRadius(1) > 0)
%!assert(AnsPackingRadius(2) > 0)
%!assert(AnsPackingRadius(3) > 0)
%!assert(AnsPackingRadius(4) > 0)
%!assert(AnsPackingRadius(5) > 0)
