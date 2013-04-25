## Copyright (C) 2011 Karl Wette
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

## Adds histograms together.
## Syntax:
##   hgrmt = addHists(hgrm, hgrm, ...)
## where:
##   hgrm  = histogram classes
##   hgrmt = total histogram

function hgrm = addHists(varargin)

  ## check input
  assert(length(varargin) > 0);
  assert(all(cellfun(@(h) isHist(h), varargin)));
  dim = unique(cellfun(@(h) length(h.bins), varargin));
  assert(isscalar(dim));

  ## create output histogram
  hgrm = Hist(dim);

  ## iterate over histogram dimensions
  for i = 1:dim

    ## get cell array of all (finite) histogram bins in this dimension
    binsi = cellfun(@(h) h.bins{i}(isfinite(h.bins{i})), varargin, "UniformOutput", false);

    ## round histogram bins to common boundaries
    [binsi{1:length(binsi)}] = roundHistBinBounds(binsi{:});

    ## create set of unique bins
    binsi = unique(cell2mat(binsi));

    ## set total histogram bins for this dimension
    hgrm.bins{i} = [-inf, binsi, inf];

  endfor

  ## create zero probability array of correct size
  siz = cellfun(@(x) length(x)-1, hgrm.bins);
  if length(siz) == 1
    siz(2) = 1;
  endif
  hgrm.counts = zeros(siz);

  ## iterate over histograms to add
  for n = 1:length(varargin)

    ## resample nth histogram to total histogram bins
    hgrmn = resampleHist(varargin{n}, hgrm.bins{:});

    ## add probabilities
    hgrm.counts += hgrmn.counts;

  endfor

endfunction
