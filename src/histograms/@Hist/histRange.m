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

## Returns the range(s) of a histogram class, which are is finite
## if the histogram is non-empty, and NaNs otherwise.
## Syntax:
##   rng = histRange(hgrm, [kk = 1:dim])
## where:
##   hgrm = histogram class
##   kk   = ranges to return; defaults to all
##   rng  = range(s) of the histogram

function rng = histRange(hgrm, kk = [])

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  if isempty(kk)
    kk = 1:dim;
  else
    assert(all(1 <= kk && kk <= length(hgrm.bins)));
  endif

  ## return range
  rng = zeros(length(kk), 2);
  for i = 1:length(kk)
    h = contractHist(hgrm, kk(i));
    ii = find(h.counts > 0);
    if isempty(ii)
      rng(i, :) = NaN;
    else
      rng(i, 1) = h.bins{1}(min(ii));
      rng(i, 2) = h.bins{1}(max(ii)+1);
    endif
  endfor

endfunction
