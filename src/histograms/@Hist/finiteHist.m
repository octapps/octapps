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

## Return the finite bins and probabilities of a histogram
## Syntax:
##   [xb, px] = finiteHist(hgrm)
##   [xb, px] = finiteHist(hgrm, "normalised")
## where:
##   hgrm  = histogram class
##   xb    = finite bins
##   px    = finite probabilities

function [xb, px] = finiteHist(hgrm, varargin)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.xb);
  normalise = false;
  if length(varargin) > 0
    assert(strcmp(varargin{1}, "normalised"));
    normalise = true;
  endif

  ## extract finite grid from histogram
  xb = cellfun(@(x) x(2:end-1), hgrm.xb, "UniformOutput", false);
  ii = cellfun(@(x) 2:length(x)-2, hgrm.xb, "UniformOutput", false);
  px = hgrm.px(ii{:});

  if normalise

    ## compute areas of all probability bins
    areas = ones(size(px));
    for k = 1:dim
      dx = histBinGrids(hgrm, k, "dx");
      areas .*= dx;
    endfor

    ## determine which bins have non-zero area
    nzii = (areas > 0);

    ## normalise by total bin count in non-zero-area bins
    norm = sum(px(nzii));
    if norm > 0
      px ./= norm;
    endif

    ## further normalise each probability bin by its area,
    ## so bins with different areas are treated correctly
    px(nzii) ./= areas(nzii);

  endif

endfunction


## generate Gaussian histograms and test normalisation with equal/unequal bins
%!test
%! hgrm1 = addDataToHist(Hist(1), normrnd(0, 1, 1e6, 1), 0.01, 0);
%! hgrm2 = addDataToHistLogBins(Hist(1), normrnd(0, 1, 1e6, 1), 0.5, 50);
%! [xb1, px1] = finiteHist(hgrm1, "normalised");
%! [xb2, px2] = finiteHist(hgrm2, "normalised");
%! xc1 = histBinGrids(hgrm1, 1, "xc");
%! xc2 = histBinGrids(hgrm2, 1, "xc");
%! assert(mean(abs(px1 - normpdf(xc1, 0, 1))) < 0.005)
%! assert(mean(abs(px2 - normpdf(xc2, 0, 1))) < 0.005)
