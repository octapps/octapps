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
## @deftypefn {Function File} {@var{ret} =} AnsKissingNumber ( @var{dim} )
##
## Return the "kissing number", i.e. number of touching spheres to one lattice cell
## for an An* lattice in n dimensions, Sect.6.6 in Conway&Sloane(1999)
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function ret = AnsKissingNumber ( dim )

  ret = 2 * dim + 2;

  return;

endfunction

%!assert(AnsKissingNumber(1) > 0)
%!assert(AnsKissingNumber(2) > 0)
%!assert(AnsKissingNumber(3) > 0)
%!assert(AnsKissingNumber(4) > 0)
%!assert(AnsKissingNumber(5) > 0)
