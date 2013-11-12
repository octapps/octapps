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

## Evaluate the cumulative distribution function (c.d.f) of a histogram.
## Syntax:
##   cdf = cumulativeDistOfHist(hgrm, x, [k = 1])
## where:
##   hgrm = histogram class
##   x    = argument to the c.d.f.
##   k    = dimension over which to evaluate the c.d.f.

function cdf = cumulativeDistOfHist(hgrm, x, k = 1)

  ## check input
  assert(isHist(hgrm));
  dim = histDim(hgrm);
  assert(isscalar(k) && 1 <= k && k <= dim);

  ## get probability densities
  prob = histProbs(hgrm, "finite");
  siz = size(prob);

  ## get bins along dimension k
  [xl, xh] = histBins(hgrm, k, "finite", "lower", "upper");
  if x <= xl(1) || xh(end) <= x
    siz(k) = 1;
    cdf = (xh(1) <= x) * ones(siz);
    return;
  endif

  ## multiply by areas of all probability bins
  for i = 1:dim
    dbins = histBinGrids(hgrm, i, "finite", "width");
    prob .*= dbins;
  endfor

  ## compute cumulative probability up to bin containing 'x'
  i = min(find(x < xl));
  sizii = 1:length(siz);
  [subs{sizii}] = ndgrid(arrayfun(@(n) 1:n, ifelse(sizii == k, i-1, siz), "UniformOutput", false){:});
  cdf = sum(prob(sub2ind(siz, subs{:})), k);

  ## add cumulative probability from bin containing 'x'
  [subs{sizii}] = ndgrid(arrayfun(@(n) 1:n, ifelse(sizii == k, 1, siz), "UniformOutput", false){:});
  subs{k} = i * ones(size(subs{k}));
  cdf += (x - xl(i)) ./ (xh(i) - xl(i)) .* prob(sub2ind(siz, subs{:}));

  ## normalise probabilities
  cdf ./= sum(prob, k);

endfunction


## test cumulative distribution function with Gaussian/uniform histogram
%!shared hgrm
%! hgrm = Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1});
%! hgrm = addDataToHist(hgrm, [normrnd(1.7, sqrt(2.3), 1e7, 1), rand(1e7, 1)]);
%!assert(abs(cumulativeDistOfHist(hgrm, 1.7 - sqrt(2.3), 1) - normcdf(-1)) < 0.005)
%!assert(abs(cumulativeDistOfHist(hgrm, 1.7, 1) - normcdf(0)) < 0.005)
%!assert(abs(cumulativeDistOfHist(hgrm, 1.7 + sqrt(2.3), 1) - normcdf(+1)) < 0.005)
%!assert(max(abs(cumulativeDistOfHist(hgrm, 0.33, 2)(30:end-30) - 0.33)) < 0.06)
%!assert(max(abs(cumulativeDistOfHist(hgrm, 0.77, 2)(30:end-30) - 0.77)) < 0.06)
