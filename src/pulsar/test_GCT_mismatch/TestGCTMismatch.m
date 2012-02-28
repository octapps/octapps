## Copyright (C) 2012 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

function TestGCTMismatch(varargin)

  ## parse options
  parseOptions(varargin,
               {"SFT_timestamps", "struct"},
               {"GCT_segments", "char"},
               {"start_time", "numeric,scalar"},
               {"end_time", "numeric,scalar"},
               {"Sh", "numeric,scalar"},
               {"h0", "numeric,scalar"},
               {"freq", "numeric,scalar"},
               {"f1dot_band", "numeric,scalar"},
               {"f2dot_band", "numeric,scalar"},
               {"debug_level", "numeric,scalar"},
               {"result_file", "char"}
               );
  IFOs = fieldnames(SFT_timestamps);

  ## check input
  for i = 1:length(IFOs)
    if !exist(SFT_timestamps.(IFOs{i}), "file")
      error("%s: file '%s' does not exist", funcName, SFT_timestamps.(IFOs{i}));
    endif
  endfor
  if !exist(GCT_segments, "file")
    error("%s: file '%s' does not exist", funcName, GCT_segments);
  endif

  ## initialise result file
  result = struct;
  save(result_file, "result");
  
  ## generate SFTs with injection
  MFD = struct;
  MFD.v = debug_level;
  MFD.Alpha = 2*pi*rand;
  MFD.Delta = (-0.5 + rand)*pi;
  MFD.Freq = freq;
  MFD.Band = 1.0;
  MFD.fmin = MFD.Freq - 0.5*MFD.Band;
  MFD.cosi = -1 + 2*rand;
  MFD.ephemYear = "09-11";
  MFD.f1dot = -f1dot_band * rand;
  MFD.f2dot =  f2dot_band * rand;
  MFD.h0 = h0;
  MFD.noiseSqrtSh = Sh;
  MFD.outSingleSFT = true;
  MFD.phi0 = 2*pi*rand;
  MFD.psi = 2*pi*rand;
  sft_files = "";
  for i = 1:length(IFOs)
    
    ## generate SFTs
    MFD.IFO = IFOs{i};
    MFD.outSFTbname = strcat(IFOs{i}, ".sft");
    MFD.timestampsFile = fullfile(".", SFT_timestamps.(IFOs{i}));
    MFD.refTime = start_time;
    runCode(MFD, "lalapps_Makefakedata_v4");

    ## list of SFTs
    if i > 1
      sft_files = strcat(sft_files, ";");
    endif
    sft_files = strcat(sft_files, MFD.outSFTbname);

  endfor

  ## create single sky position grid 
  GM = struct;
  GM.v = debug_level;
  GM.IFO = IFOs{1};
  GM.Alpha = MFD.Alpha;
  GM.Delta = MFD.Delta;
  GM.AlphaBand = 0.0;
  GM.DeltaBand = 0.0;
  GM.Freq = MFD.Freq;
  GM.startTime = start_time;
  GM.endTime = end_time;
  GM.ephemYear = MFD.ephemYear;
  GM.gridType = 2;
  GM.metricType = 1;
  GM.metricMismatch = 0.3;
  GM.outputSkyGrid = "GM_skygrid";
  runCode(GM, "lalapps_getMesh");

  ## run HierarchSearchGCT (no mismatch)
  HSGCT = struct;
  HSGCT.d = debug_level;
  HSGCT.DataFiles1 = sft_files;
  HSGCT.useWholeSFTs = true;
  HSGCT.skyGridFile = fullfile(".", GM.outputSkyGrid);
  HSGCT.skyRegion = "allsky";
  HSGCT.gridType1 = 3;
  HSGCT.Freq = MFD.Freq;
  HSGCT.FreqBand = 0.0;
  HSGCT.ephemE = sprintf("earth%s.dat", MFD.ephemYear);
  HSGCT.ephemS = sprintf("sun%s.dat", MFD.ephemYear);
  HSGCT.f1dot = MFD.f1dot;
  HSGCT.f1dotBand = 0.0;
  HSGCT.f2dot = MFD.f2dot;
  HSGCT.f2dotBand = 0.0;
  HSGCT.segmentList = fullfile(".", GCT_segments);
  HSGCT.refTime = start_time;
  HSGCT.peakThrF = 0.0;
  HSGCT.SignalOnly = (Sh == 0.0);
  HSGCT.printCand1 = true;
  HSGCT.semiCohToplist = true;
  HSGCT.fnameout = "HSGCT_Fstats";
  HSGCT.nCand1 = 1;
  runCode(HSGCT, "lalapps_HierarchSearchGCT");

  ## save no-mismatch Fstat result
  Fstats = load(HSGCT.fnameout);
  result.no_mismatch = Fstats;

  ## create sky position grid for mismatch search
  GM.AlphaBand = 2*pi * 1e-5;
  GM.DeltaBand =   pi * 1e-5;
  GM.Alpha = MFD.Alpha - 0.5 * GM.AlphaBand;
  GM.Delta = MFD.Delta - 0.5 * GM.DeltaBand;
  runCode(GM, "lalapps_getMesh");

  ## run HierarchSearchGCT (with mismatch)
  HSGCT.Freq = MFD.Freq - 1e-6;
  HSGCT.FreqBand = 2e-5;
  HSGCT.f1dot = MFD.f1dot - 0.01*f1dot_band;
  HSGCT.f1dotBand = 0.02*f1dot_band;
  HSGCT.f2dot = MFD.f2dot - 0.01*f2dot_band;
  HSGCT.f2dotBand = 0.02*f2dot_band;
  runCode(HSGCT, "lalapps_HierarchSearchGCT");

  ## save with-mismatch Fstat result
  Fstats = load(HSGCT.fnameout);
  result.with_mismatch = Fstats;

  ## save results to file
  save(result_file, "result");

endfunction

## if running as a script
if runningAsScript
  TestGCTMismatch(parseCommandLine(){:});
endif
