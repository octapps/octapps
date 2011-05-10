%% Load SWIG wrapping modules
%% Syntax:
%%   importSWIG module module ...

%%
%%  Copyright (C) 2011 Karl Wette
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

function importSWIG(varargin)

  for n = 1:length(varargin)

    %% get module name
    module = varargin{n};
    if !ischar(module)
      error("%s: invalid module name", funcName);
    endif

    %% SWIG wrapping modules must be loaded
    %% in the "base" context to work properly,
    %% and must be exported via global to be
    %% accessible within functions
    evalin("base", sprintf("%s; global %s;", module, module));

    %% functions must also declare global module
    %% variable to use constants and enums
    evalin("caller", sprintf("global %s;", module));

  endfor

endfunction
