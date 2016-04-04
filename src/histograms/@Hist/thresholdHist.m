## Copyright (C) 2015 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Set a threshold on the histogram probability of each bin; bins with
## probability below the threshold have their count set to zero. The
## histogram is then trimmed: in each dimension, the lowest/highest bins
## are removed until such bins contain at least one count above threshold.
## Usage:
##   thgrm = thresholdHist(hgrm, pth)
## where:
##   thgrm = thresholded histogram class
##   hgrm  = original histogram class
##   pth   = probability threshold

function hgrm = thresholdHist(hgrm, pth)

  ## check input
  assert(isHist(hgrm));
  assert(isscalar(pth) && 0 <= pth && pth <= 1);
  dim = length(hgrm.bins);

  ## zero count in bins with probability below threshold
  prob = histProbs(hgrm);
  hgrm.counts(find(prob <= pth)) = 0;

  ## trim histograms
  newbins = {};
  for k = 1:dim

    ## permute dimension k to beginning of array, then flatten other dimensions
    prob = histProbs(hgrm);
    perm = [k 1:(k-1) (k+1):max(dim,length(size(prob)))];
    prob = permute(prob, perm);
    siz = size(prob);
    prob = reshape(prob, siz(1), []);

    ## find contiguous area of bins above threshold in this dimension
    ii = repmat(reshape(1:size(prob, 1), [], 1), 1, size(prob, 2));
    ii(prob <= pth) = NaN;
    iimin = min(ii(:));
    iimax = max(ii(:));

    ## select bin range to resize histogram to
    newbins{k} = hgrm.bins{k}([iimin, iimax+1]);

  endfor
  hgrm = restrictHist(hgrm, newbins{:});

endfunction


%!test
%!  hgrm = Hist(3, {"lin", "dbin", 1}, {"lin", "dbin", 1}, {"lin", "dbin", 1});
%!  hgrm = addDataToHist(hgrm, [-4.5:4.5; 3.5:12.5; 10.5:19.5]');
%!  rng = histRange(hgrm);
%!  hgrm2 = thresholdHist(hgrm, 0);
%!  for k = 1:3
%!    [xl, xh] = histBins(hgrm2, k, "lower", "upper");
%!    assert(rng(k, 1) == xl(2));
%!    assert(rng(k, 2) == xh(end-1));
%!  endfor
