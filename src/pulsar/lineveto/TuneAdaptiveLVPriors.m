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


function ret = TuneAdaptiveLVPriors ( varargin )
 ## ret = TuneAdaptiveLVPriors ( varargin )
 ## function to count outliers in SFT power statistic over a large set of frequency bands (input sft files) and derive LV priors from that
 ## command-line parameters can be taken from parseOptions call below
 ## example call: octapps_run TuneAdaptiveLVPriors --sftdir=sfts --sft_filenamebit=S5R2 --freqmin=50 --freqmax=50.5 --freqband=0.05

 # read in and check input parameters
 params_init = parseOptions(varargin,
                     {"sftdir", "char"},
                     {"sft_filenamebit", "char", ""},
                     {"freqmin", "numeric,scalar"},
                     {"freqmax", "numeric,scalar", 0}, # default: set to freqmin
                     {"freqstep", "numeric,scalar", 0.05},
                     {"runname", "char"},
                     {"debug", "numeric,scalar", 0},
                     {"cleanup", "numeric,scalar", 1},
                     {"workingdir", "char", "."},
                     {"lalpath", "char", ""},
                     {"outfile", "char", "power_outliers.dat"},
                     {"rngmedbins", "numeric,scalar", 101},
                     {"thresh", "numeric,scalar", 1.25},
                     {"LVlmin", "numeric,scalar", 0.001},
                     {"LVlmax", "numeric,scalar", 1000},
                     {"sftwidth", "numeric,scalar", 0.05},
                     {"Tsft", "numeric,scalar", 1800}
                );
 params_init = check_input_parameters ( params_init );

 format long;

 if ( params_init.debug == 1 )
  printf("Running from directory '%s'. LAL path is '%s'. Local octave version is '%s'. Input parameters are:\n", pwd, params_init.lalpath, version);
  params_init
 endif

 global SMALL_EPS = 1.0e-6;

 # prepare PSD parameters
 params_psd.PSDmthopSFTs = 1;
 params_psd.PSDmthopIFOs = 8;

 # count necessary freqbands and sfts
 # NOTE: rounded down, freqmax may not be reached if freqmax-freqmin is not an integer multiple of freqstep
 num_freqsteps = 1 + floor ( ( params_init.freqmax - params_init.freqmin ) / params_init.freqstep + SMALL_EPS );

 sft_dfreq = 1.0/params_init.Tsft;
 hours = 3600;
 days  = 24 * hours;
 years = 365 * days;
 params_run.TSFT          = params_init.Tsft;
 params_run.DataFileBand  = 0.05;
 params_run.dopplerFactor = 1.05e-4; # max relative doppler-shift
 params_run.Dterms        = 8;
 params_run.offsetFreqIndex = 0; # this was only necessary when WUs were split in freq
 if ( strcmp(params_init.runname,"S5R3") == 1 ) # prepare for freqband computations, based on CFS_S5R3_setup.C from EatH project-daemons
  params_run.mismatchSpin  = 0.3; # called just "mismatch" in CFS_S5R3_setup.C
  params_run.Tstack        = 25.0 * hours;
  params_run.Tspan         = 381.0 *days; # total time-spanned by data
  params_run.DataFreqMin   = 50.0;
  params_run.DataFreqMax   = 1200.0;
  params_run.FreqBand      = 0.05; # originally in CFS_S5R3_setup.C: pars0.FreqBand = pars0.HoughSideband * pars0.tauF / ( pars0.tauF + pars0.tauH ) * ( 1.0 - eps ) / eps;
  params_run.tauNSmin      = 1000.0 * years;
  params_run.RngMedWindow  = 101; # app-default
  params_run.df1dot        = sqrt ( 33.0 * params_run.mismatchSpin) / ( pi * params_run.Tstack^2 ); # higher f1dot-resolution than predicted by the metric, because nf1dotRes=1
 elseif ( strcmp(params_init.runname,"S6bucket") == 1 ) # prepare for freqband computations, based on CFS_S6LV1_setup.C from EatH project-daemons
  params_run.mismatchSpin  = 0.1; # 'spin' mismatch (in f,fdot)
  params_run.Tstack        = 60.0 * hours;
  params_run.Tspan         = 255.32 *days; # total time-spanned by data
  params_run.DataFreqMin   = 50.0;
  params_run.DataFreqMax   = 450.0;
  params_run.FreqBand      = 0.05; # Hz; yields about ~12% overheads
  params_run.tauNSmin      = 600.0 * years;
  params_run.RngMedWindow  = 101; # app-default
  params_run.df1dot        = sqrt ( 720.0 * params_run.mismatchSpin ) / ( pi * params_run.Tstack^2 );
  params_run.dFreq         = sqrt ( 12.0 * params_run.mismatchSpin ) / ( pi * params_run.Tstack );
 endif
 params_run.f1dot         = - params_run.DataFreqMin / params_run.tauNSmin; # include sightly positive 'spindowns' too
 params_run.f1dotBand     = 1.1 * abs( params_run.f1dot ); # search from [-FreqMin/tau, 0.1 * FreqMin/tau]
 params_run.f1dotSideband = getf1dotSidebands ( params_run.f1dot, params_run.f1dotBand, params_run.Tspan );
 params_run.GCSideband    = 2.0 * abs(params_run.df1dot/2.0) * params_run.Tspan/2.0;
 # account for SFT-sidebands
 params_run.FreqMin       = params_run.DataFreqMin + 1.01 * getSidebandAtFreq ( params_run.DataFreqMin, params_run, use_rngmedSideband=1 );
 params_run.FreqMax       = params_run.DataFreqMax - getSidebandAtFreq ( params_run.DataFreqMax, params_run, use_rngmedSideband=1 ) - 1.0/params_init.Tsft;

 band   = 0;
 iFreq0 = 0;
 while ( ( band < num_freqsteps ) && ( iFreq0 >= 0 ) ) # main loop over freqbands - break when params_run.FreqMax reached
  band++;

  wufreq(band)     = params_init.freqmin+(band-1)*params_init.freqstep;
  freqband(band)  = params_init.freqstep;

  # get the frequency index of the first WU input SFT file
  [iFreq0, iFreq1] = get_iFreqRange4DataFile ( wufreq(band), params_run );
  if ( iFreq0 < 0 ) # this means we are outside params_run.FreqMax
   searchfreq(band) = wufreq(band) + getSidebandAtFreq ( wufreq(band), params_run, use_rngmedSideband=1 );
   printf("Frequency band %d, WU freq %f Hz, physical search startfreq %f Hz would lie outside params_run.FreqMax=%f, skipping...\n", band, wufreq(band), searchfreq(band), params_run.FreqMax);  
  else
   # get the start of the physical search band
   searchfreq(band) = params_run.FreqMin + 1.0 * ( iFreq0 + params_run.offsetFreqIndex ) * params_run.FreqBand;
   # get back down to start of contributing frequencies, including Doppler and spindown, but not running median bins
   sideBand1        = getSidebandAtFreq ( searchfreq(band), params_run, use_rngmedSideband=0 );
   startfreq(band)  = searchfreq(band) - sideBand1;
   startfreq(band)  -= mod(startfreq(band),sft_dfreq); # round down to next sft bin
   # do the same at upper end
   sideBand2        = getSidebandAtFreq ( searchfreq(band)+params_init.freqstep, params_run, use_rngmedSideband=0 );
   freqband(band)  += sideBand1 + sideBand2;
   freqband(band)  += -mod(startfreq(band),sft_dfreq)+sft_dfreq; # round up to next sft bin
   # add Dterms correction to actually match GCT code data read-in (not present in CFS_*_setup.C)
   startfreq(band) -= params_run.Dterms*sft_dfreq;
   freqband(band)  += 2.0*params_run.Dterms*sft_dfreq;
   printf("Frequency band %d, WU freq %f Hz, physical search startfreq %f Hz , width %f Hz: processing band from %f Hz with width %f Hz...\n", band, wufreq(band), searchfreq(band), params_init.freqstep, startfreq(band), freqband(band));

   # get the correct set of sfts, checking for running median window
   sftstartfreq = floor(20*startfreq(band))/20; # round down to get SFT file containing the startfreq
   num_sfts_to_load = ceil ( freqband(band) / params_init.sftwidth );
   rngmed_wing_normal = fix(params_init.rngmedbins/2 + 1) / params_init.Tsft;
   # if Dterms/rngmedbins overlap leads to problems at boundaries, fix by omitting a few bins from the rngmed for that one band
   if ( startfreq(band) - rngmed_wing_normal < params_run.DataFreqMin )
    rngmedbins_effective = params_init.rngmedbins - 2.0*params_run.Dterms;
    rngmed_wing = fix(rngmedbins_effective/2 + 1) / params_init.Tsft;
    printf("NOTE: combined rngmedbins=%d and Dterms=%d would require data from below FreqMin=%f, so reduced effective rngmed to %d bins for this band only.\n", params_init.rngmedbins, params_run.Dterms, params_run.DataFreqMin, rngmedbins_effective);
   elseif ( startfreq(band) + freqband(band) + rngmed_wing_normal > params_run.DataFreqMax )
    rngmedbins_effective = params_init.rngmedbins - 2.0*params_run.Dterms;
    rngmed_wing = fix(rngmedbins_effective + 1) / params_init.Tsft;
    printf("NOTE: combined rngmedbins=%d and Dterms=%d would require data from above FreqMax=%f, so reduced effective rngmed to %d bins for this band only.\n", params_init.rngmedbins, params_run.Dterms, params_run.DataFreqMax, rngmedbins_effective);
   else
    rngmedbins_effective = params_init.rngmedbins;
    rngmed_wing = rngmed_wing_normal;
   endif
   while ( startfreq(band) - rngmed_wing < sftstartfreq ) # load another SFT if below the lower boundary
    sftstartfreq -= params_init.sftwidth;
    num_sfts_to_load++;
   endwhile
   while ( startfreq(band) + freqband(band) + rngmed_wing > sftstartfreq + num_sfts_to_load*params_init.sftwidth ) # load another SFT if above the upper boundary
    num_sfts_to_load++;
   endwhile

   # load in all required sfts
   sfts.h1 = [];
   sfts.l1 = [];
   for numsft = 1:1:num_sfts_to_load
    currfreqstring = convert_freq_to_string(sftstartfreq + (numsft-1)*params_init.sftwidth,4,2);
    sftfile = [params_init.sftdir, filesep, "h1_", currfreqstring, params_init.sft_filenamebit];
    if ( exist(sftfile,"file") != 2 )
     freqsubdir = convert_freq_to_string(10*floor((sftstartfreq + (numsft-1)*params_init.sftwidth)/10+SMALL_EPS),4,0); # EatH SFTs on atlas are organized in 0fff subdirs - SMALL_EPS is to make sure 60.000 gets floored to 60 and not 50, as octave can have small numerical inaccuracies here
     sftfile = [params_init.sftdir, filesep, freqsubdir, filesep, "h1_", currfreqstring, params_init.sft_filenamebit];
     if ( exist(sftfile,"file") != 2 )
      error(["Required SFT file ", sftfile, " does not exist."]);
     endif
    endif
    sfts.h1 = [sfts.h1, sftfile];
    sftfile = [params_init.sftdir, filesep, "l1_", currfreqstring, params_init.sft_filenamebit];
    if ( exist(sftfile,"file") != 2 )
     sftfile = [params_init.sftdir, filesep, freqsubdir, filesep, "l1_", currfreqstring, params_init.sft_filenamebit];
     if ( exist(sftfile,"file") != 2 )
      error(["Required SFT file ", sftfile, " does not exist."]);
     endif
    endif
    sfts.l1 = [sfts.l1, sftfile];
    if ( numsft < num_sfts_to_load )
     sfts.h1 = [sfts.h1, ";"];
     sfts.l1 = [sfts.l1, ";"];
    endif
   endfor

   # count the outliers in the power statistic
   params_psd.FreqBand   = freqband(band);
   params_psd.Freq       = startfreq(band);
   params_psd.blocksRngMed = rngmedbins_effective;
   params_psd.inputData = sfts.h1;
   params_psd.outputPSD = [params_init.workingdir, filesep, "psd_H1_med_", num2str(params_psd.blocksRngMed), "_band_", int2str(band), ".dat"];
   [num_outliers_H1(band), max_outlier_H1(band), freqbins_H1(band)] = CountSFTPowerOutliers ( params_psd, params_init.thresh, params_init.lalpath, params_init.debug );
   if ( params_init.cleanup == 1 )
    [err, msg] = unlink (params_psd.outputPSD);
   endif
   params_psd.inputData = sfts.l1;
   params_psd.outputPSD = [params_init.workingdir, filesep, "psd_L1_med_", num2str(params_psd.blocksRngMed), "_band_", int2str(band), ".dat"];
   [num_outliers_L1(band), max_outlier_L1(band), freqbins_L1(band)] = CountSFTPowerOutliers ( params_psd, params_init.thresh, params_init.lalpath, params_init.debug );
   if ( params_init.cleanup == 1 )
    [err, msg] = unlink (params_psd.outputPSD);
   endif

   # compute the line priors
   l_H1(band) = max(params_init.LVlmin, num_outliers_H1(band)/(freqbins_H1(band)-num_outliers_H1(band)));
   l_H1(band) = min(l_H1(band), params_init.LVlmax);
   l_L1(band) = max(params_init.LVlmin, num_outliers_L1(band)/(freqbins_L1(band)-num_outliers_L1(band)));
   l_H1(band) = min(l_H1(band), params_init.LVlmax);

  endif # iFreq0 >= 0 

 endwhile

 # needed to ignore last entry in outmatrix if last band failed outside params_run.FreqMax
 num_done_bands = band;
 if ( iFreq0 < 0 )
  num_done_bands--;
 endif

 # save outliers to file as an ascii matrix with custom header
 fid = fopen ( params_init.outfile, "w" );
 fprintf ( fid, "%%%% produced from TuneAdaptiveLVPriors() with the following options:\n" );
 params_init_fieldnames = fieldnames(params_init);
 params_init_values     = struct2cell(params_init);
 for n=1:1:length(params_init_values)
  if ( isnumeric(params_init_values{n}) )
   params_init_values{n} = num2str(params_init_values{n});
  endif
  fprintf ( fid, "%%%% --%s=%s \n", params_init_fieldnames{n}, params_init_values{n} );
 endfor
 fprintf ( fid, "%%%% \n%%%% columns:\n" );
 fprintf ( fid, "%%%% wufreq searchfreq startfreq freqband freqbins_H1 freqbins_L1 num_outliers_H1 num_outliers_L1 max_outlier_H1 max_outlier_L1 l_H1 l_L1\n" )
 if ( exist("l_H1","var") == 1 ) # if first band is already outside params_run.FreqMax, this would not be valid -> skip output
  outmatrix = cat(1,wufreq(1:num_done_bands),searchfreq(1:num_done_bands),startfreq(1:num_done_bands),freqband(1:num_done_bands),freqbins_H1(1:num_done_bands),freqbins_L1(1:num_done_bands),num_outliers_H1(1:num_done_bands),num_outliers_L1(1:num_done_bands),max_outlier_H1(1:num_done_bands),max_outlier_L1(1:num_done_bands),l_H1(1:num_done_bands),l_L1(1:num_done_bands));
  fprintf ( fid, "%.2f %.10f %.10f %.10f %d %d %d %d %.6f %.6f %.6f %.6f\n", outmatrix );
 endif
 if ( ( exist("l_H1","var") != 1 ) || ( num_done_bands < band ) )
  fprintf ( fid, "%%%% params_run.FreqMax reached, no more bands processed.\n" );
 endif
 fclose ( params_init.outfile );

 ret = 1;

