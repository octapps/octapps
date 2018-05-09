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
## @deftypefn {Function File} { [ @var{lX}, @var{freqmin}, @var{freqmax}, @var{freqbins}, @var{num_outliers}, @var{max_outlier} ] =} EstimateLinePriorsFromNormSFT ( @var{psdfiles}, @var{thresh}, @var{LVlmin}, @var{LVlmax} )
##
## function to estimate line priors from normalized SFT power values in files computed by @command{lalapps_ComputePSD}
## psdfiles must be a cell array of existing files of length numDet
## thresh must be a numDet*T matrix, where T is an arbitrary number of thresh values per IFO, so that lX will be returned as a numDet*T matrix also
##
## @end deftypefn

function [lX, freqmin, freqmax, freqbins, num_outliers, max_outlier] = EstimateLinePriorsFromNormSFT ( psdfiles, thresh, LVlmin, LVlmax )

  numDet = length(psdfiles);
  if ( length(thresh(:,1)) != numDet )
    error(["Incompatible lengths of input arguments psdfiles (", int2str(numDet), ") and thresh (", int2str(length(thresh(:,1))), ")."]);
  endif

  for X = 1:1:numDet

    if ( exist(psdfiles{X},"file") != 2 )
      error(["Input PSD file ", psdfiles{X}, " not found."]);
    endif

    psd = load(psdfiles{X});
    if ( length(psd(1,:)) < 3 )
      error(["PSD file '", psdfiles{X}, "' does not contain a 3rd column (normSFT power) required for lX computation. Rerun lalapps_ComputePSD with --outputNormSFT=1."]);
    endif

    ## get PSD power outlier count and maximum
    for n = 1:1:length(thresh(X,:))
      num_outliers(X,n) = length(psd(psd(:,3)>thresh(X,n),3));
    endfor
    max_outlier(X)  = max(psd(:,3));
    freqmin(X)      = psd(1,1);
    freqmax(X)      = psd(end,1);
    freqbins(X)     = length(psd(:,1));

    ## prepare lower and upper cutoffs, either statically or depending on freqbins
    if ( LVlmin < 0 )
      LVlminX = -LVlmin/(freqbins(X)+LVlmin);
    else
      LVlminX = LVlmin;
    endif
    if ( LVlmax < 0 )
      LVlmaxX = -LVlmax*freqbins(X)-1;
    else
      LVlmaxX = LVlmax;
    endif

    ## compute the actual lX
    for n = 1:1:length(thresh(X,:))
      lX(X,n) = max(LVlminX, num_outliers(X,n)/(freqbins(X)-num_outliers(X,n)));
      lX(X,n) = min(lX(X,n), LVlmaxX);
    endfor

  endfor ## X = 1:1:numDet

endfunction ## EstimateLinePriorsFromNormSFT()

%!test disp("no test exists for this function as it requires access to data not included in OctApps")
