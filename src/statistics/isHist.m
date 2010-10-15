%% Checks whether the input arguments are
%% valid histogram structs.
%% Syntax:
%%   ishgrm = isHist(hgrm, hgrm, ...)
%% where:
%%   hgrm   = maybe a histogram struct
%%   ishgrm = true if all hgrm are valid 
%%            histogram structs, false otherwise

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

function ishgrm = isHist(varargin)

  ishgrm = 1;
  for hgrm = varargin
    hgrm = hgrm{:};
    ishgrm = ishgrm && ...
	isstruct(hgrm) && ...
	isfield(hgrm, "xb") && ...
	isfield(hgrm, "px") && ...
	( ...
	 ( isempty(hgrm.xb) && isempty(hgrm.px) ) ...
	 || ( ...
	     isvector(hgrm.xb) && isvector(hgrm.px) && ...
	     length(hgrm.xb) == length(hgrm.px) + 1    ...
	     ) ...
	 );
  endfor

endfunction
