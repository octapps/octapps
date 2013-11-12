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

## Extract histogram restricted to subregion of bins, as determined
## by the function 'F'.
## Usage
##   rhgrm = restrictHist(hgrm, F)
## where:
##   rhgrm = restricted histogram class
##   hgrm  = original histogram class
##   F     = restriction function; selects bins where
##             F([xl1, xh1], [xl2, xh2], ...)
##           evaluates true; xlk, xhk are the bin boundaries
##           of each bin in dimension 'k'.

function hgrm = restrictHist(hgrm, F)

  ## check input
  assert(isHist(hgrm));

  ## build bin boundary pairs
  dim = length(hgrm.bins);
  args = cell(1, dim);
  for k = 1:dim

    ## get bin boundaries
    [xl, xh] = histBinGrids(hgrm, k, "lower", "upper");

    ## create bin boundary pairs
    xlh = arrayfun(@horzcat, xl, xh, "UniformOutput", false);

    ## add to restrict function arguments
    args{k} = xlh;

  endfor

  ## evaluate restrict function for all bin boundary pairs over all dimensions
  r = cellfun(F, args{:});

  ## zero out bins where restrict function was false
  hgrm.counts(find(!r)) = 0;

endfunction


%!shared hgrm, hgrmx, hgrmy
%! hgrm = Hist(2,{"lin",0.01},{"lin",0.01});
%! hgrm = addDataToHist(hgrm, rand(50000,2));
%! hgrmx = restrictHist(hgrm,@(x,y) max(x)<=0.5);
%! hgrmy = restrictHist(hgrm,@(x,y) max(y)<=0.3);
%!assert(abs(meanOfHist(contractHist(hgrm,1)) - 0.5) < 1e-2)
%!assert(abs(meanOfHist(contractHist(hgrm,2)) - 0.5) < 1e-2)
%!assert(abs(meanOfHist(contractHist(hgrmx,1)) - 0.25) < 1e-2)
%!assert(abs(meanOfHist(contractHist(hgrmx,2)) - 0.5) < 1e-2)
%!assert(abs(meanOfHist(contractHist(hgrmy,1)) - 0.5) < 1e-2)
%!assert(abs(meanOfHist(contractHist(hgrmy,2)) - 0.15) < 1e-2)
