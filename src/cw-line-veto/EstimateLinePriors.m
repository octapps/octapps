## Copyright (C) 2013 David Keitel
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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{ret} =} EstimateLinePriors ( @var{varargin} )
##
## Script to estimate oLGX priors from some SFTs
## based on compute_lX_from_SFTs from LineVetoBstat repository, but with simpler SFTs and timestamps handling
## this is different from TuneAdaptiveLVPriors which is more EatH-centric, assuming a given run setup
## command-line parameters can be taken from parseOptions call below
## example call: octapps_run EstimateLinePriors --SFTs=h1*
##
## @end deftypefn

function ret = EstimateLinePriors ( varargin )

  ## read in and check input parameters
  params_init = parseOptions(varargin,
                             ## required arguments
                             {"IFOs",            "char", "H1,L1"},
                             {"SFTs",            "char"},
                             {"psdfiles",        "char", ""}, ## comma-separated list of output files
                             ## options for ComputePSD
                             {"rngmedbins",      "numeric,scalar,positive", 101},
                             {"PSDmthopSFTs",    "numeric,scalar,strictpos", 4},
                             {"PSDmthopIFOs",    "numeric,scalar,strictpos", 4},
                             {"nSFTmthopSFTs",   "numeric,scalar,strictpos", 1},
                             {"nSFTmthopIFOs",   "numeric,scalar,strictpos", 8},
                             ## basic frequency band options
                             {"freq",            "numeric,scalar", -1},
                             {"freqband",        "numeric,scalar", -1},
                             ## options to predict a HSGCT-equivalent band
                             {"getgctband",      "bool,scalar", false},
                             {"dfreq",           "numeric,scalar,positive", 0},
                             {"f1dot",           "numeric,scalar", 0},
                             {"f1dotband",       "numeric,scalar,positive", 0},
                             {"df1dot",          "numeric,scalar,positive", 0},
                             {"f2dot",           "numeric,scalar", 0},
                             {"f2dotband",       "numeric,scalar,positive", 0},
                             {"df2dot",          "numeric,scalar,positive", 0},
                             {"Dterms",          "numeric,scalar,strictpos", 8},
                             ## timestamps options (needed both for PSD over right SFTs and fA->thresh conversion)
                             {"Tsft",            "numeric,scalar,strictpos", 1800},
                             {"startTime",       "numeric,scalar", -1},
                             {"duration",        "numeric,scalar,positive", 0},
                             {"timestampsfiles", "char", ""},
                             {"segmentsfile",    "char", ""},
                             ## directly line-prior related options
                             {"SFTpower_thresh", "char", ""},
                             {"SFTpower_fA",     "char", ""},
                             {"oLGXmin",         "numeric,scalar,positive", 0.001}, ## enforces lower cutoff; negative value will be used to determine from numfreqbins
                             {"oLGXmax",         "numeric,scalar,positive", 1000}, ## enforces upper cutoff; negative value will be used to determine from numfreqbins
                             ## misc options
                             {"debug",           "bool,scalar", false},
                             {"cleanup",         "bool,scalar", false},
                             {"lalpath",         "char", ""}
                            );
  params_init = check_input_parameters ( params_init ); ## this already processes some of the input params

  if ( params_init.debug )
    printf("Running from directory '%s'. LAL path is '%s'. Local octave version is '%s'. Input parameters are:\n", pwd, params_init.lalpath, version);
    params_init
  endif

  ## set up timestamps, if requested
  timestamps.Tsft            = params_init.Tsft;
  timestamps.timestampsfiles = [];
  if ( ( params_init.startTime >= 0 ) && ( params_init.duration > 0 ) )
    timestamps.startTime      = params_init.startTime;
    timestamps.duration       = params_init.duration;
  elseif ( !isempty(params_init.timestampsfiles) )
    timestamps.endTime        = 0;
    timestamps.startTime      = Inf;
    for X = 1:1:params_init.numDet
      if ( iscell(params_init.timestampsfiles) )
        timestamps.timestampsfiles{X} = params_init.timestampsfiles{X};
      else
        timestamps.timestampsfiles{X} = params_init.timestampsfiles;
      endif
      timestamps_in            = load(timestamps.timestampsfiles{X});
      timestamps.startTime     = min(timestamps.startTime,min(timestamps_in(:,1)));
      timestamps.endTime       = max(timestamps.endTime,max(timestamps_in(:,1)));
    endfor
    timestamps.duration       = timestamps.endTime + timestamps.Tsft - timestamps.startTime;
  elseif ( !isempty(params_init.segmentsfile) )
    segments                  = load(params_init.segmentsfile);
    timestamps.startTime      = min(segments(:,1));
    timestamps.duration       = max(segments(:,2)) - timestamps.startTime;
  elseif ( params_init.getgctband )
    error("Incompatible input parameters: For getgctband=1, Need either startTime, duration or timestampsfiles or segmentsfiles.");
  endif
  if ( params_init.getgctband )
    timestamps.midTime = timestamps.startTime + 0.5*timestamps.duration;
  endif

  ## set common ComputePSD parameters
  ComputePSD      = [params_init.lalpath, "lalapps_ComputePSD"];
  params_psd.blocksRngMed     = params_init.rngmedbins;
  params_psd.PSDmthopSFTs     = params_init.PSDmthopSFTs;
  params_psd.PSDmthopIFOs     = params_init.PSDmthopIFOs;
  params_psd.nSFTmthopSFTs    = params_init.nSFTmthopSFTs;
  params_psd.nSFTmthopIFOs    = params_init.nSFTmthopIFOs;
  params_psd.outputNormSFT    = true;
  if ( params_init.debug )
    params_psd.LAL_DEBUG_LEVEL = "MSGLVL2"; ## errors and warnings
  else
    params_psd.LAL_DEBUG_LEVEL = 0;
  endif

  if ( params_init.getgctband ) ## predict the SFT readin band that HSGCT needs for the given parameter space
    deltaFsft = 1.0/timestamps.Tsft;
    if ( params_init.debug )
      printf("Predicting HSGCT data read-in frequency band...\n");
    endif
    [gct_freq_min, gct_freq_band] = PredictGCTFreqbandLegacy ( params_init.freq, params_init.freqband, params_init.dfreq, params_init.f1dot, params_init.f1dotband, params_init.df1dot, params_init.f2dot, params_init.f2dotband, params_init.df2dot, timestamps.startTime, timestamps.duration, timestamps.midTime, deltaFsft, params_init.rngmedbins, params_init.Dterms );
    if ( params_init.debug )
      printf("...obtained gct_freq_min=%.16f, gct_freq_band=%.16f\n", gct_freq_min, gct_freq_band);
    endif
    rngmedwing          = fix(params_init.rngmedbins/2 + 1) * deltaFsft; ## as in lalapps_HierarchSearchGCT and lalapps_ComputePSD, this will be applied to both sides, leading to 1 extra bin in effect
    params_psd.Freq     = gct_freq_min  + rngmedwing - params_init.Dterms * deltaFsft;
    params_psd.FreqBand = gct_freq_band + 2.0 * ( -rngmedwing + params_init.Dterms * deltaFsft );
  elseif ( ( params_init.freq != -1 ) && ( params_init.freqband != -1 ) )
    params_psd.Freq     = params_init.freq;
    params_psd.FreqBand = params_init.freqband;
  endif
  if ( params_init.debug )
    printf("Total frequency range for PSD estimation: Freq=%.16f, FreqBand=%.16f\n", params_psd.Freq, params_psd.FreqBand);
  endif

  ## for each IFO, compute the PSD and normSFT files
  for X = 1:1:params_init.numDet
    params_psd.inputData       = params_init.SFTs{X};
    params_psd.outputPSD       = params_init.psdfiles{X};
    if ( iscell(timestamps.timestampsfiles) )
      params_psd.timeStampsFile = timestamps.timestampsfiles{X};
    elseif ( !isempty(timestamps.timestampsfiles) )
      params_psd.timeStampsFile = timestamps.timestampsfiles;
    endif
    runCode ( params_psd, ComputePSD );
  endfor ##  X = 1:1:params_init.numDet

  if ( !isempty(params_init.SFTpower_fA) ) ## get number of SFT bins needed to convert from fA to thresh

    if ( params_init.debug )
      printf("Converting fA to thresh...\n");
    endif

    if ( !isempty(timestamps.timestampsfiles) )
      if ( iscell(timestamps.timestampsfiles) )
        for X=1:1:params_init.numDet
          num_SFTs(X) = length(load(timestamps.timestampsfiles{X}));
        endfor
      else
        num_SFTs = length(load(timestamps.timestampsfiles));
      endif
    else ## !isempty(timestamps.timestampsfiles)
      for X=1:1:params_init.numDet
        num_SFTs(X) = GetNumSFTsFromFile ( params_init.SFTs{X} );
      endfor
    endif ## ?isempty(timestamps.timestampsfiles)

    if ( length(num_SFTs) > 1 )
      for X=1:1:params_init.numDet
        thresh(X,:) = ComputeSFTPowerThresholdFromFA ( params_init.SFTpower_fA, num_SFTs(X) );
      endfor
    else
      for n=1:1:length(params_init.SFTpower_fA)
        thresh(:,n) = ComputeSFTPowerThresholdFromFA ( params_init.SFTpower_fA, num_SFTs ) * ones(params_init.numDet,1);
      endfor
    endif ## length(num_SFTs) > 1

  else ## isempty(params_init.SFTpower_fA)

    thresh = params_init.SFTpower_thresh;

  endif ## ?isempty(params_init.SFTpower_fA)

  if ( params_init.debug )
    printf("Estimating oLGX priors from normalized SFT power...\n");
  endif
  [oLGX, freqmin, freqmax, freqbins, num_outliers, max_outlier] = EstimateLinePriorsFromNormSFT (params_init.psdfiles, thresh, params_init.oLGXmin, params_init.oLGXmax);

  for n = 1:1:length(thresh(1,:))
    if ( params_init.debug && !isempty(params_init.SFTpower_fA) )
      printf("fA=%g:\n", params_init.SFTpower_fA(n));
    elseif ( n > 1 )
      printf(";");
    endif
    for X=1:1:params_init.numDet;
      if ( params_init.debug )
        printf("%s: feff=[%f,%f] Hz, freqbins=%d, thresh=%f: num_outliers=%d, oLGX=%.9f\n", params_init.IFOs{X}, freqmin(X), freqmax(X), freqbins(X), thresh(X,n), num_outliers(X,n), oLGX(X,n));
      else
        if ( X > 1 )
          printf(",");
        endif
        printf("%.9f", oLGX(X,n));
      endif
    endfor
  endfor
  if ( !params_init.debug )
    printf("\n");
  endif

  ## Clean up temporary files
  if ( params_init.cleanup )
    if ( params_init.debug )
      printf("Cleaning up temporary PSD files...\n");
    endif
    for X=1:1:length(params_init.psdfiles)
      [err, msg] = unlink (params_init.psdfiles{X});
    endfor
  endif

  ret = 1;

