%% attempt to compensate for output-argument switch
%% in the system() command between octave2.1 and octave2.9 [doh]
%% 'normalize' output-order to octave2.9 conventions
%%

%%
%% Copyright (C) 2007 Reinhard Prix
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

function [status, output] = system29 ( arg )
  is29 = ( index ( OCTAVE_VERSION, "2.9" ) == 1 );

  [ret1, ret2] = system ( arg );

  if ( is29 )
    status = ret1;
    output = ret2;
  else
    status = ret2;
    output = ret1;
  endif
endfunction

