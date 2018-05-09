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
## @deftypefn {Function File} { [ @var{num_outliers}, @var{max_outlier}, @var{freqbins} ] =} CountSFTPowerOutliers ( @var{params_psd}, @var{thresh}, @var{lalpath}, @var{debug} )
##
## function to compute the number of outliers of the SFT power statistic
##
## @end deftypefn

function [num_outliers, max_outlier, freqbins] = CountSFTPowerOutliers ( params_psd, thresh, lalpath, debug )

  threshdimensions = size(thresh);
  if ( ( length(threshdimensions) > 3 ) || ( ( threshdimensions(1) > 1 ) && ( threshdimensions(2) > 1 ) ) )
    error("Parameter 2 (thresh) has too high dimension, only a single row or column vector is accepted.");
  endif

  ## The following params_psd fields are REQUIRED from the caller function
  required_fields = {"inputData","outputPSD"};
  for n=1:1:length(required_fields)
    if ( !isfield(params_psd,required_fields{n}) )
      error(["Required field '", required_fields{n}, "' of params_psd was not set by caller function."]);
    endif
  endfor
  ## additionally, the following are relevant, but optional (as good defaults exist): PSDmthopSFTs, PSDmthopIFOs, blocksRngMed
  params_psd.outputNormSFT = 1; ## this one we ALWAYS need to get the power statistic

  ComputePSD      = [lalpath, "lalapps_ComputePSD"];

  if ( debug )
    printf("Computing PSDs for a running median window of %d bins.\n", params_psd.blocksRngMed);
    params_psd.LAL_DEBUG_LEVEL = "MSGLVL2"; ## errors and warnings
  else
    params_psd.LAL_DEBUG_LEVEL = 0;
  endif

  ## run ComputePSD on all input SFTs
  runCode ( params_psd, ComputePSD );
  psd = load(params_psd.outputPSD);

  ## get PSD power outlier count and maximum
  for n = 1:1:length(thresh)
    num_outliers(n) = length(psd(psd(:,3)>thresh(n),3));
  endfor
  max_outlier  = max(psd(:,3));
  freqbins     = length(psd(:,1));

endfunction ## CountSFTPowerOutliers()

%!test disp("no test exists for this function as it requires access to data not included in OctApps")
