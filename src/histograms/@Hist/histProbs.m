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

## Return the probabily densities of each histogram bin
## Syntax:
##   prob = histProbs(hgrm)
## where:
##   hgrm = histogram class
##   prob = probability densities

function prob = histProbs(hgrm)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);

  ## start with counts and normalise by total count
  prob = hgrm.counts;
  norm = sum(prob);
  if norm > 0
    prob ./= norm;
  endif

  ## compute areas of all probability bins
  areas = ones(size(prob));
  for k = 1:dim
    dbins = histBinGrids(hgrm, k, "width");
    areas .*= dbins;
  endfor

  ## determine which bins have non-zero area
  nzii = (areas > 0);

  ## further normalise each probability bin by its area,
  ## so bins with different areas are treated correctly
  prob(nzii) ./= areas(nzii);

endfunction


## generate Gaussian histograms and test normalisation
%!test
%! hgrm1 = addDataToHist(Hist(1), normrnd(0, 1, 1e6, 1), 0.01, 0);
%! p1 = histProbs(hgrm1); c1 = histBinGrids(hgrm1, 1, "centre");
%! assert(mean(abs(p1 - normpdf(c1, 0, 1))) < 0.005)
