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
##   bin0 = starting bin (default: 0)

function hgrm = Hist(dim, bin0=0)

  ## check input
  assert(isscalar(dim));
  assert(isscalar(bin0) || (isvector(bin0) && length(bin0) == dim));
  if isscalar(bin0)
    bin0 = bin0(ones(dim, 1));
  endif

  ## create class struct
  hgrm = struct;
  for k = 1:dim
    hgrm.bins{k,1} = [-inf, bin0(k), inf];
  endfor
  hgrm.counts = squeeze(zeros([2*ones(1,dim), 1]));

  ## create class
  hgrm = class(hgrm, "Hist");

endfunction
