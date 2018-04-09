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
## @deftypefn {Function File} {@var{vol} =} ZnVolume ( @var{dim} )
##
## Return the "lattice-volume" (i.e. the volume of an elementary lattice-cell)
## for a Zn lattice in @var{dim} dimensions.
## This is referring to the lattice-definition used by ZnGenerator.m,
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function vol = ZnVolume ( dim )

  ## this is trivial of course, but included for completeness of 'LatticeVolume()'
  vol = ones ( 1, length(dim) );

  return;

endfunction ## ZnVolume()

%!assert(ZnVolume(1) > 0)
%!assert(ZnVolume(2) > 0)
%!assert(ZnVolume(3) > 0)
%!assert(ZnVolume(4) > 0)
%!assert(ZnVolume(5) > 0)
