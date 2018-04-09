## Copyright (C) 2010 Reinhard Prix
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
## @deftypefn {Function File} { [ @var{fDEst}, @var{dfDEst} ] =} estimateFalseDismissal ( @var{fA}, @var{stat_0}, @var{stat_s} )
##
## @strong{DEPRECATED: use @command{estimateRateFromSamples()} or @command{estimateROC()} instead}
##
## function to estimate false-dismissals plus Jackknife error-estimates for given false-alarms
## and samples of the statistic in no-signal case (@var{stat_0}) and in case of signal+noise (@var{stat_s})
##
## new version 2011/01: for N<100 samples, just calculate fDest without errors; for N>100, but not multiple, truncate to closest multiple
##
## @end deftypefn

function [fDEst, dfDEst] = estimateFalseDismissal ( fA, stat_0, stat_s )

  warning ( "DEPRECATED: use estimateRateFromSamples() or estimateROC() instead\n");

  Nbins      = length ( fA );
  Nsamples_0 = length ( stat_0 );
  Nsamples_s = length ( stat_s );

  stat_thresh = empirical_inv (1 - fA, stat_0 );
  fDEst       = empirical_cdf ( stat_thresh, stat_s );

  if ( length(stat_0) < 100 || length(stat_s) < 100 )
    dfDEst = zeros(1,length(fDEst));
    printf("Warning: In function estimateFalseDismissal: Cannot reshape sample array because length=%d smaller than 100. No errors have been computed.\n", length(stat_0));

  else
    g = 100;

    if ( round(length(stat_0)/g) != length(stat_0)/g || round(length(stat_s)/g) != length(stat_s)/g )

      printf("Warning: In function estimateFalseDismissal: Cannot reshape sample array because \n\
          length=%d is not multiple of 100. Samples are truncated to closest multiple for error computation.\n", length(stat_0));
      stat_0 = resize (stat_0, 1, g*floor(length(stat_0)/g));
      stat_s = resize (stat_s, 1, g*floor(length(stat_s)/g));

    endif

    h_0 = round(Nsamples_0 / g );
    h_s = round(Nsamples_s / g );
    ## Jackknife error-estimate on g=100 subgroups
    stat_0_j = reshape ( stat_0, g, Nsamples_0/g );
    stat_s_j = reshape ( stat_s, g, Nsamples_s/g );

    diffs_j = zeros(g, Nbins);
    for j = 1:g
      thresh_j     = empirical_inv (1 - fA, stat_0_j(j,:) );
      fD_j         = empirical_cdf ( thresh_j, stat_s_j(j,:) );
      diffs_j(j,:) = fD_j - fDEst;
    endfor

    varfD = 1/(g * (g-1)) * sumsq ( diffs_j, 1 );

    dfDEst = sqrt ( varfD );

  endif

endfunction
