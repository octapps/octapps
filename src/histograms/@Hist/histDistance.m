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

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{d}, @var{KLD}, @var{JSD} ] =} histDistance ( @var{hgrm1}, @var{hgrm2} )
##
## Computes different distance measures between histograms
##
## @heading Arguments
## @table @var
## @item hgrm1
## @itemx hgrm2
## histogram objects
##
## @item d
## defined to be the sum of the absolute difference in probability density in
## each bin (for a common bin set), multiplied by the bin area.
##
## @item KLD
## is the (non-symmetric) Kullback–Leibler divergence D_KL(@var{hgrm1} || @var{hgrm2}) >= 0
## https://en.wikipedia.org/wiki/Kullback-Leibler_divergence
##
## @item JSD
## is the (symmetric) Jensen–Shannon divergence 0 <= JDS <= 1
## https://en.wikipedia.org/wiki/Jensen-Shannon_divergence
##
## @end table
##
## @end deftypefn

function [d, KLD, JSD] = histDistance(hgrm1, hgrm2)

  ## check input
  assert(isHist(hgrm1) && isHist(hgrm2));
  assert(length(hgrm1.bins) == length(hgrm2.bins));
  dim = length(hgrm1.bins);

  ## get union of all histogram bins in each dimension
  ubins = histBinUnions(hgrm1, hgrm2);

  ## resample histograms
  hgrm1 = resampleHist(hgrm1, ubins{:});
  hgrm2 = resampleHist(hgrm2, ubins{:});

  ## get histogram probability densities
  p1 = histProbs(hgrm1);
  p2 = histProbs(hgrm2);

  ## compute areas of all probability bins, not counting infinite bins
  areas = ones(size(p1));
  for k = 1:dim
    dbins = histBinGrids(hgrm1, k, "width");
    areas .*= dbins;
  endfor
  areas(isinf(areas)) = 0;

  ## compute area-weighted difference for each bin
  diff_area = abs(p1 - p2) .* areas;

  ## return distance
  d = sum(diff_area(:));

  ## compute discrete probability distributions
  P1 = p1 .* areas;
  P2 = p2 .* areas;
  ## compute Kullback–Leibler divergence D_KL(P1|P2)  between discrete probability distributions P1=hgrm1 and P2=hgrm2:
  KLD = compute_KLD ( P1, P2 );

  ## compute Jensen–Shannon divergence (symmetrized version of KLD)
  pM = 0.5 * ( P1 + P2 );
  JSD = 0.5 * ( compute_KLD ( P1, pM ) + compute_KLD ( P2, pM ) );

  return;

endfunction

function KLD = compute_KLD ( P, Q )
  iPos = find ( (P > eps) & (Q > eps) );
  KL0 = - P(iPos) .* log ( Q(iPos) ./ P(iPos) );
  KLD = sum ( KL0(:) );
  return;
endfunction

%!shared hgrm1, hgrm2
%!  hgrm1 = createGaussianHist(1.2, 3.4, "binsize", 0.1);
%!  hgrm2 = createGaussianHist(7.3, 3.4, "binsize", 0.1);
%!assert(histDistance(hgrm1, hgrm1), 0.00, 1e-3)
%!assert(histDistance(hgrm1, hgrm2), 1.26, 1e-3)
