## Copyright (C) 2012 David Keitel
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
## @deftypefn {Function File} {@var{ret} =} TuneAdaptiveLVPriors ( @var{varargin} )
##
## function to count outliers in SFT power statistic over a large set of frequency bands (input sft files) and derive LV priors from that
## command-line parameters can be taken from parseOptions call below
##
## @heading Example
##
## @verbatim
## octapps_run TuneAdaptiveLVPriors --sftdir=sfts --sft_filenamebit=S6GC1 --freqmin=50 --freqmax=50.5
## @end verbatim
##
## @end deftypefn

function ret = TuneAdaptiveLVPriors ( varargin )

  ## read in and check input parameters
  params_init = parseOptions(varargin,
                             ## essential input
                             {"sftdir",          "char"}, ## directory where the SFTs are stored - can handle either one flat directory or freq-dependent subdirs like "0050"
                             {"sft_filenamebit", "char", ""}, ## run-dependent part of SFT file-names, e.g. S6GC1 for S6Bucket run
                             {"freqmin",         "numeric,scalar,positive"}, ## lower range of input SFT frequencies
                             {"freqmax",         "numeric,scalar,positive", 0}, ## upper range of input SFT frequencies, default: set to freqmin (single step)
                             {"runconfig",       "char"}, ## a file, based on a project-daemons CFS_runname_setup.C file, defining important E@H run quantities
                             {"timestampsfiles", "char", ""}, ## comma-separated list of per-IFO timestamps-files (FIXME: only H1L1 supported)
                             {"SFTpower_thresh", "numeric,scalar,positive", 0}, ## use a fixed threshold for outlier counting
                             {"SFTpower_fA",     "numeric,scalar,positive", 0}, ## compute threshold from false-alarm rate (depends on NSFTX, so can be different for each detector)
                             ## output
                             {"outfile",         "char", "power_outliers.dat"}, ## main output file for the band info and oLGX priors
                             ## additional parameters
                             {"freqstep",        "numeric,scalar,strictpos", 0.05}, ## frequency step (in Hz) in search bands
                             {"sft_width",       "numeric,scalar,strictpos", 0.05}, ## assumed width of each SFT file in Hz
                             {"rngmedbins",      "numeric,scalar,positive", 101}, ## running median bins (including both sides)
                             {"oLGXmin",         "numeric,scalar,positive", 0.001}, ## minimum cutoff for oLGX output
                             {"oLGXmax",         "numeric,scalar,positive", 1000}, ## maximum cutoff for oLGX output
                             {"debug",           "bool,scalar", false}, ## switch for detailed command-line output
                             {"cleanup",         "bool,scalar", true}, ## switch to keep or remove intermediate data products
                             {"workingdir",      "char", "."}, ## local directory where intermediate data is kept
                             {"lalpath",         "char", ""}, ## path to lalapps installation (bin directory)
                             []);
  writeCommandLineToFile ( params_init.outfile, params_init, mfilename );
  params_init = check_input_parameters ( params_init ); ## this already processes some of the input params, so have to do output before

  format long;

  if ( params_init.debug )
    printf("Running from directory '%s'. LAL path is '%s'. Local octave version is '%s'. Input parameters are:\n", pwd, params_init.lalpath, version);
    params_init
  endif

  lalapps_version_string = getLalAppsVersionInfo ([params_init.lalpath, "lalapps_ComputePSD"]);
  fid = fopen ( params_init.outfile, "a" ); ## append mode
  fprintf ( fid, lalapps_version_string );
  fclose ( params_init.outfile );

  global SMALL_EPS = 1.0e-6;

  ## prepare PSD parameters
  params_psd.nSFTmthopSFTs = 1;
  params_psd.nSFTmthopIFOs = 8;
  thresh.H1 = params_init.SFTpower_thresh;
  thresh.L1 = params_init.SFTpower_thresh;

  ## count necessary freqbands and sfts
  ## NOTE: rounded down, freqmax may not be reached if freqmax-freqmin is not an integer multiple of freqstep
  num_freqsteps = 1 + floor ( ( params_init.freqmax - params_init.freqmin ) / params_init.freqstep + SMALL_EPS );

  ## get hardcoded EatH run parameters
  params_run = get_params_run ( params_init.runconfig );

  ## prepare output structs and counting variables
  frequencies     = [];
  freqbins.H1     = [];
  freqbins.L1     = [];
  num_outliers.H1 = [];
  num_outliers.L1 = [];
  max_outlier.H1  = [];
  max_outlier.L1  = [];
  oLGX.H1         = [];
  oLGX.L1         = [];
  curr_step  = 0;
  offset     = 0;
  valid_band = true;
  iFreq0_old = 0;

  ## prepare temporary directory, if it does not exist yet
  if ( isdir ( params_init.workingdir ) )
    use_temp_working_dir = false;
  else
    printf("Working directory '%s' does not exist yet, creating it...\n", params_init.workingdir );
    [status, msg, msgid] = mkdir ( params_init.workingdir );
    if ( status != 1 )
      error (["Failed to create output directory '", params_init.workingdir , "': msg = ", msg, "\n"] );
    endif
    use_temp_working_dir = true;
  endif

  ## main loop over freqbands - break when params_run.FreqMax reached
  while ( ( curr_step < num_freqsteps+offset ) && valid_band )
    curr_step++;

    ## compute the relevant frequencies and bands
    [valid_band, frequencies, offset, iFreq0_old] = get_freq_ranges ( frequencies, params_init, params_run, offset, iFreq0_old, curr_step );

    if ( !valid_band )

      printf("Frequency band %d/%d, WUfreq=%f Hz, physical searchfreq=%f Hz would lie outside params_run.FreqMax=%f, skipping all bands from here on.\n", curr_step, num_freqsteps+offset, frequencies.wu_start(curr_step), frequencies.search_start(curr_step), params_run.FreqMax);

    else

      printf("Frequency band %d/%d, WUfreq=%f Hz, physical searchfreq=%f Hz, width %f Hz: processing band from psd_startfreq=%f Hz with width psd_freqband=%f Hz...\n", curr_step, num_freqsteps+offset, frequencies.wu_start(curr_step), frequencies.search_start(curr_step), params_init.freqstep, frequencies.psd_start(curr_step), frequencies.psd_band(curr_step));

      ## get the correct set of sfts, checking for running median window
      [sftstartfreq, num_sfts_to_load, rngmedbins_effective] = get_sft_range ( params_init, params_run, frequencies.psd_start(curr_step), frequencies.psd_band(curr_step) );

      ## load in all required sfts
      [sfts.h1, firstsft.h1] = get_EatH_sft_paths ( params_init.sftdir, params_init.sft_filenamebit, params_init.sft_width, sftstartfreq, num_sfts_to_load, "h1" );
      [sfts.l1, firstsft.l1] = get_EatH_sft_paths ( params_init.sftdir, params_init.sft_filenamebit, params_init.sft_width, sftstartfreq, num_sfts_to_load, "l1" );

      if ( ( curr_step == 1 ) && ( params_init.SFTpower_fA > 0 ) )
        printf("First band, converting SFTpower_fA=%g to SFTpower_thresh", params_init.SFTpower_fA);
        if ( params_init.usetimestampsfiles ) ## get number of SFTs from timestamps
          printf(" using num_SFTs from timestamps files...\n");
          timestamps_H1 = load(params_init.timestampsfiles{1});
          num_SFTs.H1 = length(timestamps_H1);
          timestamps_L1 = load(params_init.timestampsfiles{2});
          num_SFTs.L1 = length(timestamps_L1);
        else ## get number of SFT bins needed to convert from fA to thresh
          printf(" using num_SFTs from input SFTs...\n");
          printf("Getting num_SFTs from input file '%s' ...\n", firstsft.h1);
          num_SFTs.H1 = GetNumSFTsFromFile ( firstsft.h1 );
          printf("Getting num_SFTs from input file '%s' ...\n", firstsft.l1);
          num_SFTs.L1 = GetNumSFTsFromFile ( firstsft.l1 );
        endif
        thresh.H1 = ComputeSFTPowerThresholdFromFA ( params_init.SFTpower_fA, num_SFTs.H1 );
        thresh.L1 = ComputeSFTPowerThresholdFromFA ( params_init.SFTpower_fA, num_SFTs.L1 );
        printf("H1: num_SFTs=%d, threshold=%f\n", num_SFTs.H1, thresh.H1);
        printf("L1: num_SFTs=%d, threshold=%f\n", num_SFTs.L1, thresh.L1);
      endif

      ## count the outliers in the power statistic
      params_psd.FreqBand       = frequencies.psd_band(curr_step);
      params_psd.Freq           = frequencies.psd_start(curr_step);
      params_psd.blocksRngMed   = rngmedbins_effective;
      params_psd.inputData      = sfts.h1;
      if ( params_init.usetimestampsfiles )
        params_psd.timeStampsFile = params_init.timestampsfiles{1};
      endif
      params_psd.outputPSD      = [params_init.workingdir, filesep, "psd_H1_med_", num2str(params_psd.blocksRngMed), "_band_", int2str(curr_step), ".dat"];
      [num_outliers.H1(curr_step), max_outlier.H1(curr_step), freqbins.H1(curr_step)] = CountSFTPowerOutliers ( params_psd, thresh.H1, params_init.lalpath, params_init.debug );
      if ( params_init.cleanup )
        [err, msg] = unlink (params_psd.outputPSD);
      endif
      params_psd.inputData      = sfts.l1;
      if ( params_init.usetimestampsfiles )
        params_psd.timeStampsFile = params_init.timestampsfiles{2};
      endif
      params_psd.outputPSD      = [params_init.workingdir, filesep, "psd_L1_med_", num2str(params_psd.blocksRngMed), "_band_", int2str(curr_step), ".dat"];
      [num_outliers.L1(curr_step), max_outlier.L1(curr_step), freqbins.L1(curr_step)] = CountSFTPowerOutliers ( params_psd, thresh.L1, params_init.lalpath, params_init.debug );
      if ( params_init.cleanup )
        [err, msg] = unlink (params_psd.outputPSD);
      endif

      ## compute the line prior for H1
      num_bins_below_thresh = (freqbins.H1(curr_step)-num_outliers.H1(curr_step));
      if ( num_bins_below_thresh == 0 ) ## avoid division by 0 warnings
        oLGX.H1(curr_step) = params_init.oLGXmax;
      else
        oLGX.H1(curr_step) = max(params_init.oLGXmin, num_outliers.H1(curr_step)/num_bins_below_thresh);
        oLGX.H1(curr_step) = min(oLGX.H1(curr_step), params_init.oLGXmax);
      endif

      ## same for L1
      num_bins_below_thresh = (freqbins.L1(curr_step)-num_outliers.L1(curr_step));
      if ( num_bins_below_thresh == 0 )
        oLGX.L1(curr_step) = params_init.oLGXmax;
      else
        oLGX.L1(curr_step) = max(params_init.oLGXmin, num_outliers.L1(curr_step)/num_bins_below_thresh);
        oLGX.L1(curr_step) = min(oLGX.L1(curr_step), params_init.oLGXmax);
      endif

    endif ## valid_band

  endwhile ## main loop over freqbands

  ## needed to ignore last entry in outmatrix if last band failed outside params_run.FreqMax
  num_steps_done = curr_step;
  if ( !valid_band )
    num_steps_done--;
  endif

  ## save outliers to file as an ascii matrix with custom header
  write_results_to_file (params_init.outfile, frequencies, freqbins, num_outliers, max_outlier, oLGX, num_steps_done, curr_step, params_run.FreqMax );

  ## if we created a temporary working directory, remove it again
  if ( params_init.cleanup && use_temp_working_dir )
    [status, msg, msgid] = rmdir ( params_init.workingdir );
    if ( status != 1 )
      error (["Failed to remove temporary working directory '", params_init.workingdir, "': msg = ", msg, ", msgid = ", msgid, "\n"]);
    endif
  endif

  ret = 1;

