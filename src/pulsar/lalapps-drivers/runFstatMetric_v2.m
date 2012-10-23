%% runFstatMetric_v2 (params, fmCode)
%%
%% general FstatMetric_v2 driver: pass any commandline options in 'params'
%% and run metric code, optionally specifying a binary
%% 'fmCode' (default = "lalapps_FstatMetric_v2")
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

function runFstatMetric_v2 (params, fmCode)
  global debug;
  required = true;

  if ( !exist("params" ) )
    error("Missing function argument 'params'\n");
  endif

  if ( !exist("fmCode") )
    fmCode = "lalapps_FstatMetric_v2";
  endif

  cmdline = fmCode;

  %% ----- target parameters
  cmdline = addCmdlineOption(cmdline, params, "IFOs", required );
  cmdline = addCmdlineOption(cmdline, params, "IFOweights");
  cmdline = addCmdlineOption(cmdline, params, "Alpha");
  cmdline = addCmdlineOption(cmdline, params, "dAlpha");
  cmdline = addCmdlineOption(cmdline, params, "Delta");
  cmdline = addCmdlineOption(cmdline, params, "Freq");
  cmdline = addCmdlineOption(cmdline, params, "f1dot");
  cmdline = addCmdlineOption(cmdline, params, "startTime");
  cmdline = addCmdlineOption(cmdline, params, "duration");
  cmdline = addCmdlineOption(cmdline, params, "ephemDir");
  cmdline = addCmdlineOption(cmdline, params, "ephemYear");
  cmdline = addCmdlineOption(cmdline, params, "cosi");
  cmdline = addCmdlineOption(cmdline, params, "psi");
  cmdline = addCmdlineOption(cmdline, params, "outputMetric");
  cmdline = addCmdlineOption(cmdline, params, "projection");
  cmdline = addCmdlineOption(cmdline, params, "coords");
  cmdline = addCmdlineOption(cmdline, params, "fullFmetric");
  cmdline = addCmdlineOption(cmdline, params, "detMotionType");
  cmdline = addCmdlineOption(cmdline, params, "version");

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
  [status, out] = system(cmdline);
  if ( status != 0 )
    fprintf (stderr, "\nSomething failed in running '%s'\n\n", fmCode);
    error ("Commandline was: %s", cmdline);
  endif

  return;

endfunction %% runFstatMetric_v2()
