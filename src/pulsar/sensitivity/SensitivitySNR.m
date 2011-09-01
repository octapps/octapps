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
##   rho = SensitivitySNR(pa, pd, Ns, Rsqr_H, detstat, ...)
## where:
##   rho     = detectable r.m.s. SNR (per segment)
##   pa      = false alarm probability
##   pd      = false dismissal probability
##   Ns      = number of segments
##   Rsqr_H  = histogram of SNR "geometric factor" R^2
##   detstat = detection statistic, one of:
##      "ChiSqr": chi^2 statistic, e.g. the F-statistic
##                see SensitivityChiSqrFDP for possible options

function rho = SensitivitySNR(pa, pd, Ns, Rsqr_H, detstat, varargin)

  ## check input
  assert(isHist(Rsqr_H) || isempty(Rsqr_H));

  ## make sure pa, pd, and Ns are the same size
  [cserr, pa, pd, Ns] = common_size(pa, pd, Ns);
  if cserr > 0
    error("%s: pa, pd, and Ns are not of common size", funcName);
  endif
  
  ## make inputs column vectors
  siz = size(pa);
  pa = pa(:);
  pd = pd(:);
  Ns = Ns(:);

  ## select a detection statistic
  fdp_vars = {};
  switch detstat
    case "ChiSqr"
      ## chi-squared statistic (e.g. Fstat)
      [FDP, fdp_vars, fdp_opts] = InitChiSqrFDP(pa, pd, Ns, varargin);
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
  ii = true(length(pa), 1);

  ## make column indexes ones, to duplicate columns
  jj = ones(length(Rsqr_x), 1);

  ## rho is computed for each pa, pd, Ns (dim. 1) by summing
  ## false dismissal probability for fixed Rsqr_x, weighted
  ## by Rsqr_w (dim. 2)
  Rsqr_x = Rsqr_x(ones(size(ii)), :);
  Rsqr_w = Rsqr_w(ones(size(ii)), :);

  ## initialise false dismissal probability variables
  pd_rhosqr = zeros(size(pa, 1), 1);
  pd_rhosqr_min = pd_rhosqr_max = d_pd_d_rhosqr = pd_rhosqr;

  ## calculate the false dismissal probability for rhosqr=0,
  ## only proceed if it's less than the target false dismissal
  ## probability
  rhosqr_min = zeros(size(pd_rhosqr));
  pd_rhosqr_min(ii) = callFDP(rhosqr_min,
                              ii,jj,pa,pd,Ns,Rsqr_x,Rsqr_w,
                              FDP,fdp_vars,fdp_opts);
  ii0 = (pd_rhosqr_min >= pd);
  rhosqr = nan(size(rhosqr_min));

  ## find rhosqr_max where the false dismissal rate becomes
  ## less than the target false dismissal rate, to bracket
  ## the range of rhosqr
  rhosqr_max = ones(size(pd_rhosqr));
  ii = ii0;
  do

    ## increment upper bound on rhosqr
    rhosqr_max *= 3;

    ## calculate false dismissal probability
    pd_rhosqr_max(ii) = callFDP(rhosqr_max,
                                ii,jj,pa,pd,Ns,Rsqr_x,Rsqr_w,
                                FDP,fdp_vars,fdp_opts);

    ## determine which rhosqr to keep calculating for
    ## exit when there are none left
    ii = (pd_rhosqr_max >= pd);
  until !any(ii)

  ## do a bifurcation search to reduce the range of rhosqr
  ii = ii0;
  do

    ## pick mid-point of range as new rhosqr
    rhosqr(ii) = 0.5 * (rhosqr_min(ii) + rhosqr_max(ii));

    ## calculate false dismissal probability
    pd_rhosqr(ii) = callFDP(rhosqr,
                            ii,jj,pa,pd,Ns,Rsqr_x,Rsqr_w,
                            FDP,fdp_vars,fdp_opts);
    
    ## replace bounds with mid-point as required
    ii_min = (pd_rhosqr_min >= pd & pd_rhosqr >= pd);
    ii_max = (pd_rhosqr_max <  pd & pd_rhosqr <  pd);
    rhosqr_min(ii_min) = rhosqr(ii_min);
    rhosqr_max(ii_max) = rhosqr(ii_max);

    ## determine which rhosqr to keep calculating for
    ## exit when there are none left
    ii = ((rhosqr_max - rhosqr_min) ./ rhosqr_max > 0.1);
  until !any(ii)

  ## finally use Newton-Raphson root-finding to converge
  ## to accurate values of rhosqr
  ii = ii0;
  rhosqr(ii) = 0.5 * (rhosqr_min(ii) + rhosqr_max(ii));
  D_rhosqr = err = zeros(size(rhosqr));
  do

    ## calculate false dismissal probability at
    ## current and bounding values of rhosqr
    pd_rhosqr_min(ii) = callFDP(rhosqr_min,
                                ii,jj,pa,pd,Ns,Rsqr_x,Rsqr_w,
                                FDP,fdp_vars,fdp_opts);
    pd_rhosqr(ii)     = callFDP(rhosqr,
                                ii,jj,pa,pd,Ns,Rsqr_x,Rsqr_w,
                                FDP,fdp_vars,fdp_opts);
    pd_rhosqr_max(ii) = callFDP(rhosqr_max,
                                ii,jj,pa,pd,Ns,Rsqr_x,Rsqr_w,
                                FDP,fdp_vars,fdp_opts);

    ## calculate approx. derivative of false dismissal rate
    ## with respect to rhosqr
    d_pd_d_rhosqr(ii) = (pd_rhosqr_max(ii) - pd_rhosqr_min(ii)) ./ (rhosqr_max(ii) - rhosqr_min(ii));

    ## adjustment to rhosqr given by Newton-Raphson method
    D_rhosqr(ii) = (pd_rhosqr(ii) - pd(ii)) ./ d_pd_d_rhosqr(ii);

    ## absolute error implied by adjustment
    err(ii) = abs(D_rhosqr(ii) ./ rhosqr(ii));

    ## make adjustment
    rhosqr(ii) -= D_rhosqr(ii);

    ## use adjustment to make new bounds for calculating derivative
    D_rhosqr(ii) = min(abs(rhosqr(ii) - rhosqr_max(ii)),
                       abs(rhosqr(ii) - rhosqr_min(ii)));
    rhosqr_min(ii) = rhosqr(ii) - D_rhosqr(ii);
    rhosqr_max(ii) = rhosqr(ii) + D_rhosqr(ii);

    ## determine which rhosqr to keep calculating for
    ## exit when there are none left
    ii = (isnan(err) | err > 1e-4);
  until !any(ii)

  ## return detectable SNR
  rho = sqrt(rhosqr);
  rho = reshape(rho, siz);
  
