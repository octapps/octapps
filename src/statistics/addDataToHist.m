%% Adds the given input data to the histogram.
%% If the histogram is too small, more bins are added.
%% Syntax:
%%   hgrm = addSamplesToHist(hgrm, data, dx)
%% where:
%%   hgrm = histogram struct
%%   data = input histogram data
%%   dx   = size of any new bins

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

function hgrm = addDataToHist(hgrm, data, dx)

  %% check input
  assert(isHist(hgrm));

  %% get bin multiplicities from findHistBins, resize as needed
  [hgrm, ii, nn] = findHistBins(hgrm, data, dx);

  %% add bin multiplicities to correct bins
  jj = mat2cell(ii, size(ii, 1), ones(length(hgrm.xb), 1));
  hgrm.px(sub2ind(size(hgrm.px), jj{:})) += nn;

endfunction