endfunction ## TuneAdaptiveLVPriors()

############## AUXILIARY FUNCTIONS #############

function [params_init] = check_input_parameters ( params_init )
  ## [params_init] = check_input_parameters ( params_init )
  ## function to parse argument list into variables and check consistency

  if ( !isdir(params_init.sftdir) )
    error(["Invalid input parameter (sftdir): ", params_init.sftdir, " is not a directory."])
  endif

  if ( params_init.freqmax == 0 )
    params_init.freqmax = params_init.freqmin;
  elseif ( params_init.freqmax < params_init.freqmin )
    error(["Invalid input parameter (freqmax): ", num2str(params_init.freqmax), " is lower than freqmin=", num2str(params_init.freqmin), "."]);
  endif

  if ( exist(params_init.runconfig,"file") !=2 )
    error(["Invalid input parameter (runconfig): '", params_init.runconfig, "' is not an existing file."])
  endif

  if ( !isempty(params_init.lalpath) && !isdir(params_init.lalpath) )
    error(["Invalid input parameter (lalpath): ", params_init.lalpath, " is not a directory."]);
  endif

  if ( params_init.oLGXmax < params_init.oLGXmin )
    error(["Invalid input parameter (oLGXmax): ", num2str(params_init.oLGXmax), " must be >= oLGXmin = ", num2str(params_init.oLGXmin), "."])
  endif

  if ( isempty(params_init.timestampsfiles) )
    params_init.usetimestampsfiles = false;
  else
    params_init.usetimestampsfiles = true;
    splitinstring = strsplit(params_init.timestampsfiles, ",");
    params_init = rmfield(params_init,"timestampsfiles");
    for n=1:1:length(splitinstring)
      params_init.timestampsfiles{n} = splitinstring{n};
      if ( exist(params_init.timestampsfiles{n},"file") != 2 )
        error(["Invalid input parameter (timestampsfiles{", int2str(n), "}): '", params_init.timestampsfiles{n}, "' does not exist."])
      endif
    endfor
    if ( length(params_init.timestampsfiles) != 2 ) ## hardcoded H1 L1 right now, FIXME: generalize to numdetectors
      error(["Invalid input parameter (timestampsfiles): need exactly 2 comma-separated files for H1, L1."])
    endif
  endif

