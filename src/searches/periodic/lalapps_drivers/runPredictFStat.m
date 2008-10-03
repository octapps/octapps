%% runPredictFStat (params, pfsCode)
%%
%% general PredictFStat driver: pass any commandline options in 'params'
%% and run pfs code, optionally specifying a binary
%% 'pfsCode' (default = "lalapps_PredictFStat")
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

function ret = runPredictFStat (params, pfsCode)
  global debug;

  if ( !exist("params" ) )
    error("Missing function argument 'params'\n");
  endif
  if ( !exist("pfsCode") )
    pfsCode = "lalapps_PredictFStat";
  endif

  cmdline = pfsCode;

  cmdline = addCmdlineOption(cmdline, params, "h0" );
  cmdline = addCmdlineOption(cmdline, params, "cosi" );
  cmdline = addCmdlineOption(cmdline, params, "aPlus" );
  cmdline = addCmdlineOption(cmdline, params, "aCross");
  cmdline = addCmdlineOption(cmdline, params, "psi");
  cmdline = addCmdlineOption(cmdline, params, "Alpha" );
  cmdline = addCmdlineOption(cmdline, params, "Delta" );
  cmdline = addCmdlineOption(cmdline, params, "Freq" );
  cmdline = addCmdlineOption(cmdline, params, "DataFiles" );

  %% optional params
  cmdline = addCmdlineOption(cmdline, params, "IFO");
  cmdline = addCmdlineOption(cmdline, params, "ephemDir" );
  cmdline = addCmdlineOption(cmdline, params, "ephemYear" );
  cmdline = addCmdlineOption(cmdline, params, "minStartTime" );
  cmdline = addCmdlineOption(cmdline, params, "maxEndTime" );
  cmdline = addCmdlineOption(cmdline, params, "RngMedWindow" );
  cmdline = addCmdlineOption(cmdline, params, "SignalOnly" );

  %% get output into a file
  if ( !isfield(params, "outputFstat") )
    params.outputFstat = "__pfs__.dat";
  endif
  cmdline = addCmdlineOption(cmdline, params, "outputFstat" );

  if ( isfield(params, "lalDebugLevel" ) && params.lalDebugLevel )
    cmdline = sprintf ( "%s -v%d", cmdline, params.lalDebugLevel )
  endif

  if ( debug )
    printf ("%s\n", cmdline );
  endif

  %% ----- and run it:
  [status, out] = system29(cmdline);
  if ( status != 0 )
    printf ("\nSomething failed in running '%s'\n\n", pfsCode);
    error ("Commandline was: %s", cmdline);
  endif

  %% ----- read output
  source( params.outputFstat );

  ret = [ twoF_expected, twoF_sigma ];	%% E[2F], sigma(2F)

  return;

endfunction % runPredictFStat

