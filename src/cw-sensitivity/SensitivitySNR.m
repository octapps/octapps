## Copyright (C) 2016 Christoph Dreissigacker
## Copyright (C) 2011, 2016 Karl Wette
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

## Calculate sensitivity in terms of the root-mean-square SNR
## Syntax:
##   [rho, pd_rho] = SensitivitySNR("opt", val, ...)
## where:
##   rho      = detectable r.m.s. SNR (per segment)
##   pd_rho   = calculated false dismissal probability
## and where options are:
##   "pd"     = false dismissal probability
##   "Ns"     = number of segments
##   "Rsqr"   = histogram of SNR "geometric factor" R^2,
##              computed using SqrSNRGeometricFactorHist(),
##              or scalar giving mean value of R^2
##   "stat"   = detection statistic, one of:
##              * {"ChiSqr", "opt", val, ...}
##                  chi^2 statistic, e.g. the F-statistic, see
##                  SensitivityChiSqrFDP() for options
##              * {"HoughFstat", "opt", val, ...}
##                  Hough on the F-statistic, see
##                  SensitivityHoughFstatFDP() for options
##   "prog"   = show progress updates
##  "misHist" = mismatch histogram

function [rho, pd_rho] = SensitivitySNR(varargin)

  ## parse options
  parseOptions(varargin,
               {"pd", "real,strictunit,column"},
               {"Ns", "integer,strictpos,column"},
               {"Rsqr", "a:Hist", []},
               {"misHist","a:Hist"},
               {"stat", "cell,vector"},
               {"prog", "logical,scalar", false},
               []);
  assert(histDim(Rsqr) == 1, "%s: R^2 must be a 1D histogram", funcName);                 #add for mismatch
  assert(length(stat) > 1 && ischar(stat{1}), "%s: first element of 'stat' must be a string", funcName);

  ## select a detection statistic
  switch stat{1}
    case "ChiSqr"   ## chi^2 statistic
      [pd, Ns, FDP, fdp_vars, fdp_opts] = SensitivityChiSqrFDP(pd, Ns, stat(2:end));
    case "HoughFstat"   ## Hough on F-statistic
      [pd, Ns, FDP, fdp_vars, fdp_opts] = SensitivityHoughFstatFDP(pd, Ns, stat(2:end));
    otherwise
      error("%s: invalid detection statistic '%s'", funcName, stat{1});
  endswitch

  ## get probability densities and bin quantities
  Rsqr_px = histProbs(Rsqr);
  [Rsqr_x, Rsqr_dx] = histBins(Rsqr, 1, "centre", "width");

  ## get probabilitiy densities for mismatch
  mism_px = histProbs(misHist);
  [mism_x, mism_dx] = histBins(misHist, 1, "centre", "width");

  ## check histogram bins are positive and contain no infinities                  # add for mismatch
  if min(histRange(Rsqr)) < 0
    error("%s: R^2 histogram bins must be positive", funcName);
  endif
  if Rsqr_px(1) > 0 || Rsqr_px(end) > 0
    error("%s: R^2 histogram contains non-zero probability in infinite bins", funcName);
  endif

  ## chop off infinite bins and resize to row vectors
  Rsqr_px = reshape(Rsqr_px(2:end-1), 1, []);
  Rsqr_x = reshape(Rsqr_x(2:end-1), 1, []);
  Rsqr_dx = reshape(Rsqr_dx(2:end-1), 1, []);

  ## chop off infinite bins and resize to layer vectors
  mism_px = reshape(mism_px(2:end-1), 1,1, []);
  mism_x = reshape(mism_x(2:end-1), 1,1, []);
  mism_dx = reshape(mism_dx(2:end-1), 1,1, []);

  ## compute weights
  Rsqr_w = Rsqr_px .* Rsqr_dx;
  mism_w = mism_px .* mism_dx;

  ## show progress updates?
  if prog
    old_pso = page_screen_output(0);
    printf("%s: starting\n", funcName);
  endif

  ## make row indexes logical, to select rows
  ii = true(length(pd), 1);

  ## make column indexes ones, to duplicate columns
  jj = ones(length(Rsqr_x), 1);

  ## make layer indices ones, to duplicate layers
  kk = ones(length(mism_x), 1);

  ## rho is computed for each pd and Ns (dim. 1) by summing
  ## false dismissal probability for fixed Rsqr_x, weighted
  ## by Rsqr_w (dim. 2)
  Rsqr_x = Rsqr_x(ii + 0, :,kk);
  Rsqr_w = Rsqr_w(ii + 0, :,kk);    # ii + 0 converts logical into double
  mism_x = mism_x(ii + 0, jj,:);
  mism_w = mism_w(ii + 0, jj,:);

  ## initialise variables
  pd_rho = rhosqr = nan(size(pd, 1), 1);
  pd_rho_min = pd_rho_max = zeros(size(rhosqr));

  ## calculate the false dismissal probability for rhosqr=0,
  ## only proceed if it's less than the target false dismissal
  ## probability
  rhosqr_min = zeros(size(rhosqr));
  pd_rho_min(ii) = callFDP(rhosqr_min,ii,
                           jj,kk,pd,Ns,Rsqr_x,Rsqr_w,mism_x, mism_w,
                           FDP,fdp_vars,fdp_opts);
  ii0 = (pd_rho_min >= pd);

  ## find rhosqr_max where the false dismissal probability becomes
  ## less than the target false dismissal probability, to bracket
  ## the range of rhosqr
  rhosqr_max = ones(size(rhosqr));
  ii = ii0;
  sumii = 0;
  do

    ## display progress updates?
    if prog && sum(ii) != sumii
      sumii = sum(ii);
      printf("%s: finding rhosqr_max (%i left)\n", funcName, sumii);
    endif

    ## increment upper bound on rhosqr
    rhosqr_max(ii) *= 2;

    ## calculate false dismissal probability
    pd_rho_max(ii) = callFDP(rhosqr_max,ii,
                             jj,kk,pd,Ns,Rsqr_x,Rsqr_w, mism_x, mism_w,
                             FDP,fdp_vars,fdp_opts);

    ## determine which rhosqr to keep calculating for
    ## exit when there are none left
    ii = (pd_rho_max >= pd);
  until !any(ii)

  ## find rhosqr using a bifurcation search
  err1 = inf(size(rhosqr));
  err2 = inf(size(rhosqr));
  ii = ii0;
  sumii = 0;
  do

    ## display progress updates?
    if prog && sum(ii) != sumii
      sumii = sum(ii);
      printf("%s: bifurcation search (%i left)\n", funcName, sumii);
    endif

    ## pick random point within range as new rhosqr
    u = rand(size(rhosqr));
    rhosqr(ii) = rhosqr_min(ii) .* u(ii) + rhosqr_max(ii) .* (1-u(ii));

    ## calculate new false dismissal probability
    pd_rho(ii) = callFDP(rhosqr,ii,
                         jj,kk,pd,Ns,Rsqr_x,Rsqr_w, mism_x, mism_w,
                         FDP,fdp_vars,fdp_opts);

    ## replace bounds with mid-point as required
    iimin = ii & (pd_rho_min > pd & pd_rho > pd);
    iimax = ii & (pd_rho_max < pd & pd_rho < pd);
    rhosqr_min(iimin) = rhosqr(iimin);
    pd_rho_min(iimin) = pd_rho(iimin);
    rhosqr_max(iimax) = rhosqr(iimax);
    pd_rho_max(iimax) = pd_rho(iimax);

    ## fractional error in false dismissal rate
    err1(ii) = abs(pd_rho(ii) - pd(ii)) ./ pd(ii);

    ## fractional range of rhosqr
    err2(ii) = (rhosqr_max(ii) - rhosqr_min(ii)) ./ rhosqr(ii);

    ## determine which rhosqr to keep calculating for
    ## exit when there are none left
    ii = (isfinite(err1) & err1 > 1e-3) & (isfinite(err2) & err2 > 1e-8);
  until !any(ii)

  ## return detectable SNR
  rho = sqrt(rhosqr);

  ## display progress updates?
  if prog
    printf("%s: done\n", funcName);
    page_screen_output(old_pso);
  endif

endfunction

## call a false dismissal probability calculation equation
function pd_rho = callFDP(rhosqr,ii,
                          jj,kk,pd,Ns,Rsqr_x,Rsqr_w,mism_x, mism_w,
                          FDP,fdp_vars,fdp_opts)
  if any(ii)
    pd_rho = sum(sum(feval(FDP,
                       pd(ii,jj,kk), Ns(ii,jj,kk),
                       rhosqr(ii,jj,kk).*Rsqr_x(ii,:,kk).*(1 - mism_x(ii,jj,:)),
                       cellfun(@(x) x(ii,jj,kk), fdp_vars,
                               "UniformOutput", false),
                       fdp_opts
                       ) .* Rsqr_w(ii,:,kk) .*mism_w(ii,jj,:), 2),3);
  else
    pd_rho = [];
  endif
endfunction
