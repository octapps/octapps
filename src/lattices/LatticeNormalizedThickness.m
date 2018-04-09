## Copyright (C) 2014 Karl Wette
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
## @deftypefn {Function File} {@var{R} =} LatticeNormalizedThickness ( @var{dim}, @var{lattice} )
##
## returns normalized thicknesses in n dimensions
## lattice is one of the strings @{ "Zn", "Ans" @}
##
## @heading Note
## can handle vector input in @var{dim}
##
## @end deftypefn

function R = LatticeNormalizedThickness ( dim, lattice )

  valid = { "Zn", "Ans" };

  if ( strcmp ( lattice, valid{1}) )            ## Zn
    R = ZnNormalizedThickness ( dim );
    return;
  elseif ( strcmp ( lattice, valid{2} ) )       ## An*
    R = AnsNormalizedThickness ( dim );
    return;
  else
    printf ("Unknown lattice-type, must be one of: ");
    printf (" '%s',", valid{1:length(valid)} );
    printf ("\n");
    error ("Illegal input.\n");
  endif

  return;

endfunction

%!assert(LatticeNormalizedThickness(1, "Zn") > 0)
%!assert(LatticeNormalizedThickness(1, "Ans") > 0)
%!assert(LatticeNormalizedThickness(2, "Zn") > 0)
%!assert(LatticeNormalizedThickness(2, "Ans") > 0)
%!assert(LatticeNormalizedThickness(3, "Zn") > 0)
%!assert(LatticeNormalizedThickness(3, "Ans") > 0)
