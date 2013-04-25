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

## Checks whether the input argument is a valid histogram class.
## Syntax:
##   ishgrm = isHist(hgrm)
## where:
##   hgrm   = maybe a histogram class
##   ishgrm = true if hgrm is a valid histogram class,
##            false otherwise

function ishgrm = isHist(hgrm)

  ## check if hgrm is a Hist class object
  ishgrm = strcmp(class(hgrm), "Hist");

  ## perform various consistency checks on class variables
  ishgrm = ishgrm && iscell(hgrm.bins) && isvector(hgrm.bins) && length(hgrm.bins) > 0 && ismatrix(hgrm.counts);
  if ishgrm
    for k = 1:length(hgrm.bins)
      ishgrm = ishgrm && isvector(hgrm.bins{k}) && length(hgrm.bins{k}) >= 2 && ...
          hgrm.bins{k}(1) == -inf && all(isfinite(hgrm.bins{k}(2:end-1))) && hgrm.bins{k}(end) == inf && ...
          length(hgrm.bins{k}) == size(hgrm.counts, k) + 1;
    endfor
  endif

endfunction