endfunction # TuneAdaptiveLVPriors()

############## AUXILIARY FUNCTIONS #############

function [params_init] = check_input_parameters ( params_init )
 ## [params_init] = check_input_parameters ( params_init )
 ## function to parse argument list into variables and check consistency

 if ( !isdir(params_init.sftdir) )
  error(["Invalid input parameter (sftdir): ", params_init.sftdir, " is not a directory."])
 endif

 if ( params_init.freqmin < 0.0 )
  error(["Invalid input parameter (freqmin): ", num2str(params_init.freqmin), " must be >= 0."]);
 endif

 if ( params_init.freqmax == 0 )
  params_init.freqmax = params_init.freqmin;
 elseif ( params_init.freqmax < params_init.freqmin )
  error(["Invalid input parameter (freqmax): ", num2str(params_init.freqmax), " is lower than freqmin=", num2str(params_init.freqmin), "."]);
 endif

 if ( params_init.freqstep <= 0.0 )
  error(["Invalid input parameter (freqstep): ", num2str(params_init.freqstep), " must be > 0."]);
 endif

 if ( ( strcmp(params_init.runname,"S5R3") != 1 ) && ( strcmp(params_init.runname,"S6bucket") != 1 ) )
  error(["Invalid input parameter (runname): ", params_init.runname, " is not supported, currently supported are: 'S5R3', 'S6bucket'"]);
 endif

 if ( ( params_init.debug != 0 ) && ( params_init.debug != 1 ) )
  error(["Invalid input parameter (debug): ", int2str(params_init.debug), " is neither 0 or 1."])
 endif

 if ( ( params_init.cleanup != 0 ) && ( params_init.cleanup != 1 ) )
  error(["Invalid input parameter (cleanup): ", int2str(params_init.cleanup), " is neither 0 or 1."])
 endif

 if ( !isdir(params_init.workingdir) )
  error(["Invalid input parameter (workingdir): ", params_init.workingdir, " is not a directory."])
 endif

 if ( ( length(params_init.lalpath) > 0 ) && ( !isdir(params_init.lalpath) ) )
  error(["Invalid input parameter (lalpath): ", params_init.lalpath, " is not a directory."]);
 endif

 if ( params_init.rngmedbins < 0 )
   error(["Invalid input parameter (rngmedbins): ", num2str(params_init.rngmedbins), " must be >= 0."])
 endif

 if ( params_init.thresh < 1 )
   error(["Invalid input parameter (thresh): ", num2str(params_init.thresh), " must be >= 1."])
 endif

 if ( params_init.LVlmin < 0 )
   error(["Invalid input parameter (LVlmin): ", num2str(params_init.LVlmin), " must be >= 0."])
 endif

 if ( params_init.LVlmax < params_init.LVlmin )
   error(["Invalid input parameter (LVlmax): ", num2str(params_init.LVlmax), " must be >= LVlmin = ", num2str(params_init.LVlmin), "."])
 endif

 if ( params_init.sftwidth <= 0.0 )
  error(["Invalid input parameter (sftwidth): ", num2str(params_init.sftwidth), " must be > 0."]);
 endif

 if ( params_init.Tsft <= 0.0 )
  error(["Invalid input parameter (Tsft): ", num2str(params_init.Tsft), " must be > 0."]);
 endif

