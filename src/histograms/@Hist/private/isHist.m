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

## Helper function for isHist()

function ishgrm = isHist(hgrm)

  ## Check whether the input argument is an internally consistent histogram object
  ishgrm = isa(hgrm, "Hist") && iscell(hgrm.bins) && isvector(hgrm.bins) && length(hgrm.bins) > 0 && length(size(hgrm.counts)) >= 2;
  if ishgrm
    for k = 1:length(hgrm.bins)
      ishgrm = ishgrm && isvector(hgrm.bins{k}) && length(hgrm.bins{k}) >= 2 && ...
               hgrm.bins{k}(1) == -inf && all(isfinite(hgrm.bins{k}(2:end-1))) && hgrm.bins{k}(end) == inf && ...
               length(hgrm.bins{k}) == size(hgrm.counts, k) + 1;
    endfor
  endif

endfunction