endfunction ## EstimateLinePriors()

############## AUXILIARY FUNCTIONS #############

function params_init = check_input_parameters ( params_init )
  ## params_init = check_input_parameters ( params_init )
  ## function to parse argument list into variables and check consistency

  params_init.IFOs   = strsplit(params_init.IFOs,",");
  params_init.numDet = length(params_init.IFOs);

  params_init.SFTs = strsplit(params_init.SFTs,",");
  if ( length(params_init.SFTs) != params_init.numDet )
    error("Incompatible input arguments: IFOs has length %d but SFTs has length %d.", params_init.numDet, length(params_init.SFTs));
  endif

  if ( !isempty(params_init.psdfiles) )
    params_init.psdfiles = strsplit(params_init.psdfiles,",");
    if ( length(params_init.psdfiles) != params_init.numDet )
      error("Incompatible input arguments: IFOs has length %d but psdfiles has length %d.", params_init.numDet, length(params_init.psdfiles));
    endif
  else
    params_init.psdfiles = [];
    for X=1:1:params_init.numDet
      params_init.psdfiles{X} = ["./temp_psd_", params_init.IFOs{X}, ".dat"];
    endfor
  endif

  ## basic frequency band options

  if ( ( params_init.freq < 0.0 ) && ( params_init.freq != -1 ) )
    error("Invalid input parameter (freq): %f is negative and not -1 (use full band).", params_init.freq)
  endif

  if ( ( params_init.freqband < 0.0 ) && ( params_init.freqband != -1 ) )
    error("Invalid input parameter (freqband): %f is neither -1 nor >= 0.", params_init.freqband);
  endif

  ## timestamps options (needed both for PSD over right SFTs and fA->thresh conversion)

  if ( !isempty(params_init.segmentsfile) && !exist(params_init.segmentsfile,"file") )
    error("Invalid input parameter (segmentsfile): %s is not an existing file.", params_init.segmentsfile);
  endif

  if ( !isempty(params_init.timestampsfiles) )
    tssplit = strsplit(params_init.timestampsfiles,",");
    if ( length(tssplit) > 1 )
      if ( length(tssplit) != params_init.numDet )
        error("Incompatible input parameters: timestampsfiles has %d elements, but IFOs has %d.", length(tssplit), params_init.numDet);
      endif
      params_init.timestampsfiles = [];
      for X=1:1:length(tssplit)
        params_init.timestampsfiles{X} = tssplit{X};
        if ( !strcmp(params_init.timestampsfiles{X},"none") && !exist(params_init.timestampsfiles{X},"file") ) ## no cross-check with starttime here
          error("Invalid input parameter (timestampsfiles): entry %d of %d in comma-separated list is '%s' which is neither 'none' nor an existing file.", X, length(tssplit), params_init.timestampsfiles{X});
        endif
      endfor ## X=1:1:length(tssplit)
    elseif ( !exist(params_init.timestampsfiles,"file") ) ##  length(tssplit) <= 1
      error("Invalid input parameter (timestampsfiles): '%s' is neither 'none' nor an existing file.", params_init.timestampsfiles);
    endif ## length(tssplit) > 1
  endif ## !strcmp(params_init.timestampsfiles,"none")

  ## directly line-prior related options

  if ( !isempty(params_init.SFTpower_thresh) )
    vectsplit = strsplit(params_init.SFTpower_thresh,";");
    params_init.SFTpower_thresh = zeros(params_init.numDet,length(vectsplit));
    for n=1:1:length(vectsplit)
      vectsplit2 = strsplit(vectsplit{n},",");
      if ( length(vectsplit2) != params_init.numDet )
        error("Incompatible input arguments: IFOs has length %d but SFTpower_thresh has length %d (;-separated group %d/%d).", params_init.numDet, length(vectsplit2), n, length(vectsplit));
      endif
      for X=1:1:length(vectsplit2)
        valueX = str2num(vectsplit2{X});
        if ( isempty(valueX) )
          error("Invalid input parameter (SFTpower_thresh): value %d of %d in comma-separated list is '%s' which is not a numeric value (;-separated group %d/%d).", X, length(vectsplit2), vectsplit2{X}, n, length(vectsplit));
        else
          params_init.SFTpower_thresh(X,n) = valueX;
          if ( params_init.SFTpower_thresh(X,n) < 0 )
            error("Invalid input parameter (SFTpower_thresh): value %d of %d in comma-separated list is '%d' which is negative (;-separated group %d/%d).", X, length(vectsplit2), vectsplit2{X}, n, length(vectsplit));
          endif
        endif
      endfor ## X=1:1:length(vectsplit2)
    endfor ## n=1:1:length(vectsplit)
  endif ## ength(params_init.SFTpower_thresh) > 0

  if ( !isempty(params_init.SFTpower_fA) )
    vectsplit = strsplit(params_init.SFTpower_fA,",");
    params_init.SFTpower_fA = zeros(1,length(vectsplit));
    for n=1:1:length(vectsplit)
      value_n = str2num(vectsplit{n});
      if ( isempty(value_n) )
        error("Invalid input parameter (SFTpower_fA): value %d of %d in comma-separated list is '%s' which is not a numeric value.", n, length(vectsplit), vectsplit{n});
      else
        params_init.SFTpower_fA(n) = value_n;
        if ( params_init.SFTpower_fA(n) < 0 )
          error("Invalid input parameter (SFTpower_fA): value %d of %d in comma-separated list is '%s' which is negative.", n, length(vectsplit), vectsplit{n});
        endif
      endif
    endfor
  endif ## !isempty(params_init.SFTpower_fA)

  if ( isempty(params_init.SFTpower_thresh) && isempty(params_init.SFTpower_fA) )
    error("Incompatible input parameters: need either SFTpower_thresh or SFTpower_fA.");
  endif

  if ( !isempty(params_init.SFTpower_thresh) && !isempty(params_init.SFTpower_fA) )
    error("Incompatible input parameters: can't have both SFTpower_thresh and SFTpower_fA.")
  endif

  ## misc options

  if ( !isempty(params_init.lalpath) && !isdir(params_init.lalpath) )
    error("Invalid input parameter (lalpath): %s is not a valid directory.", params_init.lalpath);
  endif

endfunction ## EstimateLinePriors()

%!test disp("no test exists for this function as it requires access to data not included in OctApps")
