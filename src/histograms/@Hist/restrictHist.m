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
  assert(is_function_handle(F));

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

  ## remove any unneeded zero bins in each dimension
  siz = size(hgrm.counts);
  for k = 1:dim

    ## sum counts over all other dimensions
    counts_k = hgrm.counts;
    for j = [1:k-1, k+1:dim]
      counts_k = sum(counts_k, j);
    endfor
    counts_k = squeeze(counts_k);

    ## find the minimum and maximum bins with non-zero count
    ## (excluding +/- infinity bins)
    nonz_k = find(counts_k > 0);
    minnonz_k = min(nonz_k(nonz_k > 1));
    maxnonz_k = max(nonz_k(nonz_k < siz(k)));

    ## extract non-zero bins
    hgrm.bins{k} = hgrm.bins{k}([1, minnonz_k:maxnonz_k+1, siz(k)+1]);

    ## extract non-zero counts
    [subs{1:dim}] = deal(":");
    subs{k} = [1, minnonz_k:maxnonz_k, siz(k)];
    hgrm.counts = subsref(hgrm.counts, substruct("()", subs));

  endfor

endfunction


%!test
%!  hgrm = Hist(2, {"lin", 0.01}, {"lin", 0.01});
%!  hgrm = addDataToHist(hgrm, rand(50000,2));
%!  hgrmx = restrictHist(hgrm, @(x,y) max(x) <= 0.5);
%!  hgrmy = restrictHist(hgrm, @(x,y) max(y) <= 0.3);
%!  assert(abs(meanOfHist(contractHist(hgrm, 1)) - 0.5) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrm, 2)) - 0.5) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrmx, 1)) - 0.25) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrmx, 2)) - 0.5) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrmy, 1)) - 0.5) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrmy, 2)) - 0.15) < 1e-2);

%!test
%!  hgrm = Hist(2, -1.0:0.1:2.0, -1.0:0.1:2.0);
%!  hgrm = addDataToHist(hgrm, rand(50000,2));
%!  count = histTotalCount(hgrm);
%!  hgrmx = restrictHist(hgrm, @(x,y) 0.0 <= min(x) && max(x) <= 1.0);
%!  hgrmy = restrictHist(hgrm, @(x,y) -0.5 <= min(y) && max(y) <= 1.5);
%!  hgrmxy = restrictHist(hgrm, @(x,y) max(x) <= 0.5 && max(y) <= 0.5);
%!  assert(histTotalCount(hgrmx) == count);
%!  assert(histTotalCount(hgrmy) == count);
%!  assert(abs(histTotalCount(hgrmxy) - 0.25*count) < 1e-2*count);
