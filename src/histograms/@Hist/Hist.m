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

## Creates a new class representing a multi-dimensional histogram.
## Syntax:
##   hgrm = Hist(dim, val)
## where:
##   hgrm = histogram class
##   dim  = dimensionality of the histogram
##   val  = (optional) singular value of the histogram

function hgrm = Hist(dim, val)

  ## check input
  assert(isscalar(dim));
  if nargin > 1
    assert(isscalar(val));
  else
    val = [];
  endif

  ## create class struct
  hgrm = struct;
  [hgrm.xb{1:dim,1}] = deal([-inf val val inf]);
  if dim == 1
    hgrm.px = zeros(length(hgrm.xb{1})-1, 1);
  else
    hgrm.px = zeros((length(hgrm.xb{1})-1)*ones(1,dim));
  endif
  if !isempty(val)
    hgrm.px(ceil(numel(hgrm.px)/2)) = 1;
  endif

  ## create class
  hgrm = class(hgrm, "Hist");

endfunction
