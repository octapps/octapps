%% runCode (params, code)
%%
%% generic code-running driver: run code passing any commandline options in 'params'
%% in --name=val format
%%

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

function runCode (params, code)
  global debug;

  if ( !exist("params" ) )
    error("Missing function argument 'params'\n");
  endif

  if ( !exist("code") )
    error("Missing function argument 'code'\n");
  endif

  cmdline = code;

  option_names = fieldnames ( params );

  for i = 1:length(option_names)
    thisopt = option_names{i};

    cmdline = addCmdlineOption(cmdline, params, thisopt );

  endfor

  %% ----- debug
  if ( isfield(params, "v") )
    lalDebugLevel = params.v;
  elseif ( isfield(params, "d") )
    lalDebugLevel = params.d;
  elseif ( isfield(params, "lalDebugLevel" ) && params.lalDebugLevel )
    lalDebugLevel = params.lalDebugLevel;
    cmdline = sprintf ( "%s -v%d", cmdline, params.lalDebugLevel )
  else
    lalDebugLevel = 0;
  endif

  if ( debug || lalDebugLevel )
    printf ( "%s\n", cmdline );
  endif

  %% ----- and run it:
  unmanglePATH;
  status = system(cmdline);
  if ( status != 0 )
    printf ( "\nSomething failed in running '%s'\n\n", code);
    printf ( "Commandline was: %s\n", cmdline);
    error ("'%s' failed with exit status %i", code, status);
  endif

  return;

endfunction %% runCode

