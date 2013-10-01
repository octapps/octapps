function ret = EstimateLinePriors ( varargin )
 %% ret = EstimateLinePriors ( varargin )
 %% Script to estimate lX priors from some SFTs
 %% based on compute_lX_from_SFTs from LineVetoBstat repository, but with simpler SFTs and timestamps handling
 %% this is different from TuneAdaptiveLVPriors which is more EatH-centric, assuming a given run setup
 %% command-line parameters can be taken from parseOptions call below
 %% example call: octapps_run EstimateLinePriors --SFTs=h1*

 % read in and check input parameters
 params_init = parseOptions(varargin,
 # required arguments
                     {"IFOs", "char", "H1,L1"},
                     {"SFTs", "char"},
                     {"psdfiles", "char", ""}, # comma-separated list of output files
 # options for ComputePSD
                     {"rngmedbins", "numeric,scalar", 101},
                     {"PSDmthopSFTs", "numeric,scalar", 4},
                     {"PSDmthopIFOs", "numeric,scalar", 4},
                     {"nSFTmthopSFTs", "numeric,scalar", 1},
                     {"nSFTmthopIFOs", "numeric,scalar", 8},
 # basic frequency band options
                     {"freq", "numeric,scalar", -1},
                     {"freqband", "numeric,scalar", -1},
 # options to predict a HSGCT-equivalent band
                     {"getgctband", "numeric,scalar", 0},
                     {"dfreq", "numeric,scalar", 0},
                     {"f1dot", "numeric,scalar", 0},
                     {"f1dotband", "numeric,scalar", 0},
                     {"df1dot", "numeric,scalar", 0},
                     {"f2dot", "numeric,scalar", 0},
                     {"f2dotband", "numeric,scalar", 0},
                     {"df2dot", "numeric,scalar", 0},
                     {"Dterms", "numeric,scalar", 8},
 # timestamps options (needed both for PSD over right SFTs and fA->thresh conversion)
                     {"Tsft", "numeric,scalar", 1800},
                     {"startTime", "numeric,scalar", -1},
                     {"duration", "numeric,scalar", 0},
                     {"timestampsfiles", "char", "none"},
                     {"segmentsfile", "char", "none"},
 # directly line-prior related options
                     {"SFTpower_thresh", "char", ""},
                     {"SFTpower_fA", "char", ""},
                     {"LVlmin", "numeric,scalar", 0.001}, # enforces lower cutoff; negative value will be used to determine from numfreqbins
                     {"LVlmax", "numeric,scalar", 1000}, # enforces upper cutoff; negative value will be used to determine from numfreqbins
 # misc options
                     {"debug", "numeric,scalar", 0},
                     {"cleanup", "numeric,scalar", 0},
                     {"lalpath", "char", ""}
                );
 params_init = check_input_parameters ( params_init ); # this already processes some of the input params

 if ( params_init.debug == 1 )
  printf("Running from directory '%s'. LAL path is '%s'. Local octave version is '%s'. Input parameters are:\n", pwd, params_init.lalpath, version);
  params_init
 endif

 % set up timestamps, if requested
 timestamps.Tsft       = params_init.Tsft;
 if ( ( params_init.startTime >= 0 ) && ( params_init.duration > 0 ) )
  timestamps.startTime = params_init.startTime;
  timestamps.duration  = params_init.duration;
  timestamps.timestampsfiles = [];
 elseif ( strcmp(params_init.timestampsfiles,"none") != 1 )
  timestamps.endTime   = 0;
  timestamps.startTime = Inf;
  for X = 1:1:params_init.numDet
   if ( iscell(params_init.timestampsfiles) )
    timestamps.timestampsfiles{X} = params_init.timestampsfiles{X};
   else
    timestamps.timestampsfiles{X} = params_init.timestampsfiles;
   endif
   timestamps_in = load(timestamps.timestampsfiles{X});
   timestamps.startTime = min(timestamps.startTime,min(timestamps_in(:,1)));
   timestamps.endTime   = max(timestamps.endTime,max(timestamps_in(:,1)));
  endfor
  timestamps.duration  = timestamps.endTime + timestamps.Tsft - timestamps.startTime;
 elseif ( strcmp(params_init.segmentsfile,"none") != 1 )
  segments = load(params_init.segmentsfile);
  timestamps.startTime = min(segments(:,1));
  timestamps.duration  = max(segments(:,2)) - timestamps.startTime;
  timestamps.timestampsfiles = [];
 else
  error("Invalid input parameters: Need either startTime, duration or timestampsfiles or segmentsfiles.");
 endif
 timestamps.midTime = timestamps.startTime + 0.5*timestamps.duration;

 % set common ComputePSD parameters
 ComputePSD      = [params_init.lalpath, "lalapps_ComputePSD"];
 params_psd.blocksRngMed  = params_init.rngmedbins;
 params_psd.PSDmthopSFTs  = params_init.PSDmthopSFTs;
 params_psd.PSDmthopIFOs  = params_init.PSDmthopIFOs;
 params_psd.nSFTmthopSFTs = params_init.nSFTmthopSFTs;
 params_psd.nSFTmthopIFOs = params_init.nSFTmthopIFOs;
 params_psd.outputNormSFT = 1;

 if ( params_init.getgctband == 1 ) # predict the SFT readin band that HSGCT needs for the given parameter space
  deltaFsft = 1.0/timestamps.Tsft;
  [gct_freq_min, gct_freq_band] = PredictGCTFreqband ( params_init.freq, params_init.freqband, params_init.dfreq, params_init.f1dot, params_init.f1dotband, params_init.df1dot, params_init.f2dot, params_init.f2dotband, params_init.df2dot, timestamps.startTime, timestamps.duration, timestamps.midTime, deltaFsft, params_init.rngmedbins, params_init.Dterms );
  rngmedwing = fix(params_init.rngmedbins/2 + 1) * deltaFsft; # as in lalapps_HierarchSearchGCT and lalapps_ComputePSD, this will be applied to both sides, leading to 1 extra bin in effect
  params_psd.Freq = gct_freq_min  + rngmedwing - params_init.Dterms * deltaFsft;
  params_psd.FreqBand = gct_freq_band + 2.0 * ( -rngmedwing + params_init.Dterms * deltaFsft );
 elseif ( ( params_init.freq != -1 ) && ( params_init.freqband != -1 ) )
  params_psd.Freq = params_init.freq;
  params_psd.FreqBand = params_init.freqband;
 endif

 # compute the PSD and normSFT files
 for X = 1:1:length(params_init.IFOs)
  params_psd.inputData = params_init.SFTs{X};
  params_psd.outputPSD = params_init.psdfiles{X};
  if ( iscell(timestamps.timestampsfiles) )
   params_psd.timeStampsFile = timestamps.timestampsfiles{X};
  elseif ( length(timestamps.timestampsfiles) > 0 )
   params_psd.timeStampsFile = timestamps.timestampsfiles;
  endif
  runCode ( params_psd, ComputePSD );
 endfor #  X = 1:1:length(IFOs)

 if ( length(params_init.SFTpower_fA) > 0 ) # get number of SFT bins needed to convert from fA to thresh

  if ( params_init.debug == 1 )
   printf("Converting fA to thresh...\n");
  endif

  if ( length(timestamps.timestampsfiles) > 0 )
   if ( iscell(timestamps.timestampsfiles) )
    for X=1:1:numDet
     num_SFTs(X) = length(load(timestamps.timestampsfiles{X}));
    endfor
   else
    num_SFTs = length(load(timestamps.timestampsfiles));
   endif
  else # length(timestamps.timestampsfiles) == 0
   for X=1:1:params_init.numDet
    num_SFTs(X) = GetNumSFTsFromFile ( params_init.SFTs{X} );
   endfor
  endif # length(timestamps.timestampsfiles) > 0

  if ( length(num_SFTs) > 1 )
   for X=1:1:params_init.numDet
    thresh(X,:) = ComputeSFTPowerThresholdFromFA ( params_init.SFTpower_fA, num_SFTs(X) );
   endfor
  else
   for n=1:1:length(params_init.SFTpower_fA)
    thresh(:,n) = ComputeSFTPowerThresholdFromFA ( params_init.SFTpower_fA, num_SFTs ) * ones(params_init.numDet,1);
   endfor
  endif # length(num_SFTs) > 1

 else # length(params_init.SFTpower_fA) == 0

  thresh = params_init.SFTpower_thresh;

 endif # length(params_init.SFTpower_fA) > 0

 if ( params_init.debug == 1 )
  printf("Obtaining lX priors from normalized SFT power...\n");
 endif
 [lX, freqmin, freqmax, freqbins, num_outliers, max_outlier] = EstimateLinePriorsFromNormSFT (params_init.psdfiles, thresh, params_init.LVlmin, params_init.LVlmax);

 for n = 1:1:length(thresh(1,:))
  if ( ( params_init.debug == 1 ) && ( length(params_init.SFTpower_fA) > 0 ) )
   printf("fA=%g:\n", params_init.SFTpower_fA(n));
  elseif ( n > 1 )
   printf(";");
  endif
  for X=1:1:params_init.numDet;
   if ( params_init.debug == 1 ) 
    printf("%s: feff=[%f,%f] Hz, freqbins=%d, thresh=%f: num_outliers=%d, lX=oLGX=%.9f\n", params_init.IFOs{X}, freqmin(X), freqmax(X), freqbins(X), thresh(X,n), num_outliers(X,n), lX(X,n));
   else
    if ( X > 1 )
     printf(",");
    endif
    printf("%.9f", lX(X,n));
   endif
  endfor
 endfor
 if ( params_init.debug == 0 )
  printf("\n");
 endif

 % Clean up temporary files
 if ( params_init.cleanup == 1 )
  if ( params_init.debug == 1 )
   printf("Cleaning up temporary PSD files...\n");
  endif
  for X=1:1:length(params_init.psdfiles)
   [err, msg] = unlink (params_init.psdfiles{X});
  endfor
 endif

 ret = 1;

