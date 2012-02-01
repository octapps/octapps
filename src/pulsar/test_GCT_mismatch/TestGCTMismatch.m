function TestGCTMismatch(varargin)

  ## parse options
  parseOptions(varargin,
               {"SFT_timestamps", "struct"},
               {"GCT_segments", "char"},
               {"start_time", "numeric,scalar"},
               {"end_time", "numeric,scalar"},
               {"Sh", "numeric,scalar"},
               {"h0", "numeric,scalar"},
               {"f1dot_band", "numeric,scalar"},
               {"f2dot_band", "numeric,scalar"},
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
  sft_files = "";
  for i = 1:length(IFOs)
    
    ## generate SFTs
    MFD = struct;
    MFD.Alpha = 2*pi*rand;
    MFD.Delta = (-0.5 + rand)*pi;
    MFD.fmin = 99.75;
    MFD.Band = 0.5;
    MFD.Freq = 100;
    MFD.IFO = IFOs{i};
    MFD.cosi = -1 + 2*rand;
    MFD.ephemYear = "09-11";
    MFD.f1dot = -f1dot_band * rand;
    MFD.f2dot =  f2dot_band * rand;
    MFD.h0 = h0;
    MFD.noiseSqrtSh = Sh;
    MFD.outSFTbname = strcat(IFOs{i}, ".sft");
    MFD.outSingleSFT = true;
    MFD.phi0 = 2*pi*rand;
    MFD.psi = 2*pi*rand;
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
  GM.outputSkyGrid = "GM_skygrid";
  runCode(GM, "lalapps_getMesh -v 1");

  ## run HierarchSearchGCT (no mismatch)
  HSGCT = struct;
  HSGCT.DataFiles1 = sft_files;
  HSGCT.skyGridFile = fullfile(".", GM.outputSkyGrid);
  HSGCT.skyRegion = "allsky";
  HSGCT.gridType1 = 3;
  HSGCT.Freq = MFD.Freq;
  HSGCT.FreqBand = 0.0;
  HSGCT.ephemE = sprintf("earth%s.dat", MFD.ephemYear);
  HSGCT.ephemS = sprintf("sun%s.dat", MFD.ephemYear);
  HSGCT.f1dot = MFD.f1dot;
  HSGCT.f1dotBand = 0.0;
  HSGCT.segmentList = fullfile(".", GCT_segments);
  HSGCT.refTime = start_time;
  HSGCT.peakThrF = 0.0;
  HSGCT.SignalOnly = (Sh == 0.0);
  HSGCT.printCand1 = true;
  HSGCT.semiCohToplist = true;
  HSGCT.fnameout = "HSGCT_Fstats";
  HSGCT.nCand1 = 1;
  runCode(HSGCT, "lalapps_HierarchSearchGCT -d 1");

  ## save no-mismatch Fstat result
  Fstats = load(HSGCT.fnameout);
  result.no_mismatch = Fstats;

  ## create sky position grid for mismatch search
  GM.AlphaBand = 2*pi * 0.01;
  GM.DeltaBand =   pi * 0.01;
  GM.Alpha = MFD.Alpha - 0.5 * GM.AlphaBand;
  GM.Delta = MFD.Delta - 0.5 * GM.DeltaBand;
  runCode(GM, "lalapps_getMesh -v 1");


  ## save results to file
  save(result_file, "result");

endfunction

## if running as a script
if runningAsScript
  TestGCTMismatch(parseCommandLine(){:});
endif
