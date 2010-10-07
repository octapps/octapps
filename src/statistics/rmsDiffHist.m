%% Compute the root-mean-square difference
%% between two histograms.
%% Syntax:
%%   rmsd = rmsDiffHist(hgrm1, hgrm2)
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

function rmsd = rmsDiffHist(hgrm1, hgrm2)

  %% create a common set of bins to
  %% re-sample histograms to
  xmin = min(min(hgrm1.xb), min(hgrm2.xb));
  xmax = max(max(hgrm1.xb), max(hgrm2.xb));
  dx = min([diff(hgrm1.xb), diff(hgrm2.xb)]);
  newxb = (floor(xmin / dx):ceil(xmax / dx)) * dx

  %% re-sample histograms
  hgrm1 = resampleHist(hgrm1, newxb)
  hgrm2 = resampleHist(hgrm2, newxb)

  %% return rms difference
  rmsd = sqrt(mean((hgrm1.px - hgrm2.px) .^ 2));

endfunction