endfunction # check_input_parameters()


function [freqstring] = convert_freq_to_string ( freq, leading, trailing )
 ## [freqstring] = convert_freq_to_string ( freq, leading, trailing )
 ## function to convert a frequency value to a string with leading 0s
 freqstring_init = num2str(freq);
 freqstring_split = strsplit(freqstring_init,".");
 if ( length(freqstring_split{1}) > leading ) # too many digits before '.'
  error(["Error converting frequency ", num2str(freq), " into string ", freqstring_init, ": more leading digits than requested (", int2str(leading), ") - do not want to truncate this."]);
 endif
 freqstring = freqstring_split{1};
 if ( trailing > 0 )
  freqstring = [freqstring, "."];
  if ( length(freqstring_split) >= 2 )
   freqstring = [freqstring, freqstring_split{2}(1:min(length(freqstring_split{2}),trailing))];
   digits = length(freqstring_split{2});
  else
   digits = 0;
  endif
  for ( n = 1:1:trailing-digits )
   freqstring = [freqstring, "0"];
  endfor
 endif
 for ( n = 1:1:leading-length(freqstring_split{1}) )
  freqstring = ["0", freqstring];
 endfor
endfunction # convert_freq_to_string()


function sideBand = getSidebandAtFreq ( Freq, params_run, use_rngmedSideband )
 ## sideBand = getSidebandAtFreq ( Freq, params_run, use_rngmedSideband )
 ## based on CFS_S6LV1_setup.C from EatH project-daemons

  # get extra-band required to account for frequency-drifting due to f1dot-range
  FreqMax = Freq + params_run.f1dotSideband;

  dopplerSideband = params_run.dopplerFactor * FreqMax;
  GCSideband      = 0.5 * params_run.GCSideband; # GCTSideband referes to both sides of frequency-interval

  sideBand = dopplerSideband + params_run.f1dotSideband + GCSideband; # HS-app SUMS them, not max(,)!!
  if ( use_rngmedSideband == 1 )
   rngmedSideband  =  fix(params_run.RngMedWindow/2 + 1) / params_run.TSFT; # "fix" needed because original C code does integer summation and only afterwards casts the bracket to float
   sideBand += rngmedSideband;
  endif

