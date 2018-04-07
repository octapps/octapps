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

## vol = AnsVolume ( dim )
## [can handle vector input]
##
## Return the "lattice-volume" (i.e. the volume of an elementary lattice-cell)
## for an An* lattice in 'dim' dimensions.
## This is referring to the lattice-definition used by AnsGenerator.m,
## i.e. Chap.4, Eq.(76) of Conway&Sloane(1999).

function vol = AnsVolume ( dim )

  vol = 1 ./ sqrt ( dim + 1 );

  return;

endfunction ## AnsVolume()

%!assert(AnsVolume(1) > 0)
%!assert(AnsVolume(2) > 0)
%!assert(AnsVolume(3) > 0)
%!assert(AnsVolume(4) > 0)
%!assert(AnsVolume(5) > 0)
