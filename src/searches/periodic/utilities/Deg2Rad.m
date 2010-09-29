%% ret = Deg2Rad ( degs )
%% convert degrees in either "deg.xxx" or "deg:min:sec.xx" into radians
%% decimal degrees input type can be either in string-format or as a decimal number


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


function ret = Deg2Rad ( degs )

  tmp = strtrim ( degs );

  %% determine if input format is decimal degrees or 'deg:min:sec'
  if ( isnumeric(degs) )
    degsDecimal = degs;
  else
    numColons = length ( strchr ( degs, ":" ) );

    if ( numColons == 0 )
      degsDecimal = str2num ( degs );
    elseif (numColons == 2 )
      tokens = strsplit (degs, ":" );

      degsNum = str2num ( tokens{1} );
      minutes = str2num ( tokens{2} );
      seconds = str2num ( tokens{3} );

      degsDecimal = ( degsNum + minutes/60.0 + seconds/3600.0 );

    else
      error ("Invalid input format for degrees '%s', use either decimal 'd.xx' or 'd:m:s.xxx' format.\n", degs );
    endif
  endif

  ret = degsDecimal / 360.0 * 2*pi;

  return;

endfunction % Deg2Rad()

