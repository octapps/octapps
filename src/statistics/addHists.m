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
##   hgrm  = histogram structs
##   hgrmt = total histogram

function hgrm = addHists(varargin)

  ## check input
  assert(length(varargin) > 0);
  assert(all(cellfun(@(h) isHist(h), varargin)));
  dim = unique(cellfun(@(h) length(h.xb), varargin));
  assert(isscalar(dim));

  ## create output histogram
  hgrm = newHist(dim);

  ## iterate over histogram dimensions
  for i = 1:dim

    ## get cell array of all (finite) histogram bins in this dimension
    xbi = cellfun(@(h) h.xb{i}(isfinite(h.xb{i})), varargin, "UniformOutput", false);

    ## round histogram bins to common boundaries
    [xbi{1:length(xbi)}] = roundHistBinBounds(xbi{:});

    ## create set of unique bins
    xbi = unique(cell2mat(xbi));

    ## set total histogram bins for this dimension
    hgrm.xb{i} = [-inf, xbi, inf];

  endfor

  ## create zero probability array of correct size
  siz = cellfun(@(x) length(x)-1, hgrm.xb);
  if length(siz) == 1
    siz(2) = 1;
  endif
  hgrm.px = zeros(siz);

  ## iterate over histograms to add
  for n = 1:length(varargin)

    ## resample nth histogram to total histogram bins    
    hgrmn = resampleHist(varargin{n}, hgrm.xb{:});

    ## add probabilities
    hgrm.px += hgrmn.px;

  endfor

endfunction