endfunction ## check_input_parameters()

function params_run = get_params_run ( runconfigfile )
  ## params_run = get_params_run ( runconfigfile )
  ## get EatH run parameters from a config file and check that all required fields were provided

  source ( runconfigfile );
  if ( !exist("params_run","var") )
    error(["Input runconfig='", runconfigfile, "' does not provide a structure 'params_run'."]);
  endif

  required_fieldnames = {"sft_dfreq", "DataFileBand", "dopplerFactor" ,"Dterms", "offsetFreqIndex", "Tspan", "DataFreqMin", "DataFreqMax", "FreqBand", "RngMedWindow"};

  for n = 1:1:length(required_fieldnames)
    if ( !isfield(params_run,required_fieldnames{n}) )
      error(["Input runconfig='", runconfigfile, "' does not provide required field 'params_run.", required_fieldnames{n}, "'."]);
    endif
  endfor

  ## common derived quantities for all runs
  params_run.f1dot         = - params_run.DataFreqMin / params_run.tauNSmin; ## include sightly positive 'spindowns' too
  params_run.f1dotBand     = 1.1 * abs( params_run.f1dot ); ## search from [-FreqMin/tau, 0.1 * FreqMin/tau]
  params_run.f1dotSideband = getf1dotSidebands ( params_run.f1dot, params_run.f1dotBand, params_run.Tspan );
  params_run.GCSideband    = 2.0 * abs(params_run.df1dot/2.0) * params_run.Tspan/2.0;
  ## account for SFT-sidebands
  params_run.FreqMin       = params_run.DataFreqMin + 1.01 * getSidebandAtFreq ( params_run.DataFreqMin, params_run, use_rngmedSideband=true );
  params_run.FreqMax       = params_run.DataFreqMax - getSidebandAtFreq ( params_run.DataFreqMax, params_run, use_rngmedSideband=true ) - params_run.sft_dfreq;

