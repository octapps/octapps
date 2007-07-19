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

function runFstatMetric (params, fmCode)
  %% function runFstatMetric (params)
  %% general driver for 'FstatMetric'
  global debug;

  if ( !exist("params" ) )
    error("Missing function argument 'params'\n");
  endif

  if ( !exist("fmCode") )
    fmCode = "FstatMetric";
  endif

  %% first handle all *required* params
  if ( !isfield(params, "IFOs" ) )
    error("Required FstatMetric-option 'IFOs' is missing in params\n");
  endif

  cmdline = fmCode;

  %% ----- target parameters
  cmdline = addCmdlineOption(cmdline, params, "IFOs");
  cmdline = addCmdlineOption(cmdline, params, "IFOweights");
  cmdline = addCmdlineOption(cmdline, params, "Alpha");
  cmdline = addCmdlineOption(cmdline, params, "dAlpha");
  cmdline = addCmdlineOption(cmdline, params, "Delta");
  cmdline = addCmdlineOption(cmdline, params, "dDelta");
  cmdline = addCmdlineOption(cmdline, params, "Freq");
  cmdline = addCmdlineOption(cmdline, params, "dFreq");
  cmdline = addCmdlineOption(cmdline, params, "f1dot");
  cmdline = addCmdlineOption(cmdline, params, "df1dot");
  cmdline = addCmdlineOption(cmdline, params, "startTime");
  cmdline = addCmdlineOption(cmdline, params, "refTime");
  cmdline = addCmdlineOption(cmdline, params, "duration");
  cmdline = addCmdlineOption(cmdline, params, "numSteps");
  cmdline = addCmdlineOption(cmdline, params, "ephemDir");
  cmdline = addCmdlineOption(cmdline, params, "ephemYear");
  cmdline = addCmdlineOption(cmdline, params, "cosi");
  cmdline = addCmdlineOption(cmdline, params, "psi");
  cmdline = addCmdlineOption(cmdline, params, "printMotion");
  cmdline = addCmdlineOption(cmdline, params, "outputMetric");
  cmdline = addCmdlineOption(cmdline, params, "metricType");
  cmdline = addCmdlineOption(cmdline, params, "unitsType");

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
  [out, status] = system(cmdline);
  if ( status != 0 )
    printf ("\nSomething failed in running '%s'\n\n", fmCode);
    error ("Commandline was: %s", cmdline);
  endif
  
  return;

endfunction %% runFstatMetric()
