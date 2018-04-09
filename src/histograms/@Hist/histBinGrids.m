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
## @deftypefn {Function File} { [ @var{binq}, @dots{} ] =} histBinsGrids ( @var{hgrm}, @var{k}, @code{type}, @dots{} )
##
## Return quantities relating to the histogram bin boundaries,
## in gridded arrays of the same size as the probability array.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item k
## dimension along which to return bin quantities
##
## @item type
## see @command{histBins()}
##
## @item binq
## bin quantities
##
## @end table
##
## @end deftypefn

function varargout = histBinGrids(hgrm, k, varargin)

  ## check input
  assert(isHist(hgrm));
  assert(1 <= k && k <= length(hgrm.bins));

  ## determine whether to return finite bin quantities
  siz = size(hgrm.counts);
  if strcmp(varargin{1}, "finite")
    siz(siz > 1) -= 2;
    finitearg = varargin(1);
    varargin = varargin(2:end);
  else
    finitearg = {};
  endif

  ## loop over requested output
  for i = 1:length(varargin)

    ## what do you want?
    binq = histBins(hgrm, k, finitearg{:}, varargin{i});

    ## return binq duplicated over all dimensions != k
    varargout{i} = replOver(binq, setdiff(1:length(hgrm.bins), k), siz);

  endfor

endfunction

%!shared hgrm
%!  hgrm = restrictHist(addDataToHist(Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}), unifrnd(0, 1, 1e6, 2)));
%!assert(histBinGrids(hgrm, 1, "lower"), [-inf, 0:0.1:0.9, inf]' * ones(1, 12), 1e-3)
%!assert(histBinGrids(hgrm, 1, "centre"), [-inf, 0.05:0.1:0.95, inf]' * ones(1, 12), 1e-3)
%!assert(histBinGrids(hgrm, 1, "upper"), [-inf, 0.1:0.1:1.0, inf]' * ones(1, 12), 1e-3)
