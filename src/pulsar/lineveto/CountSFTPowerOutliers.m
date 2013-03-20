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

function [num_outliers, max_outlier, freqbins] = CountSFTPowerOutliers ( params_psd, thresh, lalpath, debug )
 ## [num_outliers, max_outlier, freqbins] = CountSFTPowerOutliers ( params_psd, thresh, lalpath, debug )
 ## function to compute the number of outliers of the SFT power statistic


 # The following params_psd fields are REQUIRED from the caller function
 required_fields = {"inputData","outputPSD"};
 for n=1:1:length(required_fields)
  if ( !isfield(params_psd,required_fields{n}) )
   error(["Required field '", required_fields{n}, "' of params_psd was not set by caller function."]);
  endif
 endfor
 # additionally, the following are relevant, but optional (as good defaults exist): PSDmthopSFTs, PSDmthopIFOs, blocksRngMed
 params_psd.outputNormSFT = 1; # this one we ALWAYS need to get the power statistic

 if ( debug == 0 )
  ComputePSD      = [lalpath, "lalapps_ComputePSD -v0"];
 else
  ComputePSD      = [lalpath, "lalapps_ComputePSD -v1"];
 endif

 if ( debug == 1 )
  printf("Computing PSDs for a running median window of %d bins.\n", params_psd.blocksRngMed);
 endif

 # run ComputePSD on all input SFTs
 runCode ( params_psd, ComputePSD );
 psd = load(params_psd.outputPSD);

 # get PSD power outlier count and maximum
 outliers     = psd(psd(:,3)>thresh,3);
 num_outliers = length(outliers);
 max_outlier  = max(psd(:,3));
 freqbins     = length(psd(:,1));

endfunction # CountSFTPowerOutliers()