endfunction ## get_params_run()

function sideBand = getSidebandAtFreq ( Freq, params_run, use_rngmedSideband )
  ## sideBand = getSidebandAtFreq ( Freq, params_run, use_rngmedSideband )
  ## based on CFS_S6LV1_setup.C from EatH project-daemons

  ## get extra-band required to account for frequency-drifting due to f1dot-range
  FreqMax = Freq + params_run.f1dotSideband;

  dopplerSideband = params_run.dopplerFactor * FreqMax;
  GCSideband      = 0.5 * params_run.GCSideband; ## GCTSideband referes to both sides of frequency-interval

  sideBand = dopplerSideband + params_run.f1dotSideband + GCSideband; ## HS-app SUMS them, not max(,)!!
  if ( use_rngmedSideband )
    rngmedSideband  =  fix(params_run.RngMedWindow/2 + 1) * params_run.sft_dfreq; ## "fix" needed because original C code does integer summation and only afterwards casts the bracket to float
    sideBand += rngmedSideband;
  endif

endfunction ## getSidebandAtFreq()

function deltaFreqMax = getf1dotSidebands ( f1dot, f1dotBand, Tspan )
  ## deltaFreqMax = getf1dotSidebands ( f1dot, f1dotBand, Tspan )
  ## based on CFS_S6LV1_setup.C from EatH project-daemons

  deltaT   = 0.5 * Tspan; ## refTime = mid-point of observation-span
  f1dotMin = min ( f1dot, f1dot + f1dotBand );
  f1dotMax = max ( f1dot, f1dot + f1dotBand );

  dFreq1 = abs ( f1dotMin * deltaT );
  dFreq2 = abs ( f1dotMax * deltaT );

  deltaFreqMax = max ( dFreq1, dFreq2 ); ## maximal frequency-shift forward or backward from mid-time = reftime

