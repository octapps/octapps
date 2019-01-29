## Copyright (C) 2019 Reinhard Prix
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
## @deftypefn {Function File} {@var{packingRadius} =} ZnPackingRadius ( @var{dim} )
##
## Return packing-radius for the Zn lattice in n dimensions
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function packingRadius = ZnPackingRadius ( dim )

  ## packing Radius of Zn is simply 1/2: see Chap.4,Sect.5 in Conway&Sloane(1999)
  packingRadius = 1/2;

  return;

endfunction

%!assert(ZnPackingRadius(1) == 1/2)
%!assert(ZnPackingRadius(5) == 1/2)

