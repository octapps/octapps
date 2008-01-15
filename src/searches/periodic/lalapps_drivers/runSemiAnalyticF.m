%% function runSemiAnalyticF (params, code)
%% general SemiAnalyticF driver: pass all commandline-options in params
%% run lalapps_SemiAnalyticF, return 2F_saf
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

function ret = runSemiAnalyticF (params, safCode)
  global debug;

  if ( !exist("params" ) )
    error("Missing function argument 'params'\n");
  endif
  if ( !exist("safCode") )
    cfsCode = "lalapps_SemiAnalyticF";
  endif

  cmdline = safCode;

  cmdline = addCmdlineOption(cmdline, params, "h0" );
  cmdline = addCmdlineOption(cmdline, params, "cosi" );
  cmdline = addCmdlineOption(cmdline, params, "aPlus" );
  cmdline = addCmdlineOption(cmdline, params, "aCross");
  cmdline = addCmdlineOption(cmdline, params, "psi");
  cmdline = addCmdlineOption(cmdline, params, "Alpha" );
  cmdline = addCmdlineOption(cmdline, params, "Delta" );

  %% optional params
  cmdline = addCmdlineOption(cmdline, params, "IFO");
  cmdline = addCmdlineOption(cmdline, params, "ephemDir" );
  cmdline = addCmdlineOption(cmdline, params, "ephemYear" );
  cmdline = addCmdlineOption(cmdline, params, "minStartTime" );
  cmdline = addCmdlineOption(cmdline, params, "startTime" );
  cmdline = addCmdlineOption(cmdline, params, "duration" );
  cmdline = addCmdlineOption(cmdline, params, "Tsft" );
  cmdline = addCmdlineOption(cmdline, params, "sqrtSh" );

  if ( isfield(params, "lalDebugLevel" ) && params.lalDebugLevel )
    cmdline = sprintf ( "%s -v%d", cmdline, params.lalDebugLevel )
  endif

  if ( debug )
    printf ("%s\n", cmdline );
  endif

  %% ----- and run it:
  [status, out] = system29(cmdline);
  if ( status != 0 )
    printf ("\nSomething failed in running '%s'\n\n", safCode);
    error ("Commandline was: %s", cmdline);
  endif

  %% ----- read output
  ret = 2 * str2num ( out );	%% E[2F]

  return;

endfunction % runSemiAnalyticF

