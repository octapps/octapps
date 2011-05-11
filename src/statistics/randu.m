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

%% -*- texinfo -*-
%% @deftypefn {Function File} {} randu([@var{min} @var{max}])
%% @deftypefnx{Function File} {} randu(@var{min}, @var{max})
%%
%% Return random values uniformly distributed over a given
%% range. @var{min} and @var{max} may be scalars (first usage),
%% or equi-dimensional matrices (second usage).
%% @end deftypefn

function x = randu(varargin)

  if nargin == 1
    m = min(varargin{1});
    M = max(varargin{1});
  elseif nargin == 2
    m = min(varargin{1}, varargin{2});
    M = max(varargin{1}, varargin{2});
  else
    print_usage();
  endif

  x = m + rand(size(m)) .* (M - m);

endfunction
