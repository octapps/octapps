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

## Return the unions of bins of the given histograms in each dimension.
## Syntax:
##   ubins = histBinUnions(hgrms...)
## where:
##   ubins = cell array of union of bins in each dimension
##   hgrms = histograms

function ubins = histBinUnions(varargin)

  ## check input
  assert(length(varargin) > 0);
  dim = [];
  for i = 1:length(varargin)
    hgrm = varargin{i};
    assert(isHist(hgrm), "Argument #i must be a valid histogram class", i);
    if isempty(dim)
      dim = length(hgrm.bins);
    else
      assert(dim == length(hgrm.bins), "Histograms must have the same dimensionality");
    endif
  endfor

  ## iterate over histogram dimensions
  ubins = cell(1, dim);
  for i = 1:dim

    ## get finite histogram bins
    allbins_i = cellfun(@(H) reshape(H.bins{i}(2:end-1), 1, []), varargin, "UniformOutput", false);

    ## get minimum bin width
    minwidth = min(cell2mat(cellfun(@(b) min(diff(b)), allbins_i, "UniformOutput", false)));

    ## create unique, sorted array of all bins
    ubins_i = unique(cell2mat(allbins_i));

    ## remove any bins which would create a bin smaller than minimum bin width
    ubins_i([false, diff(ubins_i) < minwidth]) = [];

    ## make sure new bins cover old bins
    ubins_i(1) = min(cellfun(@(b) min(b), allbins_i));
    ubins_i(end) = max(cellfun(@(b) max(b), allbins_i));

    ## set histogram bin union for this dimension
    ubins{i} = ubins_i;

  endfor

endfunction