endfunction ## getf1dotSidebands()

function [iFreq0, iFreq1] = get_iFreqRange4DataFile ( f0, params_run )
  ## [iFreq0, iFreq1] = get_iFreqRange4DataFile ( f0, params_run )
  ## based on CFS_S6LV1_setup.C from EatH project-daemons
  ## Find the interval of Freq-indices [iFreq0, iFreq1) corresponding to the data-file
  ## with start-frequency 'f0'. The total number of physical search frequency-bands
  ## needing this as the lowest-frequency data-file is: nFreqBands = iFreq1 - iFreq0
  ##
  ## NOTE: iFreq0 == iFreq1 == -1 means there are no physical FreqBands 'starting' in this data file

  global SMALL_EPS;

  ## lowest physical search frequency needing this as the lowest data-files
  f0Eff = f0 + getSidebandAtFreq ( f0, params_run, use_rngmedSideband=true );

  ## lowest physical search frequency using the *next one* as the lowest data-file
  f1 = f0 + params_run.DataFileBand; ## first bin in next-highest datafile
  f1Eff = f1 + getSidebandAtFreq ( f1, params_run, use_rngmedSideband=true );

  if ( f0Eff >= params_run.FreqMax )
    iFreq0 = iFreq1 = -1; ## no work in this file
  endif
  if ( f1Eff > params_run.FreqMax )
    f1Eff = params_run.FreqMax;
  endif

  i0 = ceil ( ( f0Eff - params_run.FreqMin ) / params_run.FreqBand - SMALL_EPS ); ## first index of *this* data-file
  i1 = ceil  ( ( f1Eff - params_run.FreqMin ) / params_run.FreqBand - SMALL_EPS ); ## first index of *next* data-file
  iMax = floor ( (params_run.FreqMax - params_run.FreqMin) / params_run.FreqBand + SMALL_EPS );

  iFreq0 = min ( i0, iMax );
  iFreq1 = min ( i1, iMax );

  if ( i1 <= i0 ) ## no physical Freq-indicies starting in this data-file
    iFreq0 = iFreq1 = -1;
  endif

endfunction ## get_iFreqRange4DataFile()

