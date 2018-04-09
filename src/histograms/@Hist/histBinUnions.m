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
## @deftypefn {Function File} {@var{ubins} =} histBinUnions ( @var{hgrms}@dots{} )
##
## Return the unions of bins of the given histograms in each dimension.
##
## @heading Arguments
##
## @table @var
## @item ubins
## cell array of union of bins in each dimension
##
## @item hgrms
## histograms
##
## @end table
##
## @end deftypefn

function ubins = histBinUnions(varargin)

  ## check input
  assert(length(varargin) > 0);
  dim = [];
  for i = 1:length(varargin)
    hgrm = varargin{i};
    assert(isHist(hgrm), "Argument #i must be a valid histogram object", i);
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
    allbins_i = cellfun(@(H) reshape(struct(H).bins{i}(2:end-1), 1, []), varargin, "UniformOutput", false);

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

%!shared hgrm1, hgrm2, hgrm3
%!  hgrm1 = restrictHist(addDataToHist(Hist(1, {"lin", "dbin", 0.1}), unifrnd(0, 1, 1e6, 1)));
%!  hgrm2 = restrictHist(addDataToHist(Hist(1, {"lin", "dbin", 0.1}), unifrnd(1, 2, 1e6, 1)));
%!  hgrm3 = restrictHist(addDataToHist(Hist(1, {"lin", "dbin", 0.1}), unifrnd(2, 3, 1e6, 1)));
%!assert(histBinUnions(hgrm1, hgrm2), {[0:0.1:2]}, 1e-3)
%!assert(histBinUnions(hgrm1, hgrm3), {[0:0.1:1, 2:0.1:3]}, 1e-3)
%!assert(histBinUnions(hgrm2, hgrm3), {[1:0.1:3]}, 1e-3)
