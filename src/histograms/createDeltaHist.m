## Copyright (C) 2013 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{hgrm} =} createDeltaHist ( @var{x0} )
##
## Creates a histogram representing a delta function at a given value
##
## @heading Arguments
##
## @table @var
## @item hgrm
## delta function histogram
##
## @item x0
## location of delta function
##
## @end table
##
## @end deftypefn

function hgrm = createDeltaHist(x0)

  ## create histogram of delta function
  hgrm = addDataToHist(Hist(1, [x0, x0+eps]), x0);

endfunction

%!test
%!  createDeltaHist(1.23);
