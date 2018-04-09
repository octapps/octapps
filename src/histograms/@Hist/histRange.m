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
## @deftypefn {Function File} { [ @var{rng}, @var{nbins} ] =} histRange ( @var{hgrm}, [ @var{kk} = 1:dim ] )
## @deftypefnx{Function File} { [ @var{frng}, @var{fnbins} ] =} histRange ( @var{hgrm}, [ @var{kk} = 1:dim ] , @code{finite} )
##
## Returns the ranges of a histogram object, which are finite
## if the histogram is non-empty and NaNs otherwise, and the
## number of bins in each range.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item kk
## dimensions for which to return ranges; defaults to all
##
## @item rng
## ranges of the histogram
##
## @item nbins
## number of bins in each range
##
## @item frng
## @code{finite} ranges of the histogram
##
## @item fnbins
## number of @code{finite} bins in each range
##
## @end table
##
## @end deftypefn

function [rng, nbins] = histRange(hgrm, varargin)

  ## check input
  narginchk(1, 3)
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  if length(varargin) > 0 && ischar(varargin{end})
    assert(strcmp(varargin{end}, "finite"));
    fretn = true;
    varargin = varargin(1:end-1);
  else
    fretn = false;
  endif
  if length(varargin) > 0
    kk = varargin{end};
    assert(all(1 <= kk && kk <= length(hgrm.bins)));
  else
    kk = 1:dim;
  endif

  ## return range
  rng = zeros(length(kk), 2);
  nbins = zeros(length(kk), 1);
  for i = 1:length(kk)
    h = contractHist(hgrm, kk(i));
    if fretn
      h.counts(1) = h.counts(end) = 0;
    endif
    ii = find(h.counts > 0);
    if isempty(ii)
      rng(i, :) = NaN;
    else
      rng(i, 1) = h.bins{1}(min(ii));
      rng(i, 2) = h.bins{1}(max(ii)+1);
      nbins(i) = max(ii) - min(ii) + 1;
    endif
  endfor

endfunction

%!shared hgrm0
%!  hgrm0 = Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1});
%!assert(histRange(addDataToHist(hgrm0, unifrnd(1.2, 9.7, 1000, 2))), [1.2, 9.7; 1.2, 9.7], 0.2)
%!assert(histRange(addDataToHist(hgrm0, [unifrnd(2.3, 11.3, 1000, 1), unifrnd(67.9, 103.5, 1000, 1)]), 1), [2.3, 11.3], 0.2)
%!assert(histRange(addDataToHist(hgrm0, [unifrnd(2.3, 11.3, 1000, 1), unifrnd(67.9, 103.5, 1000, 1)]), 2), [67.9, 103.5], 0.2)