endfunction # getSidebandAtFreq()


function deltaFreqMax = getf1dotSidebands ( f1dot, f1dotBand, Tspan )
 ## deltaFreqMax = getf1dotSidebands ( f1dot, f1dotBand, Tspan )
 ## based on CFS_S6LV1_setup.C from EatH project-daemons

  deltaT   = 0.5 * Tspan; # refTime = mid-point of observation-span
  f1dotMin = min ( f1dot, f1dot + f1dotBand );
  f1dotMax = max ( f1dot, f1dot + f1dotBand );

  dFreq1 = abs ( f1dotMin * deltaT );
  dFreq2 = abs ( f1dotMax * deltaT );

  deltaFreqMax = max ( dFreq1, dFreq2 ); # maximal frequency-shift forward or backward from mid-time = reftime

endfunction # getf1dotSidebands()


function [iFreq0, iFreq1] = get_iFreqRange4DataFile ( f0, params_run )
 ## [iFreq0, iFreq1] = get_iFreqRange4DataFile ( f0, params_run )
 ## based on CFS_S6LV1_setup.C from EatH project-daemons
 ## Find the interval of Freq-indices [iFreq0, iFreq1) corresponding to the data-file
 ## with start-frequency 'f0'. The total number of physical search frequency-bands
 ## needing this as the lowest-frequency data-file is: nFreqBands = iFreq1 - iFreq0
 ##
 ## NOTE: iFreq0 == iFreq1 == -1 means there are no physical FreqBands 'starting' in this data file

 global SMALL_EPS;

 # lowest physical search frequency needing this as the lowest data-files
 f0Eff = f0 + getSidebandAtFreq ( f0, params_run, use_rngmedSideband=1 );

 # lowest physical search frequency using the *next one* as the lowest data-file
 f1 = f0 + params_run.DataFileBand; # first bin in next-highest datafile
 f1Eff = f1 + getSidebandAtFreq ( f1, params_run, use_rngmedSideband=1 );

 if ( f0Eff >= params_run.FreqMax )
  iFreq0 = iFreq1 = -1; # no work in this file
 endif
 if ( f1Eff > params_run.FreqMax )
  f1Eff = params_run.FreqMax;
 endif

 i0 = ceil ( ( f0Eff - params_run.FreqMin ) / params_run.FreqBand - SMALL_EPS ); # first index of *this* data-file
 i1 = ceil  ( ( f1Eff - params_run.FreqMin ) / params_run.FreqBand - SMALL_EPS ); # first index of *next* data-file
 iMax = floor ( (params_run.FreqMax - params_run.FreqMin) / params_run.FreqBand + SMALL_EPS );

 iFreq0 = min ( i0, iMax );
 iFreq1 = min ( i1, iMax );

 if ( i1 <= i0 ) # no physical Freq-indicies starting in this data-file
  iFreq0 = iFreq1 = -1;
 endif

endfunction # get_iFreqRange4DataFile()