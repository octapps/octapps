## Copyright (C) 2010 Karl Wette
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

## Generates random values drawn from the
## probability distribution given by the histogram.
## Syntax:
##   x    = drawFromHist(hgrm, N)
## where:
##   hgrm = histogram class
##   N    = number of random values to generate
##   x    = generated random values

function x = drawFromHist(hgrm, N)

  ## check input
  assert(isHist(hgrm));
  dim = histDim(hgrm);

  ## get histogram bins and probability densities
  binlo = binhi = cell(1, dim);
  for k = 1:dim
    [binlo{k}, binhi{k}] = histBins(hgrm, k, "lower", "upper");
  endfor
  prob = histProbs(hgrm);

  ## generate random indices to histogram bins, with appropriate probabilities
  [ii{1:dim}] = ind2sub(size(prob), discrete_rnd(1:numel(prob), prob(:)', N, 1));

  ## start with the lower bound of each randomly
  ## chosen bin and add a uniformly-distributed
  ## offset within that bin
  x = zeros(N, dim);
  for k = 1:dim
    dbin = binhi{k}(ii{k}) - binlo{k}(ii{k});
    x(:,k) = binlo{k}(ii{k}) + rand(size(ii{k})).*dbin;
  endfor

endfunction


## generate Gaussian histogram and test reproducing it
%!test
%! hgrm1 = createGaussianHist(1.2, 3.4, "err", 1e-3, "binsize", 0.1);
%! x = drawFromHist(hgrm1, 1e6);
%! hgrm2 = addDataToHist(Hist(1, {"lin", "dbin", 0.1}), x(:));
%! assert(histDistance(hgrm1, hgrm2) < 0.05)
