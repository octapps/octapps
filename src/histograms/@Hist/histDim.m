## Copyright (C) 2013 Karl Wette
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
## @deftypefn {Function File} {@var{dim} =} histDim ( @var{hgrm} )
##
## Returns the dimensionality of a histogram object.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item dim
## dimensionality of the histogram
##
## @end table
##
## @end deftypefn

function dim = histDim(hgrm)

  ## check input
  assert(isHist(hgrm));

  ## return dimensionality
  dim = length(hgrm.bins);

endfunction

%!assert(histDim(Hist(1, {"lin", "dbin", 0.1})), 1)
%!assert(histDim(Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1})), 2)
%!assert(histDim(Hist(3, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1})), 3)
%!assert(histDim(Hist(4, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1})), 4)
%!assert(histDim(Hist(5, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1})), 5)
