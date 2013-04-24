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
##   hgrm{1,2} = histogram structs

function d = histDistance(hgrm1, hgrm2)

  ## check input
  assert(isHist(hgrm1) && isHist(hgrm2));
  assert(length(hgrm1.xb) == length(hgrm2.xb));
  dim = length(hgrm1.xb);

  ## resample histograms to common bin set
  for k = 1:dim

    ## get rounded bins
    [xb1, xb2] = roundHistBinBounds(hgrm1.xb{k}, hgrm2.xb{k});
    if length(xb1) != length(xb2) || xb1 != xb2

      ## common bin set
      xb = union(xb1, xb2);

      ## resample histograms
      hgrm1 = resampleHist(hgrm1, k, xb);
      hgrm2 = resampleHist(hgrm2, k, xb);

    endif

  endfor

  ## get normalised histogram data
  [xb1, px1] = finiteHist(hgrm1, "normalised");
  [xb2, px2] = finiteHist(hgrm2, "normalised");

  ## compute areas of all probability bins
  areas = ones(size(px1));
  for k = 1:dim
    dx = histBinGrids(hgrm1, k, "dx");
    areas .*= dx;
  endfor

  ## compute area-weighted difference for each bin
  diff_area = abs(px1 - px2) .* areas;

  ## return distance
  d = sum(diff_area(:));

endfunction
