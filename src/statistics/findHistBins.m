%% Finds the indices of the histogram bins that would
%% contain some given input data. If the histogram is too
%% small, more bins are added as needed.
%% Syntax:
%%   [hgrm, ii, nn] = findHistBins(hgrm, data, dx)
%% where:
%%   hgrm = histogram struct
%%   data = input histogram data
%%   ii   = indices of histogram bins
%%   dx   = size of any new bins
%%   nn   = (optional) multiplicities of each index

%%
%%  Copyright (C) 2010 Karl Wette
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%

function [hgrm, ii, nn] = findHistBins(hgrm, data, dx)

  %% check input
  assert(isHist(hgrm));
  dim = length(hgrm.xb);
  assert(ismatrix(data) && size(data, 2) == dim);
  assert(isscalar(dx) || (isvector(dx) && length(dx) == dim));
  if isscalar(dx)
    dx = dx(ones(dim, 1));
  endif

  %% expand histogram to include new bins, if needed
  for k = 1:dim

    %% range of data
    dmin = min(data(:,k));
    dmax = max(data(:,k));
    if !(isfinite(dmin) && isfinite(dmax))
      error("%s: Input data has non-finite range", funcName);
    endif

    %% create new bins
    if isempty(hgrm.xb{k})
      nxb = (floor(dmin / dx(k)):ceil(dmax / dx(k))) * dx(k);
    else
      nxblo = hgrm.xb{k}(1) - (ceil((hgrm.xb{k}(1) - dmin) / dx(k)):-1:1) * dx(k);
      nxbhi = hgrm.xb{k}(end) + (1:ceil((dmax - hgrm.xb{k}(end)) / dx(k))) * dx(k);
      nxb = [nxblo, hgrm.xb{k}, nxbhi];
    endif

    %% resize histogram
    hgrm = resampleHist(hgrm, k, nxb);

  endfor

  %% bin indices
  ii = zeros(size(data));
  for k = 1:dim
    ii(:,k) = lookup(hgrm.xb{k}, data(:,k));
  endfor

  %% multiplicities of each bin index
  if nargout > 2
    ii = sortrows(ii);
    [ii, nnii] = unique(ii, "rows", "last");
    nn = diff([0; nnii]);
  endif

endfunction
