%% runMakefakedata (params, mfdCode)
%%
%% general makefakedata driver: pass any commandline options in 'params'
%% and run mfd code, optionally specifying a binary
%% 'mfdCode' (default = "lalapps_Makefakedata_v4")
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

function runMakefakedata (params, mfdCode)
  global debug;

  if ( !exist("params" ) )
    error("Missing function argument 'params'\n");
  endif
  if ( !exist("mfdCode") )
    mfdCode = "lalapps_Makefakedata_v4";
  endif

  cmdline = mfdCode;

  %% signal parameters
  cmdline = addCmdlineOption(cmdline, params, "h0" );
  cmdline = addCmdlineOption(cmdline, params, "cosi" );
  cmdline = addCmdlineOption(cmdline, params, "aPlus" );
  cmdline = addCmdlineOption(cmdline, params, "aCross");
  cmdline = addCmdlineOption(cmdline, params, "psi");
  cmdline = addCmdlineOption(cmdline, params, "phi0");
  cmdline = addCmdlineOption(cmdline, params, "Alpha" );
  cmdline = addCmdlineOption(cmdline, params, "Delta" );
  cmdline = addCmdlineOption(cmdline, params, "Freq" );
  cmdline = addCmdlineOption(cmdline, params, "f1dot" );
  cmdline = addCmdlineOption(cmdline, params, "f2dot" );
  cmdline = addCmdlineOption(cmdline, params, "f3dot" );
  cmdline = addCmdlineOption(cmdline, params, "refTime" );

  %% orbital parameters
  cmdline = addCmdlineOption(cmdline, params, "orbitSemiMajorAxis" );
  cmdline = addCmdlineOption(cmdline, params, "orbitEccentricity" );
  cmdline = addCmdlineOption(cmdline, params, "orbitTperiSSBsec" );
  cmdline = addCmdlineOption(cmdline, params, "orbitTperiSSBns" );
  cmdline = addCmdlineOption(cmdline, params, "orbitPeriod" );
  cmdline = addCmdlineOption(cmdline, params, "orbitArgPeriapse" );

  %% output parameters
  cmdline = addCmdlineOption(cmdline, params, "outSFTbname" );

  cmdline = addCmdlineOption(cmdline, params, "fmin" );
  cmdline = addCmdlineOption(cmdline, params, "Band" );
  cmdline = addCmdlineOption(cmdline, params, "Tsft" );
  cmdline = addCmdlineOption(cmdline, params, "SFToverlap" );

  %% optional params
  cmdline = addCmdlineOption(cmdline, params, "TDDfile" );
  cmdline = addCmdlineOption(cmdline, params, "logfile" );
  cmdline = addCmdlineOption(cmdline, params, "actuation" );
  cmdline = addCmdlineOption(cmdline, params, "actuationScale" );

  cmdline = addCmdlineOption(cmdline, params, "ephemDir" );
  cmdline = addCmdlineOption(cmdline, params, "ephemYear" );

  cmdline = addCmdlineOption(cmdline, params, "IFO");
  cmdline = addCmdlineOption(cmdline, params, "startTime" );
  cmdline = addCmdlineOption(cmdline, params, "duration" );
  cmdline = addCmdlineOption(cmdline, params, "timestampsFile" );
  cmdline = addCmdlineOption(cmdline, params, "generationMode" );

  cmdline = addCmdlineOption(cmdline, params, "noiseSFTs" );
  cmdline = addCmdlineOption(cmdline, params, "noiseSigma" );
  cmdline = addCmdlineOption(cmdline, params, "noiseSqrtSh" );

  cmdline = addCmdlineOption(cmdline, params, "outSFTv1" );
  cmdline = addCmdlineOption(cmdline, params, "exactSignal" );
  cmdline = addCmdlineOption(cmdline, params, "lineFeature" );

  cmdline = addCmdlineOption(cmdline, params, "randSeed" );

  if ( isfield(params, "lalDebugLevel" ) && params.lalDebugLevel )
    cmdline = sprintf ( "%s -v%d", cmdline, params.lalDebugLevel )
  endif

  if ( debug )
    printf ( "%s\n", cmdline );
  endif

  %% ----- and run it:
  [status, out] = system(cmdline);
  if ( status != 0 )
    fprintf (stderr, "\nSomething failed in running '%s'\n\n", mfdCode);
    error ("Commandline was: %s", cmdline);
  endif

  return;

endfunction % runMakefakedata

