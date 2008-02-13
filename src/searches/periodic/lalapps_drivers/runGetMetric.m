%% function runGetMetric (params)
%% general driver for 'getMetric' lalapps code, return the metric matrix
%%

%%
%% Copyright (C) 2008 Reinhard Prix
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
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston
%%  MA  02111-1307  USA
%%

function gij = runGetMetric (params, gmCode)
  global debug;
  required = true;

  if ( !exist("params" ) )
    error("Missing function argument 'params'\n");
  endif

  if ( !exist("gmCode") )
    gmCode = "lalapps_getMetric";
  endif

  cmdline = gmCode;

  %% ----- target parameters
  %% required:
  cmdline = addCmdlineOption(cmdline, params, "IFO", required );
  cmdline = addCmdlineOption(cmdline, params, "Alpha", required );
  cmdline = addCmdlineOption(cmdline, params, "Delta", required );
  cmdline = addCmdlineOption(cmdline, params, "Freq", required );
  cmdline = addCmdlineOption(cmdline, params, "duration", required );
  %% optional
  cmdline = addCmdlineOption(cmdline, params, "f1dot");
  cmdline = addCmdlineOption(cmdline, params, "metricType");
  cmdline = addCmdlineOption(cmdline, params, "projectMetric");

  cmdline = addCmdlineOption(cmdline, params, "startTime");

  cmdline = addCmdlineOption(cmdline, params, "ephemDir");
  cmdline = addCmdlineOption(cmdline, params, "ephemYear");

  %% ----- debug
  if ( isfield(params, "lalDebugLevel" ) && params.lalDebugLevel )
    lalDebugLevel = params.lalDebugLevel;
    cmdline = sprintf ( "%s -v%d", cmdline, params.lalDebugLevel )
  else
    lalDebugLevel = 0;
  endif

  if ( debug || lalDebugLevel )
    printf ( "%s\n", cmdline );
  endif

  %% ----- and run it:
  [status, out] = system29(cmdline);
  if ( status != 0 )
    printf ("\nSomething failed in running '%s'\n\n", gmCode);
    error ("Commandline was: %s", cmdline);
  endif

  %% output is the form: 'g_ij = [... ];', so we simply evaluate it
  eval ( out, 'error("Failed to parse output from getMetric!\n");' );
  gij = g_ij;

  return;

endfunction %% runGetMetric()