endfunction

## call a false dismissal probability calculation equation
function pd_rhosqr = callFDP(rhosqr,
                             ii,jj,pa,pd,Ns,Rsqr_x,Rsqr_w,
                             FDP,fdp_vars,fdp_opts)
  pd_rhosqr = sum(feval(FDP,
                        pa(ii,jj), pd(ii,jj), Ns(ii,jj),
                        rhosqr(ii,jj).*Rsqr_x(ii,:),
                        cellfun(@(x) x(ii,jj), fdp_vars,
                                "UniformOutput", false),
                        fdp_opts
                        ) .* Rsqr_w(ii,:), 2);
endfunction

##### detection statistic functions #####

## initialise chi-squared statistic (e.g. Fstat)
function [FDP, fdp_vars, fdp_opts] = InitChiSqrFDP(pa, pd, Ns, args)

  FDP = @ChiSqrFDP;

  ## options
  fdp_opts = parseOptions(args,
                          {"deg_freedom", "numeric,scalar", 4},
                          {"normal_approx", "logical,scalar", false}
                          );
  
  ## degrees of freedom of the statistic
  nu = fdp_opts.deg_freedom;

  ## false alarm threshold
  sa = invFalseAlarm_chi2_asym(pa, Ns .* nu);
  fdp_vars{1} = sa;
  
endfunction

## false dismissal probability for a chi-squared statistic (e.g. Fstat)
function pd_rhosqr = ChiSqrFDP(pa, pd, Ns, rhosqr, fdp_vars, fdp_opts)
  
  ## degrees of freedom of the statistic
  nu = fdp_opts.deg_freedom;

  ## false alarm threshold
  sa = fdp_vars{1};

  ## false dismissal probability
  if fdp_opts.normal_approx
    ## use normal approximation
    mean = Ns .* ( nu + rhosqr );
    stdv = sqrt( 2.*Ns .* ( nu + 2.*rhosqr ) );
    pd_rhosqr = normcdf(sa, mean, stdv);
  else
    ## use non-central chi-sqr distribution
    pd_rhosqr = ChiSquare_cdf(sa, Ns .* nu, Ns .* rhosqr);
  endif

endfunction
