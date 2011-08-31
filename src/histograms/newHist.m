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

## Creates a new struct representing a (multi-dimensional) histogram.
## Syntax:
##   [hgrm, hgrm, ...] = newHist(dim, val)
## where:
##   hgrm,... = histogram structs
##   dim      = dimensionality of the histograms
##   val      = singular val of the histograms

function varargout = newHist(dim, val)

  ## check input
  if !exist("dim")
    dim = 1;
  elseif !isscalar(dim)
    error("%s: dim must be a scalar", funcName);
  endif
  if !exist("val")
    val = [];
  elseif !isscalar(val)
    error("%s: val must be a scalar", funcName);
  endif

  ## create struct
  clear hgrm;
  [hgrm.xb{1:dim,1}] = deal([-inf val val inf]);
  if dim == 1
    hgrm.px = zeros(length(hgrm.xb{1})-1, 1);
  else
    hgrm.px = zeros((length(hgrm.xb{1})-1)*ones(1,dim));
  endif
  if !isempty(val)
    hgrm.px(ceil(numel(hgrm.px)/2)) = 1;
  endif
  [varargout{1:max(nargout,1)}] = deal(hgrm);

endfunction