function [valid_band, frequencies, offset, iFreq0_old] = get_freq_ranges ( frequencies, params_init, params_run, offset, iFreq0_old, curr_step );
  ## [valid_band, frequencies, offset, iFreq0_old] = get_freq_ranges ( frequencies, params_init, params_run, offset, iFreq0_old, curr_step )
  ## function to compute the nominal WU frequency, the physical search frequency and SFT read-in start frequency and band

  frequencies.wu_start(curr_step) = params_init.freqmin+(curr_step-1-offset)*params_init.freqstep;
  frequencies.psd_band(curr_step) = params_init.freqstep;

  ## get the frequency index of the first WU input SFT file
  [iFreq0, iFreq1] = get_iFreqRange4DataFile ( frequencies.wu_start(curr_step), params_run );
  if ( iFreq0 < 0 ) ## this means we are outside params_run.FreqMax
    valid_band = false;
    frequencies.search_start(curr_step) = frequencies.wu_start(curr_step) + getSidebandAtFreq ( frequencies.wu_start(curr_step), params_run, use_rngmedSideband=true ); ## needed for commandline output
    frequencies.psd_start(curr_step)    = 0; ## irrelevant from here on
  else
    valid_band = true;

    if ( curr_step > 1 )
      iFreq0diff = iFreq0 - iFreq0_old;
      if ( iFreq0diff >= 2 )
        freq_wu_start_corr = params_init.freqmin+(curr_step-offset-iFreq0diff)*params_init.freqstep;
        printf("At WU freq %f Hz, jump in physical searchfreq detected due to additional SFT required. Correcting by inserting additional line with previous WUfreq=%f Hz and corresponding searchfreq.\n", frequencies.wu_start(curr_step), freq_wu_start_corr);
        offset++;
        frequencies.wu_start(curr_step) = freq_wu_start_corr;
        iFreq0--;
      endif
    endif
    iFreq0_old = iFreq0;

    ## get the start of the physical search band
    frequencies.search_start(curr_step) = params_run.FreqMin + 1.0 * ( iFreq0 + params_run.offsetFreqIndex ) * params_run.FreqBand;

    ## get back down to start of contributing frequencies, including Doppler and spindown, but not running median bins
    sideBand1  = getSidebandAtFreq ( frequencies.search_start(curr_step), params_run, use_rngmedSideband=false );
    frequencies.psd_start(curr_step)    = frequencies.search_start(curr_step) - sideBand1; ## we do not round this to an exact bin, as ComputePSD already reads in from the next-lowest bin frequency

    ## do the same at upper end
    sideBand2  = getSidebandAtFreq ( frequencies.search_start(curr_step)+params_init.freqstep, params_run, use_rngmedSideband=false );
    frequencies.psd_band(curr_step)    += sideBand1 + sideBand2; ## we do not round this to exact bins, as ComputePSD already reads in up to and including the next-highest bin frequency

    ## add Dterms correction to actually match GCT code data read-in (not present in CFS_*_setup.C)
    frequencies.psd_start(curr_step)   -= params_run.Dterms*params_run.sft_dfreq;
    frequencies.psd_band(curr_step)    += 2.0*params_run.Dterms*params_run.sft_dfreq;

  endif ## iFreq0 < 0

endfunction ## get_freq_ranges()

function [sftstartfreq, num_sfts_to_load, rngmedbins_effective] = get_sft_range ( params_init, params_run, startfreq, freqband )
  ## [sftstartfreq, num_sfts_to_load, rngmedbins_effective] = get_sft_range ( params_init, params_run, startfreq, freqband )
  ## function to compute the necessary SFT start frequency and the number of (contiguous) SFTs starting from there

  sftstartfreq = floor(20*startfreq)/20; ## round down to get SFT file containing the startfreq
  num_sfts_to_load = ceil ( freqband / params_init.sft_width );
  rngmed_wing_normal = fix(params_init.rngmedbins/2 + 1) * params_run.sft_dfreq;

  ## if Dterms/rngmedbins overlap leads to problems at boundaries, fix by omitting a few bins from the rngmed for that one band
  if ( startfreq - rngmed_wing_normal < params_run.DataFreqMin )
    rngmedbins_effective = params_init.rngmedbins - 2.0*params_run.Dterms;
    rngmed_wing = fix(rngmedbins_effective/2 + 1) * params_run.sft_dfreq;
    printf("NOTE: combined rngmedbins=%d and Dterms=%d would require data from below FreqMin=%f, so reduced effective rngmed to %d bins for this band only.\n", params_init.rngmedbins, params_run.Dterms, params_run.DataFreqMin, rngmedbins_effective);
  elseif ( startfreq + freqband + rngmed_wing_normal > params_run.DataFreqMax )
    rngmedbins_effective = params_init.rngmedbins - 2.0*params_run.Dterms;
    rngmed_wing = fix(rngmedbins_effective + 1) * params_run.sft_dfreq;
    printf("NOTE: combined rngmedbins=%d and Dterms=%d would require data from above FreqMax=%f, so reduced effective rngmed to %d bins for this band only.\n", params_init.rngmedbins, params_run.Dterms, params_run.DataFreqMax, rngmedbins_effective);
  else
    rngmedbins_effective = params_init.rngmedbins;
    rngmed_wing = rngmed_wing_normal;
  endif

  ## load more SFTs if below the lower boundary
  while ( startfreq - rngmed_wing < sftstartfreq + params_run.sft_dfreq )
    if ( sftstartfreq - params_init.sft_width >= params_run.DataFreqMin )
      sftstartfreq -= params_init.sft_width;
      num_sfts_to_load++;
    else
      printf("NOTE: Required data start frequency %f Hz is closer to DataFreqMin=%f Hz than one SFT bin (%f Hz), cannot add more SFTs below. Next call to lalapps_ComputePSD might fail.\n", startfreq-rngmed_wing, params_run.DataFreqMin, params_run.sft_dfreq);
      break;
    endif
  endwhile

  ## load more SFTs if above the upper boundary
  while ( startfreq + freqband + rngmed_wing >= sftstartfreq + num_sfts_to_load*params_init.sft_width - params_run.sft_dfreq )
    if ( sftstartfreq + num_sfts_to_load*params_init.sft_width <= params_run.DataFreqMax )
      num_sfts_to_load++;
    else
      printf("NOTE: Required data end frequency %f Hz is closer to DataFreqMax=%f Hz than one SFT bin (%f Hz), cannot add more SFTs above. Next call to lalapps_ComputePSD might fail.\n", startfreq+freqband+rngmed_wing, params_run.DataFreqMax, params_run.sft_dfreq);
      break;
    endif
  endwhile

