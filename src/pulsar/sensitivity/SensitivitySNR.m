## Copyright (C) 2011 Karl Wette
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
##   [rho, pd_rho] = SensitivitySNR(paNt, pd, Ns, Rsqr_H, detstat, ...)
## where:
##   rho     = detectable r.m.s. SNR (per segment)
##   pd_rho  = calculated false dismissal probability
##   paNt    = false alarm probability (per template)
##   pd      = false dismissal probability
##   Ns      = number of segments
##   Rsqr_H  = histogram of SNR "geometric factor" R^2
##   detstat = detection statistic, one of:
##      "ChiSqr": chi^2 statistic, e.g. the F-statistic
##                see SensitivityChiSqrFDP for possible options

function [rho, pd_rho] = SensitivitySNR(paNt, pd, Ns, Rsqr_H, detstat, varargin)

  ## display progress updates?
  global sensitivity_progress;
  if isempty(sensitivity_progress)
    sensitivity_progress = false;
  endif
  if sensitivity_progress
    old_pso = page_screen_output(0);
    fprintf("%s: starting\n", funcName);
  endif

  ## check input
  assert(all(paNt > 0));
  assert(all(pd > 0));
  assert(all(Ns > 0));
  assert(isHist(Rsqr_H) || isempty(Rsqr_H));

  ## make sure paNt, pd, and Ns are the same size
  [cserr, paNt, pd, Ns] = common_size(paNt, pd, Ns);
  if cserr > 0
    error("%s: paNt, pd, and Ns are not of common size", funcName);
  endif
  
  ## make inputs column vectors
  siz = size(paNt);
  paNt = paNt(:);
  pd = pd(:);
  Ns = Ns(:);

  ## select a detection statistic
  fdp_vars = {};
  switch detstat
    case "ChiSqr"   ## chi^2 statistic
      [FDP, fdp_vars, fdp_opts] = SensitivityChiSqrFDP(paNt, pd, Ns, varargin);
    otherwise
      error("%s: invalid detection statistic '%s'", funcName, detstat);
  endswitch

  ## get values and weights of R^2 as row vectors
  if isempty(Rsqr_H)
    ## singular case: R^2 = 1
    Rsqr_x = 1.0;
    Rsqr_w = 1.0;
  else
    ## from histogram
    [Rsqr_xb, Rsqr_px] = finiteHist(Rsqr_H);
    [Rsqr_x, Rsqr_dx] = histBinGrids(Rsqr_H, 1, "xc", "dx");
    Rsqr_w = Rsqr_px .* Rsqr_dx;
  endif
  Rsqr_x = Rsqr_x(:)';
  Rsqr_w = Rsqr_w(:)';
  
  ## make row indexes logical, to select rows
  ii = true(length(paNt), 1);

  ## make column indexes ones, to duplicate columns
  jj = ones(length(Rsqr_x), 1);

  ## rho is computed for each paNt, pd, Ns (dim. 1) by summing
  ## false dismissal probability for fixed Rsqr_x, weighted
  ## by Rsqr_w (dim. 2)
  Rsqr_x = Rsqr_x(ones(size(ii)), :);
  Rsqr_w = Rsqr_w(ones(size(ii)), :);

  ## initialise variables
  pd_rho = rhosqr = nan(size(paNt, 1), 1);
  pd_rho_min = pd_rho_max = zeros(size(rhosqr));

  ## calculate the false dismissal probability for rhosqr=0,
  ## only proceed if it's less than the target false dismissal
  ## probability
  rhosqr_min = zeros(size(rhosqr));
  pd_rho_min(ii) = callFDP(rhosqr_min,ii,
                           jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
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
    if sensitivity_progress && sum(ii) != sumii
      sumii = sum(ii);
      fprintf("%s: finding rhosqr_max (%i left)\n", funcName, sumii);
    endif

    ## increment upper bound on rhosqr
    rhosqr_max(ii) *= 2;

    ## calculate false dismissal probability
    pd_rho_max(ii) = callFDP(rhosqr_max,ii,
                             jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                             FDP,fdp_vars,fdp_opts);
    
    ## determine which rhosqr to keep calculating for
    ## exit when there are none left
    ii = (pd_rho_max >= pd);
  until !any(ii)

  ## pick mid-point of range as starting rhosqr
  rhosqr(ii0) = 0.5 * (rhosqr_min(ii0) + rhosqr_max(ii0));

  ## find rhosqr using a combined bifurcation search / Newton-Raphson root-finding
  d_pd_d_rhosqr = D_rhosqr = err = zeros(size(rhosqr));
  rhosqr_Dmin = rhosqr_min;
  rhosqr_Dmax = rhosqr_max;
  pd_rho_Dmin = pd_rho_min;
  pd_rho_Dmax = pd_rho_max;
  ii = ii0;
  sumiibf = sumiinr = 0;
  do

    ## do bifurcation if rhosqr bouding range is still large, or
    ## if rhosqr has strayed outside of bounding range in NR step
    ii_bifurc = (
                 ((rhosqr_max - rhosqr_min) ./ rhosqr_max > 0.1)
                 |
                 !(rhosqr_min <= rhosqr & rhosqr <= rhosqr_max)
                 );
    iibf = ii & ii_bifurc;
    iinr = ii & !ii_bifurc;

    ## display progress updates?
    if sensitivity_progress && (sum(iibf) != sumiibf | sum(iinr) != sumiinr)
      sumiibf = sum(iibf);
      sumiinr = sum(iinr);
      fprintf("%s: bifurcation (%i left) & Newton-Raphson (%i left)\n", funcName, sumiibf, sumiinr);
      ##disp([rhosqr_min(ii)';rhosqr_Dmin(ii)';rhosqr(ii)';rhosqr_Dmax(ii)';rhosqr_max(ii)']);
    endif

    ## do bifurcation search
    if any(iibf)

      ## pick mid-point of range as new rhosqr
      rhosqr(iibf) = 0.5 * (rhosqr_min(iibf) + rhosqr_max(iibf));

      ## calculate false dismissal probability
      pd_rho(iibf) = callFDP(rhosqr,iibf,
                             jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                             FDP,fdp_vars,fdp_opts);
      
      ## replace bounds with mid-point as required
      iimin = iibf & (pd_rho_min >= pd & pd_rho >= pd);
      iimax = iibf & (pd_rho_max <  pd & pd_rho <  pd);
      rhosqr_min(iimin) = rhosqr(iimin);
      rhosqr_max(iimax) = rhosqr(iimax);

      ## re-compute false dismissal probabilities
      pd_rho_min(iimin) = callFDP(rhosqr_min,iimin,
                                  jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                                  FDP,fdp_vars,fdp_opts);
      pd_rho_max(iimax) = callFDP(rhosqr_max,iimax,
                                  jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                                  FDP,fdp_vars,fdp_opts);

      ## reset bounds used to calculate derivatives
      rhosqr_Dmin(iimin) = rhosqr_min(iimin);
      rhosqr_Dmax(iimax) = rhosqr_max(iimax);
      pd_rho_Dmin(iimin) = pd_rho_min(iimin);
      pd_rho_Dmax(iimax) = pd_rho_max(iimax);

      ## prevent existing on bifurcation search alone
      err(iibf) = inf;

    endif

    ## do Newton-Raphson root-finding to converge
    if any(iinr)

      ## calculate false dismissal probability
      pd_rho(iinr) = callFDP(rhosqr,iinr,
                             jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                             FDP,fdp_vars,fdp_opts);

      ## calculate approx. derivative of false dismissal probability
      ## with respect to rhosqr
      d_pd_d_rhosqr(iinr) = (pd_rho_Dmax(iinr) - pd_rho_Dmin(iinr)) ./ (rhosqr_Dmax(iinr) - rhosqr_Dmin(iinr));
      
      ## adjustment to rhosqr given by Newton-Raphson method
      D_rhosqr(iinr) = (pd_rho(iinr) - pd(iinr)) ./ d_pd_d_rhosqr(iinr);
      
      ## fractional error implied by adjustment
      err(iinr) = abs(D_rhosqr(iinr)) ./ rhosqr(iinr);

      ## make adjustment
      rhosqr(iinr) -= D_rhosqr(iinr);

      ## check if rhosqr is still within bounding range
      iir = iinr & (rhosqr_min < rhosqr && rhosqr < rhosqr_max);
      if any(iir)

        ## use adjustment to make new bounds for calculating derivative
        D_rhosqr(iir) = min(abs(rhosqr(iir) - rhosqr_Dmin(iir)),
                            abs(rhosqr(iir) - rhosqr_Dmax(iir)));
        rhosqr_Dmin(iir) = rhosqr(iir) - D_rhosqr(iir);
        rhosqr_Dmax(iir) = rhosqr(iir) + D_rhosqr(iir);
        
        ## re-compute false dismissal probabilities
        pd_rho_Dmin(iir) = callFDP(rhosqr_Dmin,iir,
                                   jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                                   FDP,fdp_vars,fdp_opts);
        pd_rho_Dmax(iir) = callFDP(rhosqr_Dmax,iir,
                                   jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                                   FDP,fdp_vars,fdp_opts);
        
      endif

    endif
      
    ## determine which rhosqr to keep calculating for
    ## exit when there are none left
    ii = (isnan(err) | err > 1e-3);
  until !any(ii)

  ## calculate final false dismissal probability
  pd_rho(ii0) = callFDP(rhosqr,ii0,
                        jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                        FDP,fdp_vars,fdp_opts);
  
  ## return detectable SNR
  rho = sqrt(rhosqr);
  rho = reshape(rho, siz);
  pd_rho = reshape(pd_rho, siz);
  
  ## display progress updates?
  if sensitivity_progress
    fprintf("%s: done\n", funcName);
    page_screen_output(old_pso);
  endif

endfunction

## call a false dismissal probability calculation equation
function pd_rho = callFDP(rhosqr,ii,
                          jj,paNt,pd,Ns,Rsqr_x,Rsqr_w,
                          FDP,fdp_vars,fdp_opts)
  if any(ii)
    pd_rho = sum(feval(FDP,
                       paNt(ii,jj), pd(ii,jj), Ns(ii,jj),
                       rhosqr(ii,jj).*Rsqr_x(ii,:),
                       cellfun(@(x) x(ii,jj), fdp_vars,
                               "UniformOutput", false),
                       fdp_opts
                       ) .* Rsqr_w(ii,:), 2);
  else
    pd_rho = [];
  endif
endfunction
