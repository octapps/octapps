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

  %% range of data
  data = data(:);
  dmin = min(data);
  dmax = max(data);
  
  %% if histogram is empty, create appropriate bins
  if isempty(hgrm.xb)
    hgrm.xb = (floor(dmin / dx):ceil(dmax / dx)) * dx;
    hgrm.px = zeros(1, length(hgrm.xb) - 1);
  else

    %% expand histogram to lower bin values needed
    if dmin < hgrm.xb(1)
      newxb = hgrm.xb(1) - (ceil((hgrm.xb(1) - dmin) / dx):-1:1) * dx;
      hgrm.xb = [newxb,              hgrm.xb];
      hgrm.px = [zeros(size(newxb)), hgrm.px];
    endif

    %% expand histogram to higher bin values needed
    if dmax > hgrm.xb(end)
      newxb = hgrm.xb(end) + (1:ceil((dmax - hgrm.xb(end)) / dx)) * dx;
      hgrm.xb = [hgrm.xb, newxb,            ];
      hgrm.px = [hgrm.px, zeros(size(newxb))];
    endif
    
  endif

  %% bin indices
  ii = lookup(hgrm.xb, data);

  %% multiplicities of each bin index
  if nargout > 2
    iiu = unique(ii);
    nn = zeros(size(hgrm.px));
    for i = 1:length(iiu)
      nn(iiu(i)) += length(find(ii == iiu(i)));
    endfor
  endif

endfunction
