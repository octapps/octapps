## Copyright (C) 2011, 2013 Karl Wette
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
## @deftypefn {Function File} {@var{hgrm} =} rescaleHistBins ( @var{hgrm}, @var{s} )
##
## Rescale the bins of a histogram.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item s
## strictly positive scale to apply to bin in each dimension
##
## @end table
##
## @end deftypefn

function hgrm = rescaleHistBins(hgrm, s)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  assert(length(s) == dim);
  assert(all(s > 0));

  ## rescale bins
  for k = 1:dim
    hgrm.bins{k} *= s;
  endfor

endfunction

%!shared hgrm
%!  hgrm = createGaussianHist(1.2, 3.4, "binsize", 0.1);
%!assert(meanOfHist(rescaleHistBins(hgrm, 64.2)), 1.2 * 64.2, 1e-3)
