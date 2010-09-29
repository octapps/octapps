%% ret = HMS2Rad ( HMS )
%% convert an "hour:minute:second.xxx" string into radians

%%
%% Copyright (C) 2010 Reinhard Prix
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


function ret = HMS2Rad ( hms )

  tmp = strtrim ( hms );

  tokens = strsplit (tmp, ":" );
  if ( length(tokens) != 3 )
    error ("Invalid inut string '%s' not in HMS format 'hour:minute:seconds.xxx'\n", hms );
  endif

  hours   = str2num ( tokens{1} );
  minutes = str2num ( tokens{2} );
  seconds = str2num ( tokens{3} );

  ret = ( hours + minutes/60.0 + seconds/3600.0 ) / 24 * 2 *pi;

endfunction % HMS2Rad()

