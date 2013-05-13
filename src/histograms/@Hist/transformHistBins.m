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

## Transform the bins of a histogram.
## The new bins must be in strictly ascending order.
## Syntax:
##   hgrm = transformHistBins(hgrm, k, F)
## where:
##   hgrm = histogram class
##   k    = dimension along which to scale bin
##   F    = function to apply to bins

function hgrm = transformHistBins(hgrm, k, F)

  ## check input
  assert(isHist(hgrm));
  assert(1 <= k && k <= length(hgrm.bins));

  ## transform bins
  newbins = arrayfun(F, hgrm.bins{k}(2:end-1));

  ## check that transformed bins are strictly ascending
  if !all(diff(newbins) > 0)
    error("%s: function '%s' does not produce strictly-ascending-order bins", funcName, func2str(F));
  endif

  ## assign new bins
  hgrm.bins{k}(2:end-1) = newbins;

endfunction
