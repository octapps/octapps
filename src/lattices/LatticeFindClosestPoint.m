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
## @deftypefn {Function File} {@var{closest} =} LatticeFindClosestPoint ( @var{x}, @var{lattice} )
##
## return the closest point of the @var{lattice} to the given point @var{x} in R^n
## This is just a wrapper to the lower-level @var{lattice}-specific functions.
## lattice is one of the strings @{@code{Zn}, @code{An}, @code{Ans}@}
##
## @heading Note
## can handle vector input in @var{x}
##
## @end deftypefn

function closest = LatticeFindClosestPoint ( x, lattice )

  valid = { "Zn", "An", "Ans" };

  if ( strcmp ( lattice, valid{1}) )            ## Zn
    closest = ZnFindClosestPoint ( x );
    return;
  elseif ( strcmp ( lattice, valid{2} ) )       ## An
    closest = AnFindClosestPoint ( x );
    return;
  elseif ( strcmp ( lattice, valid{3} ) )       ## An*
    closest = AnsFindClosestPoint ( x );
    return;
  else
    printf ("Unknown lattice-type, must be one of: ");
    printf (" '%s',", valid{1:length(valid)} );
    printf ("\n");
    error ("Illegal input.\n");
  endif

  return;

endfunction

%!assert(isvector(LatticeFindClosestPoint(rand(4, 1), "Zn")))
%!assert(isvector(LatticeFindClosestPoint(rand(4, 1), "An")))
%!assert(isvector(LatticeFindClosestPoint(rand(4, 1), "Ans")))
