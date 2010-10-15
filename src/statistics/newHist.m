%% Creates a new struct representing a histogram.
%% Syntax:
%%   [hgrm1, hgrm2, ...] = newHist
%%   [hgrm1, hgrm2, ...] = newHist(N1, N2, ...)
%% where:
%%   hgrm{1,2,...} = histogram (array) structs
%%   N{1,2,...}    = array dimensions

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

function varargout = newHist(varargin)

  %% create struct (array)
  if nargin == 0
    varargin = {1};
  elseif nargin == 1
    varargin{end+1} = 1;
  endif
  hgrm = struct("xb", [], "px", []);
  hgrm = hgrm(ones(varargin{:}));
  [varargout{1:max(nargout,1)}] = deal(hgrm);

endfunction
