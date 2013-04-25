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

## Finds the indices of the histogram bins that would
## contain some given input data. If the histogram is too
## small, more bins are added as needed.
## Syntax:
##   [hgrm, ii, nn] = findHistBins(hgrm, data, dx, x0)
## where:
##   hgrm = histogram class
##   data = input histogram data
##   ii   = indices of histogram bins
##   dx   = size of any new bins
##   x0   = (optional) initial bin when adding inf. data
##   nn   = (optional) multiplicities of each index

function [hgrm, ii, nn] = findHistBins(hgrm, data, dx, x0)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.xb);
  assert(ismatrix(data) && size(data, 2) == dim);
  assert(isscalar(dx) || (isvector(dx) && length(dx) == dim));
  if isscalar(dx)
    dx = dx(ones(dim, 1));
  endif
  if nargin < 4 || isempty(x0)
    x0 = 0;
  endif
  if isscalar(x0)
    x0 = x0(ones(dim, 1));
  endif

  ## check for non-numeric data
  if any(isnan(data(:)))
    error("%s: Input data contains NaNs", funcName);
  endif

  ## expand histogram to include new bins, if needed
  for k = 1:dim
    
    ## if data is all infinite
    finii = find(isfinite(data(:,k)));
    if !any(finii)

      ## make sure there's at least one non-infinite bin
      if length(hgrm.xb{k}) == 2
        hgrm = resampleHist(hgrm, k, x0);
      endif

    else

      ## range of finite data
      dmin = min(data(finii,k));
      dmax = max(data(finii,k));
      
      ## create new bins
      if length(hgrm.xb{k}) == 2
        nxb = (floor(dmin / dx(k)):ceil(dmax / dx(k))) * dx(k);
        if length(nxb) == 1
          nxb = [nxb, nxb + dx(k)];
        endif
      else
        nxblo = hgrm.xb{k}(2) - (ceil((hgrm.xb{k}(2) - dmin) / dx(k)):-1:1) * dx(k);
        nxbhi = hgrm.xb{k}(end-1) + (1:ceil((dmax - hgrm.xb{k}(end-1)) / dx(k))) * dx(k);
        nxb = [nxblo, hgrm.xb{k}(2:end-1), nxbhi];
      endif
      
      ## resize histogram
      hgrm = resampleHist(hgrm, k, nxb);

    endif

  endfor

  ## bin indices
  ii = zeros(size(data));
  for k = 1:dim
    datak = data(:,k);
    ## so that last (finite) bin is treated as <=
    if length(hgrm.xb{k}) >= 4
      datak(datak == hgrm.xb{k}(end-1)) = hgrm.xb{k}(end-2);
    endif
    ii(:,k) = lookup(hgrm.xb{k}, datak, "lr");
  endfor

  ## multiplicities of each bin index
  if nargout > 2
    ii = sortrows(ii);
    [ii, nnii] = unique(ii, "rows", "last");
    nn = diff([0; nnii]);
  endif

endfunction
