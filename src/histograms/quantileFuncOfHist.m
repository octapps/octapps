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
## @deftypefn {Function File} {q.f. =} quantileFuncOfHist ( @var{hgrm}, @var{p}, [ @var{k} = 1 ] )
##
## Evaluate the quantile function (q.f.) of a histogram.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item p
## quantile probability, in the range [0, 1]
##
## @item k
## dimension over which to evaluate the q.f.
##
## @end table
##
## @end deftypefn

function qf = quantileFuncOfHist(hgrm, p, k = 1)

  ## check input
  assert(isa(hgrm, "Hist"));
  dim = histDim(hgrm);
  assert(isscalar(p) && 0 <= p && p <= 1);
  assert(isscalar(k) && 1 <= k && k <= dim);

  ## get probability densities
  prob = histProbs(hgrm, "finite");

  ## multiply by areas of all probability bins
  for i = 1:dim
    dbins = histBinGrids(hgrm, i, "finite", "width");
    prob .*= dbins;
  endfor

  ## calculate cumulative probabilities along dimension k
  siz = size(prob);
  siz(k) += 1;
  cumprob = zeros(siz);
  sizii = 1:length(siz);
  [subs{sizii}] = ndgrid(arrayfun(@(n) 1:n, size(prob), "UniformOutput", false){:});
  subs{k} += 1;
  cumprob(sub2ind(siz, subs{:})) = cumsum(prob, k);

  ## calculate normalisation from total probability of dimension k
  [subs{sizii}] = ndgrid(arrayfun(@(n) 1:n, siz, "UniformOutput", false){:});
  subs{k} = siz(k)*ones(siz);
  norm = cumprob(sub2ind(siz, subs{:}));

  ## normalise probabilities
  cumprob ./= norm;

  ## get lower and upper cumulative probabilities containing 'p'
  nn = siz;
  nn(sizii == k) = 1;
  [subs{sizii}] = ndgrid(arrayfun(@(n) 1:n, nn, "UniformOutput", false){:});
  norm1 = norm(sub2ind(siz, subs{:}));
  if p == 1
    subsk = sum(cumprob < 1, k);
  else
    subsk = sum(cumprob <= p, k);
  endif
  subsk(find(norm1 == 0.0)) = 1;
  subs{k} = subsk;
  cumproblower = cumprob(sub2ind(siz, subs{:}));
  subs{k} += 1;
  cumprobupper = cumprob(sub2ind(siz, subs{:}));

  ## calculate quantile function
  [xl, dx] = histBins(hgrm, k, "finite", "lower", "width");
  xlk = reshape(xl(subsk), size(cumproblower));
  dxk = reshape(dx(subsk), size(cumproblower));
  qf = squeeze(xlk + dxk .* (p - cumproblower) ./ (cumprobupper - cumproblower));

endfunction

## test quantile function with Gaussian/uniform histogram
%!shared hgrm
%!  hgrm = Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1});
%!  hgrm = addDataToHist(hgrm, [normrnd(1.7, sqrt(2.3), 1e7, 1), rand(1e7, 1)]);
%!assert(abs(quantileFuncOfHist(hgrm, normcdf(-1), 1) - (1.7 - sqrt(2.3))) < 0.01)
%!assert(abs(quantileFuncOfHist(hgrm, normcdf( 0), 1) - (1.7)) < 0.01)
%!assert(abs(quantileFuncOfHist(hgrm, normcdf(+1), 1) - (1.7 + sqrt(2.3))) < 0.01)
%!assert(max(abs(quantileFuncOfHist(hgrm, 0.33, 2)(50:end-50) - 0.33)) < 0.05)
%!assert(max(abs(quantileFuncOfHist(hgrm, 0.77, 2)(50:end-50) - 0.77)) < 0.05)
