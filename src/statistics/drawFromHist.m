%% Generates random values drawn from the
%% probability distribution given by the histogram.
%% Syntax:
%%   x         = drawFromHist(hgrm, N)
%%   [x, wksp] = drawFromHist(hgrm, N, wksp)
%% where:
%%   hgrm = histogram struct
%%   N    = number of random values to generate
%%   wksp = working variables for drawFromHist
%%   x    = generated random values

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

function [x, wksp] = drawFromHist(hgrm, N, wksp)

  %% check input
  assert(isHist(hgrm));
  dim = length(hgrm.xb);

  %% store some variables for re-use
  if isempty(wksp)

    %% normalise histogram
    hgrm = normaliseHist(hgrm);

    %% probability of each bin
    P = hgrm.px;
    for k = 1:dim
      P .*= histBinGrids(hgrm, k, "dx");
    endfor

    %% indices to all histogram bins, and their probabilities
    wksp = struct("ii", 1:numel(hgrm.px), "P", P(:)');

  endif

  %% generate random indices to histogram bins,
  %% with appropriate probabilities
  [ii{1:dim}] = ind2sub(size(hgrm.px), discrete_rnd(N, wksp.ii, wksp.P));
  
  %% start with the lower bound of each randomly
  %% chosen bin and add a uniformly-distributed
  %% offset within that bin
  x = zeros(N, dim);
  for k = 1:dim
    dx = hgrm.xb{k}(ii{k}+1) - hgrm.xb{k}(ii{k});
    x(:,k) = hgrm.xb{k}(ii{k}) + rand(size(ii{k})).*dx;
  endfor

endfunction
