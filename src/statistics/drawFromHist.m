%% Generates random values drawn from the
%% probability distribution given by the histogram.
%% Syntax:
%%   x         = drawFromHist(hgrm, N)
%%   [x, hgrm] = drawFromHist(hgrm, N)
%% where:
%%   hgrm = histogram struct
%%   N    = number of random values to generate
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

function [x, hgrm] = drawFromHist(hgrm, N)

  %% check input
  assert(isHist(hgrm));

  %% store some variables for re-use
  if ~isfield(hgrm, "P")
    hgrm = normaliseHist(hgrm);    % normalise histogram
    hgrm.ii = 1:length(hgrm.px);   % indices to histogram bins
    hgrm.dx = diff(hgrm.xb);       % width of each bin
    hgrm.P = hgrm.px .* hgrm.dx;   % probability of each bin
  endif

  %% generate random indices to histogram bins,
  %% with appropriate probabilities
  ii = discrete_rnd(N, hgrm.ii, hgrm.P);
  
  %% start with the lower bound of each randomly
  %% chosen bin and add a uniformly-distributed
  %% offset within that bin
  x = hgrm.xb(ii) + rand(size(ii)).*hgrm.dx(ii);

endfunction
