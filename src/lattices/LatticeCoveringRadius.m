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
## @deftypefn {Function File} {@var{R} =} LatticeCoveringRadius ( @var{dim}, @var{lattice} )
##
## return the covering radius for the given lattice
## lattice is one of the strings @{@code{Zn}, @code{An}, @code{Ans}@}
##
## @heading Note
## can handle vector input in @var{dim}
##
## @end deftypefn

function R = LatticeCoveringRadius ( dim, lattice )

  valid = { "Zn", "An", "Ans" };

  if ( strcmp ( lattice, valid{1}) )            ## Zn
    R = ZnCoveringRadius ( dim );
    return;
  elseif ( strcmp ( lattice, valid{2} ) )       ## An
    R = AnCoveringRadius ( dim );
    return;
  elseif ( strcmp ( lattice, valid{3} ) )       ## An*
    R = AnsCoveringRadius ( dim );
    return;
  else
    printf ("Unknown lattice-type, must be one of: ");
    printf (" '%s',", valid{1:length(valid)} );
    printf ("\n");
    error ("Illegal input.\n");
  endif

  return;

endfunction

%!assert(LatticeCoveringRadius(1, "Zn") > 0)
%!assert(LatticeCoveringRadius(1, "An") > 0)
%!assert(LatticeCoveringRadius(1, "Ans") > 0)
%!assert(LatticeCoveringRadius(2, "Zn") > 0)
%!assert(LatticeCoveringRadius(2, "An") > 0)
%!assert(LatticeCoveringRadius(2, "Ans") > 0)
%!assert(LatticeCoveringRadius(3, "Zn") > 0)
%!assert(LatticeCoveringRadius(3, "An") > 0)
%!assert(LatticeCoveringRadius(3, "Ans") > 0)
