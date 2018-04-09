## Copyright (C) 2010, 2013 Karl Wette
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
## @deftypefn {Function File} {@var{x} =} drawFromHist ( @var{hgrm}, @var{N} )
##
## Generates random values drawn from the
## probability distribution given by the histogram.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item N
## number of random values to generate
##
## @item x
## generated random values
##
## @end table
##
## @end deftypefn

function x = drawFromHist(hgrm, N)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);

  ## get histogram probabilities
  prob = hgrm.counts;
  total = sum(hgrm.counts(:));
  if total == 0
    x = nan(N, dim);
    return;
  endif
  prob /= total;

  ## get histogram bins
  binlo = binhi = cell(1, dim);
  for k = 1:dim
    [binlo{k}, binhi{k}] = histBins(hgrm, k, "lower", "upper");
  endfor

  ## generate random indices to histogram bins, with appropriate probabilities
  [ii{1:dim}] = ind2sub(size(prob), discrete_rnd(1:numel(prob), prob(:)', N, 1));

  ## start with the lower bound of each randomly chosen bin and
  ## add a uniformly-distributed offset within that bin
  x = zeros(N, dim);
  for k = 1:dim
    dbin = binhi{k}(ii{k}) - binlo{k}(ii{k});
    x(:,k) = binlo{k}(ii{k}) + rand(length(ii{k}), 1).*dbin;
  endfor

endfunction

## create histograms for testing
%!shared hgrmA, hgrmB, hgrmC, N
%!  hgrmA = Hist(1, {"lin", "dbin", 0.1});
%!  hgrmB = Hist(1, {"log", "minrange", 0.1, "binsper10", 8});
%!  hgrmC = Hist(2, {"lin", "dbin", 0.1}, {"log", "minrange", 1.0, "binsper10", 8});
%!  N = 1e6;
%!  do
%!    x = randn(N, 2);
%!    oldhgrmA = hgrmA;
%!    hgrmA = addDataToHist(hgrmA, x(:,1));
%!    hgrmB = addDataToHist(hgrmB, x(:,1));
%!    hgrmC = addDataToHist(hgrmC, x(:,1:2));
%!    histerr = histDistance(oldhgrmA, hgrmA);
%!  until histerr < 1e-2

## test reproducing histograms
%!test
%!  thgrmA = Hist(1, {"lin", "dbin", 0.1});
%!  x = drawFromHist(hgrmA, N);
%!  thgrmA = addDataToHist(thgrmA, x);
%!  assert(histDistance(hgrmA, thgrmA) < 0.01);
%!test
%!  thgrmB = Hist(1, {"log", "minrange", 0.1, "binsper10", 8});
%!  x = drawFromHist(hgrmB, N);
%!  thgrmB = addDataToHist(thgrmB, x);
%!  assert(histDistance(hgrmB, thgrmB) < 0.01);
%!test
%!  thgrmC = Hist(2, {"lin", "dbin", 0.1}, {"log", "minrange", 1.0, "binsper10", 8});
%!  x = drawFromHist(hgrmC, 20*N);
%!  thgrmC = addDataToHist(thgrmC, x);
%!  assert(histDistance(hgrmC, thgrmC) < 0.01);
