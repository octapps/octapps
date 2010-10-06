%% Finds the indices of the histogram bins that would
%% contain some given input data. If the histogram is too
%% small, more bins are added as needed.
%% Syntax:
%%   [hist, ii, nn] = findHistBins(hist, data, dx)
%% where:
%%   hist = histogram
%%   data = input histogram data
%%   ii   = indices of histogram bins
%%   dx   = (optional) size of new bins (otherwise use hist.dx)
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

function [hist, ii, nn] = findHistBins(hist, data, dx)

  %% bin size to use  
  if nargin < 3
    dx = hist.dx;
  endif
  
  %% range of data
  data = data(:);
  dmin = min(data);
  dmax = max(data);
  
  %% if histogram is empty, create appropriate bins
  if isempty(hist.xb)
    hist.xb = (floor(dmin / dx):ceil(dmax / dx)) * dx;
    hist.px = zeros(1, length(hist.xb) - 1);
  else

    %% expand histogram to lower bin values needed
    if dmin < hist.xb(1)
      newxb = hist.xb(1) - (ceil((hist.xb(1) - dmin) / dx):-1:1) * dx;
      hist.xb = [newxb,              hist.xb];
      hist.px = [zeros(size(newxb)), hist.px];
    endif

    %% expand histogram to higher bin values needed
    if dmax > hist.xb(end)
      newxb = hist.xb(end) + (1:ceil((dmax - hist.xb(end)) / dx)) * dx;
      hist.xb = [hist.xb, newxb,            ];
      hist.px = [hist.px, zeros(size(newxb))];
    endif
    
  endif

  %% bin indices
  ii = lookup(hist.xb, data);

  %% multiplicities of each bin index
  if nargout > 2
    iiu = unique(ii);
    nn = zeros(size(hist.px));
    for i = 1:length(iiu)
      nn(iiu(i)) += length(find(ii == iiu(i)));
    endfor
  endif

endfunction
