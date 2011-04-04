%% Computes a metric distance between histograms, defined to be
%% the area under the histogram whose probability densities are
%% the absolute difference in (normalised) probability densities
%% of the two input histograms.
%% Syntax:
%%   d = histMetric(hgrm1, hgrm2)
%% where:
%%   hgrm{1,2} = histogram structs

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

function d = histMetric(hgrm1, hgrm2)

  %% check input
  assert(isHist(hgrm1) && isHist(hgrm2));
  assert(length(hgrm1.xb) == length(hgrm2.xb));
  dim = length(hgrm1.xb);

  %% resample histograms to common bin set
  for k = 1:dim

    %% get rounded bins
    [xb1, xb2] = roundHistBinBounds(hgrm1.xb{k}, hgrm2.xb{k});
    if length(xb1) != length(xb2) || xb1 != xb2

      %% common bin set
      xb = union(xb1, xb2);

      %% resample histograms
      hgrm1 = resampleHist(hgrm1, k, xb);
      hgrm2 = resampleHist(hgrm2, k, xb);

    endif

  endfor

  %% normalise histograms
  hgrm1 = normaliseHist(hgrm1);
  hgrm2 = normaliseHist(hgrm2);

  %% construct difference histogram
  hgrmd.xb = hgrm1.xb;
  hgrmd.px = abs(hgrm1.px - hgrm2.px);
  assert(isHist(hgrmd));

  %% return distance
  d = areaUnderHist(hgrmd);

endfunction
