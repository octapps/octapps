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

## Computes a distance between histograms, defined to be the
## sum of the absolute difference in probability density in
## each bin (for a common bin set), multiplied by the bin area.
## Syntax:
##   d = histDistance(hgrm1, hgrm2)
## where:
##   hgrm{1,2} = histogram classes

function d = histDistance(hgrm1, hgrm2)

  ## check input
  assert(isHist(hgrm1) && isHist(hgrm2));
  assert(length(hgrm1.bins) == length(hgrm2.bins));
  dim = length(hgrm1.bins);

  ## resample histograms to common bin set
  for k = 1:dim

    ## get rounded bins
    [bins1, bins2] = roundHistBinBounds(hgrm1.bins{k}, hgrm2.bins{k});
    if length(bins1) != length(bins2) || bins1 != bins2

      ## common bin set
      bins = union(bins1, bins2);

      ## resample histograms
      hgrm1 = resampleHist(hgrm1, k, bins);
      hgrm2 = resampleHist(hgrm2, k, bins);

    endif

  endfor

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

endfunction
