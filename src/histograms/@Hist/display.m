## Copyright (C) 2010, 2016 Karl Wette
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

## Display a histogram object.
## Syntax:
##   display(hgrm)
## where:
##   hgrm = histogram object

function s = display(hgrm)

  ## check input
  assert(isHist(hgrm));
  dim = histDim(hgrm);

  ## display histogram
  in = inputname(1);
  if length(in) > 0
    printf("%s = ", in);
  endif
  printf("{histogram: count=%i, range=", histTotalCount(hgrm));
  printf("[%g,%g]", histRange(hgrm)');
  printf("}\n");

endfunction