endfunction # EstimateLinePriors()


%%%%%%%%%%%%%% AUXILIARY FUNCTIONS %%%%%%%%%%%%%

function [params_init] = check_input_parameters ( params_init )
 %% [params_init] = check_input_parameters ( params_init )
 %% function to parse argument list into variables and check consistency

 params_init.IFOs   = strsplit(params_init.IFOs,",");
 params_init.numDet = length(params_init.IFOs);

 params_init.SFTs = strsplit(params_init.SFTs,",");
 if ( length(params_init.SFTs) != params_init.numDet )
  error(["Incompatible input arguments: IFOs has length ", int2str(params_init.numDet), " but SFTs has length ", int2str(length(params_init.SFTs)), "."]);
 endif

 params_init.psdfiles = strsplit(params_init.psdfiles,",");
 if ( length(params_init.psdfiles) != params_init.numDet )
  error(["Incompatible input arguments: IFOs has length ", int2str(params_init.numDet), " but psdfiles has length ", int2str(length(params_init.psdfiles)), "."]);
 endif

 % options for ComputePSD

 if ( params_init.rngmedbins < 0 )
   error(["Invalid input parameter (rngmedbins): ", num2str(params_init.rngmedbins), " is negative."])
 endif

 % basic frequency band options

 if ( ( params_init.freq < 0.0 ) && ( params_init.freq != -1 ) )
  error(["Invalid input parameter (freq): ", num2str(params_init.freq), " is negative and not -1 (use full band)."])
 endif

 if ( ( params_init.freqband < 0.0 ) && ( params_init.freqband != -1 ) )
  error(["Invalid input parameter (freqband): ", num2str(params_init.freqband), " is neither -1 nor >= 0."])
 endif

 % options to predict a HSGCT-equivalent band

 if ( ( params_init.getgctband != 0 ) && ( params_init.getgctband != 1 ) )
  error(["Invalid input parameter (getgctband): ", int2str(params_init.getgctband), " is neither 0 or 1."])
 endif

 if ( params_init.dfreq < 0.0 )
  error(["Invalid input parameter (dfreq): ", num2str(params_init.dfreq), " is negative."])
 endif

 if ( params_init.df1dot < 0.0 )
  error(["Invalid input parameter (df1dot): ", num2str(params_init.df1dot), " is negative."])
 endif

 if ( params_init.df2dot < 0.0 )
  error(["Invalid input parameter (df2dot): ", num2str(params_init.df2dot), " is negative."])
 endif

 if ( params_init.Dterms <= 0.0 )
  error(["Invalid input parameter (Dterms): ", num2str(params_init.Dterms), " must be > 0."]);
 endif

 % timestamps options (needed both for PSD over right SFTs and fA->thresh conversion)

 if ( ( strcmp(params_init.segmentsfile,"none") != 1 ) && ( exist(params_init.segmentsfile,"file") != 2 ) )
  error(["Invalid input parameter (segmentsfile): ", params_init.segmentsfile, " is neither 'none' nor an existing file."]);
 endif

 if ( strcmp(params_init.timestampsfiles,"none") != 1 )
  tssplit = strsplit(params_init.timestampsfiles,",");
  if ( length(tssplit) > 1 )
   if ( length(tssplit) != params_init.numDet )
    error(["Incompatible input parameters: timestampsfiles has ", int2str(length(tssplit)), " elements, but IFOs has ", int2str(params_init.numDet), "."]);
   endif
   params_init.timestampsfiles = [];
   for X=1:1:length(tssplit)
    params_init.timestampsfiles{X} = tssplit{X};
    if ( ( strcmp(params_init.timestampsfiles{X},"none") != 1 ) && ( exist(params_init.timestampsfiles{X},"file") != 2 ) ) # no cross-check with starttime here, as this is entirely optional (only for cropSFTs and adaptiveLV, not for HSGCT itself)
     error(["Invalid input parameter (timestampsfiles): entry ", int2str(X), " of ", int2str(length(tssplit)), " in comma-separated list is '", params_init.timestampsfiles{X}, "' which is neither 'none' nor an existing file."]);
    endif
   endfor # X=1:1:length(tssplit)
  elseif ( exist(params_init.timestampsfiles,"file") != 2 ) #  length(tssplit) <= 1
   error(["Invalid input parameter (timestampsfiles): '", params_init.timestampsfiles, "' is neither 'none' nor an existing file."]);
  endif # length(tssplit) > 1
 endif # strcmp(params_init.timestampsfiles,"none") != 1

 % directly line-prior related options

 if ( length(params_init.SFTpower_thresh) > 0 )
  vectsplit = strsplit(params_init.SFTpower_thresh,";");
  params_init.SFTpower_thresh = zeros(params_init.numDet,length(vectsplit));
  for n=1:1:length(vectsplit)
   vectsplit2 = strsplit(vectsplit{n},",");
   if ( length(vectsplit2) != params_init.numDet )
    error(["Incompatible input arguments: IFOs has length ", int2str(params_init.numDet), " but SFTpower_thresh has length ", int2str(length(vectsplit2)), " (;-separated group ", int2str(n), "/", int2str(length(vectsplit)), ")."]);
   endif
   for X=1:1:length(vectsplit2)
    valueX = str2num(vectsplit2{X});
    if ( length(valueX) == 0 )
     error(["Invalid input parameter (SFTpower_thresh): value ", num2str(X), " of ", num2str(length(vectsplit2)), " in comma-separated list is '", vectsplit2{X}, "' which is not a numeric value (;-separated group ", int2str(n), "/", int2str(length(vectsplit)), ")."]);
    else
     params_init.SFTpower_thresh(X,n) = valueX;
     if ( params_init.SFTpower_thresh(X,n) < 0 )
      error(["Invalid input parameter (SFTpower_thresh): value ", num2str(X), " of ", num2str(length(vectsplit2)), " in comma-separated list is '", vectsplit2{X}, "' which is negative (;-separated group ", int2str(n), "/", int2str(length(vectsplit)), ")."]);
     endif
    endif
   endfor # X=1:1:length(vectsplit2)
  endfor # n=1:1:length(vectsplit)
 endif # ength(params_init.SFTpower_thresh) > 0

 if ( length(params_init.SFTpower_fA) > 0 )
  vectsplit = strsplit(params_init.SFTpower_fA,",");
  params_init.SFTpower_fA = zeros(1,length(vectsplit));
  for n=1:1:length(vectsplit)
   value_n = str2num(vectsplit{n});
   if ( length(value_n) == 0 )
    error(["Invalid input parameter (SFTpower_fA): value ", num2str(n), " of ", num2str(length(vectsplit)), " in comma-separated list is '", vectsplit{n}, "' which is not a numeric value."]);
   else
    params_init.SFTpower_fA(n) = value_n;
    if ( params_init.SFTpower_fA(n) < 0 )
     error(["Invalid input parameter (SFTpower_fA): value ", num2str(n), " of ", num2str(length(vectsplit)), " in comma-separated list is '", vectsplit{n}, "' which is negative."]);
    endif
   endif
  endfor
 endif # length(params_init.SFTpower_fA) > 0

 if ( ( length(params_init.SFTpower_thresh) == 0 ) && ( length(params_init.SFTpower_fA) == 0 ) )
  error(["Incompatible input parameters: need either SFTpower_thresh or SFTpower_fA."])
 endif

 if ( ( length(params_init.SFTpower_thresh) > 0 ) && ( length(params_init.SFTpower_fA) > 0 ) )
  error(["Incompatible input parameters: can't have both SFTpower_thresh and SFTpower_fA."])
 endif

 % misc options

 if ( ( params_init.debug != 0 ) && ( params_init.debug != 1 ) )
  error(["Invalid input parameter (debug mode): ", int2str(params_init.debug), " is neither 0 or 1."])
 endif

 if ( ( params_init.cleanup != 0 ) && ( params_init.cleanup != 1 ) )
  error(["Invalid input parameter (cleanup temp files?): ", int2str(params_init.cleanup), " is neither 0 or 1."])
 endif

 if ( ( strcmp(params_init.lalpath,"") != 1 ) && !isdir(params_init.lalpath) )
  error(["Invalid input parameter (lalpath): ", params_init.lalpath, " is not a valid directory."]);
 endif

endfunction # EstimateLinePriors()
