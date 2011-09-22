%% ret = addCmdlineOption ( params, option, [isRequired] );
%%
%% This is a helper function to construct commandlines for running executables
%% Return 'cmdline' with 'option' appended, if this field exists in 'params'
%%
%% the optional field 'isRequired': if (isRequired): exit with an error if
%% that option does not exist in params
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

function ret = addCmdlineOption ( cmdline, params, option, isRequired )

  if ( !exist("isRequired") )
    isRequired = false;
  endif

  if ( !isfield (params, option ) )
    if ( isRequired )
      error ("Required option '%s' is missing in params\n", option);
    else
      ret = cmdline;	%% missing but not required: return unmodified commandline
      return;
    endif
  endif

  val = getfield ( params, option );

  if ( ischar ( val ) )
    valstr = sprintf ("'%s'", val );
  elseif ( isscalar (val) && isreal (val) )
    valstr = sprintf ("%.16g", val );
  elseif ( islogical ( val ) )
    valstr = sprintf ("%d", val );
  else
    error ("Field '%s' is neither a string, bool or real scalar!\n", option );
  endif

  if length(option) == 1
    dashes = "-";
  else
    dashes = "--";
  endif

  ret = strcat ( cmdline, " ", dashes, option, "=", valstr );

  return;

endfunction

