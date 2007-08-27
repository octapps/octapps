%% ret = pickFromRange(range)
%% function to return a random-value from within 'range',
%% which can be a single number, or a vector with [min, max] entries
%%

%%
%% Copyright (C) 2006 Reinhard Prix
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

function ret = pickFromRange(range)
  if ( length(range) == 1 )
    ret = range;
    return;		%% trivial case
  endif
  if ( rows(range) * columns(range) > 2 )
    error ("Illegal input to pickFromRange(): input either a scalar or an array[2]");
  endif

  minVal = min( range(:) );
  maxVal = max( range(:) );

  ret = minVal + rand() * ( maxVal - minVal );

endfunction
