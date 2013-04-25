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

## Return quantities relating to the histogram bin boundaries,
## in gridded arrays of the same size as the probability array.
## Syntax:
##   [binq, ...] = histBinsGrids(hgrm, k, "type", ...)
## where:
##   hgrm = histogram class
##   k    = dimension along which to return bin quantities
##   type = see histBins()
##   binq = bin quantities

function varargout = histBinGrids(hgrm, k, varargin)

  ## check input
  assert(isHist(hgrm));
  assert(1 <= k && k <= length(hgrm.bins));

  ## loop over requested output
  for i = 1:length(varargin)

    ## what do you want?
    binq = histBins(hgrm, k, varargin{i});

    ## return binq duplicated over all dimensions != k
    ## taken from ndgrid.m
    shape = size(hgrm.counts);
    r = ones(size(shape));
    r(k) = shape(k);
    s = shape;
    s(k) = 1;
    varargout{i} = repmat(reshape(binq, r), s);

  endfor

endfunction
