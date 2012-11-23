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
                     {"freqmax", "numeric,scalar"},
                     {"freqband", "numeric,scalar"},
                     {"debug", "numeric,scalar", 0},
                     {"cleanup", "numeric,scalar", 1},
                     {"workingdir", "char", "."},
                     {"lalpath", "char", ""},
                     {"outfile", "char", "power_outliers.dat"},
                     {"runmed", "numeric,scalar", 50},
                     {"thresh", "numeric,scalar", 1.25},
                     {"LVlmin", "numeric,scalar", 0.001},
                     {"LVlmax", "numeric,scalar", 1000},
                     {"sftwidth", "numeric,scalar", 0.05}
                );
 params_init = check_input_parameters ( params_init );

 if ( params_init.debug == 1 )
  printf("Running from directory '%s'. LAL path is '%s'. Local octave version is '%s'. Input parameters are:\n", pwd, params_init.lalpath, version);
  params_init
 endif

 # prepare PSD parameters
 params_psd.PSDmthopSFTs = 1;
 params_psd.PSDmthopIFOs = 8;
 params_psd.blocksRngMed = params_init.runmed;
 params_psd.FreqBand     = params_init.freqband;

 # count necessary freqbands and sfts
 # NOTE: rounded down, freqmax may not be reached if freqmax-freqmin is not an integer multiple of freqband
 num_freqbands = floor ( ( params_init.freqmax - params_init.freqmin ) / params_init.freqband );
 if ( num_freqbands <= 0 )
  error(["Requested frequency range too small, corresponds to less than 1 freqband."]);
 endif
 num_sfts_per_freqband = ceil ( params_init.freqband / params_init.sftwidth );

 for band = 1:1:num_freqbands # main loop over freqbands

  startfreq(band) = params_init.freqmin+(band-1)*params_init.freqband;

  printf("Frequency band %d, starting from %f Hz...\n", band, startfreq(band));

  # load in enough sfts, i.e. one extra to the left and right of requested band
  sfts.h1 = [];
  sfts.l1 = [];
  for numsft = 1:1:num_sfts_per_freqband+2
   currfreqstring = convert_freq_to_string(startfreq(band) + (numsft-2)*params_init.sftwidth,4,2);
   sftfile = [params_init.sftdir, filesep, "h1_", currfreqstring, params_init.sft_filenamebit];
   if ( exist(sftfile,"file") != 2 )
    freqsubdir = convert_freq_to_string(10*floor((startfreq(band) + (numsft-2)*params_init.sftwidth)/10+0.001),4,0); # EatH SFTs on atlas are organized in 0fff subdirs - 0.001 is to make sure 60.000 gets floored to 60 and not 50, as octave can have small numerical inaccuracies here
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
   if ( numsft < num_sfts_per_freqband+2 )
    sfts.h1 = [sfts.h1, ";"];
    sfts.l1 = [sfts.l1, ";"];
   endif
  endfor

  # count the outliers in the power statistic
  params_psd.Freq = startfreq(band);
  params_psd.inputData = sfts.h1;
  params_psd.outputPSD = [params_init.workingdir, filesep, "psd_H1_med_", num2str(params_psd.blocksRngMed), "_band_", int2str(band), ".dat"];
  [num_outliers_H1(band), max_outlier_H1(band), freqbins_H1] = CountSFTPowerOutliers ( params_psd, params_init.thresh, params_init.lalpath, params_init.debug );
  if ( params_init.cleanup == 1 )
   [err, msg] = unlink (params_psd.outputPSD);
  endif
  params_psd.inputData = sfts.l1;
  params_psd.outputPSD = [params_init.workingdir, filesep, "psd_L1_med_", num2str(params_psd.blocksRngMed), "_band_", int2str(band), ".dat"];
  [num_outliers_L1(band), max_outlier_L1(band), freqbins_L1] = CountSFTPowerOutliers ( params_psd, params_init.thresh, params_init.lalpath, params_init.debug );
  if ( params_init.cleanup == 1 )
   [err, msg] = unlink (params_psd.outputPSD);
  endif

  # compute the line priors
  l_H1(band) = max(params_init.LVlmin, num_outliers_H1(band)/(freqbins_H1-num_outliers_H1(band)));
  l_H1(band) = min(l_H1(band), params_init.LVlmax);
  l_L1(band) = max(params_init.LVlmin, num_outliers_L1(band)/(freqbins_L1-num_outliers_L1(band)));
  l_H1(band) = min(l_H1(band), params_init.LVlmax);

 endfor # band <= num_band

 # save outliers to file as an ascii matrix with custom header
 outmatrix = cat(1,startfreq,num_outliers_H1,num_outliers_L1,max_outlier_H1,max_outlier_L1,l_H1,l_L1);
 fid = fopen ( params_init.outfile, "w" );
 fprintf ( fid, "%%%% produced from count_power_outliers_many_bands with the following options:\n" );
 params_init_fieldnames = fieldnames(params_init);
 params_init_values     = struct2cell(params_init);
 for n=1:1:length(params_init_values)
  if ( isnumeric(params_init_values{n}) )
   params_init_values{n} = num2str(params_init_values{n});
  endif
  fprintf ( fid, "%%%% --%s=%s \n", params_init_fieldnames{n}, params_init_values{n} );
 endfor
 fprintf ( fid, "%%%% \n%%%% columns:\n" );
 fprintf ( fid, "%%%% startfreq num_outliers_H1 num_outliers_L1 max_outlier_H1 max_outlier_L1 l_H1 l_L1\n" )
 fprintf ( fid, "%f %d %d %f %f %f %f\n", outmatrix );
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

 if ( params_init.freqmax < params_init.freqmin )
  error(["Invalid input parameter (freqmax): ", num2str(params_init.freqmax), " is lower than freqmin=", num2str(params_init.freqmin), "."]);
 endif

 if ( params_init.freqband <= 0.0 )
  error(["Invalid input parameter (freqband): ", num2str(params_init.freqband), " must be > 0."]);
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

 if ( params_init.runmed < 0 )
   error(["Invalid input parameter (runmed): ", num2str(params_init.runmed), " must be >= 0."])
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
