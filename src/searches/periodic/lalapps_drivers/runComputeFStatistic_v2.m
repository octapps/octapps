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

function runComputeFStatistic_v2 (params, cfsCode)
  %% function runComputeFStatistic_v2 (params)
  %% general CFSv2 driver: pass any CFS_v2 commandline option in params
  %% and run F-stat search with CFS_v2
  global debug;

  if ( !exist("params" ) )
    error("Missing function argument 'params'\n");
  endif

  if ( !exist("cfsCode") )
    cfsCode = "ComputeFStatistic_v2";
  endif

  %% first handle all *required* params
  if ( !isfield(params, "Freq" ) )
    error("Required CFS-option 'Freq' is missing in params\n");
  endif
  if ( !isfield(params, "DataFiles") )
    error("Required CFS-option 'DataFiles' is missing in params\n");
  endif

  cmdline = cfsCode;

  %% ----- target parameters
  cmdline = addCmdlineOption(cmdline, params, "refTime" );
  cmdline = addCmdlineOption(cmdline, params, "Alpha" );
  cmdline = addCmdlineOption(cmdline, params, "Delta" );
  cmdline = addCmdlineOption(cmdline, params, "Freq" );
  cmdline = addCmdlineOption(cmdline, params, "f1dot" );
  cmdline = addCmdlineOption(cmdline, params, "f2dot" );
  cmdline = addCmdlineOption(cmdline, params, "f3dot" );
  %% ----- search-area
  cmdline = addCmdlineOption(cmdline, params, "AlphaBand" );
  cmdline = addCmdlineOption(cmdline, params, "DeltaBand" );
  cmdline = addCmdlineOption(cmdline, params, "FreqBand" );
  cmdline = addCmdlineOption(cmdline, params, "f1dotBand" );
  cmdline = addCmdlineOption(cmdline, params, "f2dotBand" );
  cmdline = addCmdlineOption(cmdline, params, "f3dotBand" );
  cmdline = addCmdlineOption(cmdline, params, "skyRegion");
  %% ----- resolution
  cmdline = addCmdlineOption(cmdline, params, "dAlpha" );
  cmdline = addCmdlineOption(cmdline, params, "dDelta" );
  cmdline = addCmdlineOption(cmdline, params, "dFreq" );
  cmdline = addCmdlineOption(cmdline, params, "df1dot" );
  cmdline = addCmdlineOption(cmdline, params, "df2dot" );
  cmdline = addCmdlineOption(cmdline, params, "df3dot" );
  cmdline = addCmdlineOption(cmdline, params, "gridType" );
  cmdline = addCmdlineOption(cmdline, params, "metricType" );
  cmdline = addCmdlineOption(cmdline, params, "metricMismatch" );
  cmdline = addCmdlineOption(cmdline, params, "skyGridFile" );

  %% ----- input
  cmdline = addCmdlineOption(cmdline, params, "minStartTime" );
  cmdline = addCmdlineOption(cmdline, params, "maxEndTime" );
  cmdline = addCmdlineOption(cmdline, params, "DataFiles" );
  cmdline = addCmdlineOption(cmdline, params, "IFO");

  %% ----- output
  cmdline = addCmdlineOption(cmdline, params, "NumCandidatesToKeep" );
  cmdline = addCmdlineOption(cmdline, params, "TwoFthreshold" );
  cmdline = addCmdlineOption(cmdline, params, "outputFstat" );
  cmdline = addCmdlineOption(cmdline, params, "outputBstat" );
  cmdline = addCmdlineOption(cmdline, params, "outputLabel" );
  cmdline = addCmdlineOption(cmdline, params, "outputSkyGrid" );
  cmdline = addCmdlineOption(cmdline, params, "outputLoudest" );

  %% ----- misc
  cmdline = addCmdlineOption(cmdline, params, "ephemDir" );
  cmdline = addCmdlineOption(cmdline, params, "ephemYear" );
  cmdline = addCmdlineOption(cmdline, params, "SignalOnly" );
  cmdline = addCmdlineOption(cmdline, params, "dopplermax" );
  cmdline = addCmdlineOption(cmdline, params, "SSBprecision" );
  cmdline = addCmdlineOption(cmdline, params, "RngMedWindow" );
  cmdline = addCmdlineOption(cmdline, params, "Dterms" );
  cmdline = addCmdlineOption(cmdline, params, "workingDir" );
  cmdline = addCmdlineOption(cmdline, params, "internalRefTime" );

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
    printf ("\nSomething failed in running '%s'\n\n", cfsCode);
    error ("Commandline was: %s", cmdline);
  endif
  
  return;

endfunction %% runComputeFStatistic_v2
