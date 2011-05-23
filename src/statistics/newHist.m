%% Creates a new struct representing a (multi-dimensional) histogram.
%% Syntax:
%%   [hgrm1, hgrm2, ...] = newHist(dim)
%% where:
%%   hgrm{1,2,...} = histogram (array) structs
%%   dim           = dimensionality of the histograms

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

function varargout = newHist(dim)

  %% create struct (array)
  if !exist("dim")
    dim = 1;
  endif
  clear hgrm;
  [hgrm.xb{1:dim,1}] = deal([-inf inf]);
  hgrm.px = 0;
  [varargout{1:max(nargout,1)}] = deal(hgrm);

endfunction