endfunction ## get_sft_range()

function write_results_to_file (outfile, frequencies, freqbins, num_outliers, max_outlier, oLGX, num_steps_done, curr_step, FreqMax )
  ## write_results_to_file (outfile, frequencies, freqbins, num_outliers, max_outlier, oLGX, num_steps_done, curr_step, FreqMax )
  ## save outliers to file as an ascii matrix with custom header

  ## header (commandline has already been written into this file)
  fid = fopen ( outfile, "a" ); ## append mode
  fprintf ( fid, "# \n# columns:\n" );
  columnlabels = {"wufreq", "searchfreq", "psd_startfreq", "psd_freqband", "freqbins_H1", "freqbins_L1", "num_outliers_H1", "num_outliers_L1", "max_outlier_H1", "max_outlier_L1", "oLG^H1", "oLG^L1"};
  majordigits = 4*ones(length(columnlabels),1); ## assume only frequencies, bin numbers, power values etc up to 9999
  minordigits = [2,10,10,10,0,0,0,0,6,6,6,6]; ## these must be the same as the ".2f" and similar in the body formatstring
  formatstring = "#"; ## comment marker for beginning of line
  for n = 1:1:length(columnlabels) ## pad headings if numbers will be wider
    formatstring = [formatstring, " %%%ds"];
    if ( minordigits(n) == 0 )
      decimaldot = 0;
    else
      decimaldot = 1;
    endif
    columnwidths(n) = max(length(columnlabels{n}),majordigits(n)+decimaldot+minordigits(n));
  endfor
  formatstring = sprintf([formatstring, "\n"], columnwidths);
  fprintf ( fid, formatstring, columnlabels{:} );

  ## body
  if ( isempty(oLGX.H1) ) ## if first band is already outside params_run.FreqMax, skip output
    skip_output = true;
  else
    skip_output = false;
    columnwidths(1) += 2; ## now need to pad for leading "# " in heading also
    formatstring = sprintf("%%%d.2f %%%d.10f %%%d.10f %%%d.10f %%%dd %%%dd %%%dd %%%dd %%%d.6f %%%d.6f %%%d.6f %%%d.6f\n", columnwidths); ## pad to standard with; ".2f" and similar must be same numbers of minor digits as above
    for n=1:1:num_steps_done
      fprintf ( fid, formatstring, frequencies.wu_start(n),frequencies.search_start(n),frequencies.psd_start(n),frequencies.psd_band(n),freqbins.H1(n),freqbins.L1(n),num_outliers.H1(n),num_outliers.L1(n),max_outlier.H1(n),max_outlier.L1(n),oLGX.H1(n),oLGX.L1(n) );
    endfor
  endif
  if ( skip_output || ( num_steps_done < curr_step ) ) ## if no output at all or skipped some bands at end of freq range, note so in the file
    fprintf ( fid, "# params_run.FreqMax=%.10f reached, no more bands processed.\n", FreqMax );
  endif

  ## done
  fclose ( outfile );

endfunction ## write_results_to_file()

%!test disp("no test exists for this function as it requires access to data not included in OctApps")
