%% Return quantities relating to the histogram bin boundaries,
%% in gridded arrays of the same size as the probability array
%% Syntax:
%%   [x, ...] = histBinGrids(hgrm, k, "type", ...)
%% where:
%%   hgrm = histogram struct
%%   k    = dimension along which to return bin quantities
%%   type = one of:
%%            "xl": lower bin boundary
%%            "xh": upper bin boundary
%%            "xc": bin centre
%%            "dx": bin width

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

function varargout = histBinGrids(hgrm, k, varargin)

  %% check input
  assert(isHist(hgrm));
  assert(1 <= k && k <= length(hgrm.xb));

  %% loop over requested output
  for i = 1:length(varargin)

    %% what do you want?
    xl = hgrm.xb{k}(1:end-1);
    xh = hgrm.xb{k}(2:end);
    switch varargin{i}
      case "xl"
	x = xl;
      case "xc"
	x = (xl + xh) / 2;
      case "xh"
	x = xh;
      case "dx"
	x = xh - xl;
      otherwise
	error("Invalid input argument '%s'!", varargin{i});
    endswitch

    %% duplicate over all dimensions != k
    %% taken from ndgrid.m
    shape = size(hgrm.px);
    r = ones(size(shape));
    r(k) = shape(k);
    s = shape;
    s(k) = 1;
    varargout{i} = repmat(reshape(x, r), s);
    
  endfor
  
endfunction
