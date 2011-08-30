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

## Checks whether the input arguments are
## valid histogram structs.
## Syntax:
##   ishgrm = isHist(hgrm)
## where:
##   hgrm   = maybe a histogram struct
##   ishgrm = true if hgrm is a valid histogram struct,
##            false otherwise

function ishgrm = isHist(hgrm)

  ishgrm = isstruct(hgrm) && length(hgrm) == 1 && ...
      isfield(hgrm, "xb") && iscell(hgrm.xb) && isvector(hgrm.xb) && length(hgrm.xb) > 0 && ...
      isfield(hgrm, "px") && ismatrix(hgrm.px);
  if ishgrm
    for k = 1:length(hgrm.xb)
      ishgrm = ishgrm && isvector(hgrm.xb{k}) && length(hgrm.xb{k}) >= 2 && ...
          hgrm.xb{k}(1) == -inf && all(isfinite(hgrm.xb{k}(2:end-1))) && hgrm.xb{k}(end) == inf && ...
          length(hgrm.xb{k}) == size(hgrm.px, k) + 1;
    endfor
  endif
  
endfunction
