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

## Helper function for SensitivitySNR:
## Calculate the false dismissal probability of a chi^2 detection
## statistic, such as the F-statistic
## Options:
##   "paNt" = false alarm probability per template
##   "sa"   = false alarm threshold
##   "dof"  = number of degrees of freedom (default: 4)
##   "norm" = use normal approximation to chi^2 (default: false)

function [FDP, fdp_vars, fdp_opts] = SensitivityChiSqrFDP(pd, Ns, args)

  FDP = @ChiSqrFDP;

  ## options
  parseOptions(args,
               {"paNt", "numeric,matrix", []},
               {"sa", "numeric,matrix", []},
               {"dof", "numeric,scalar", 4},
               {"norm", "logical,scalar", false}
               );
  fdp_opts.dof = dof;
  fdp_opts.norm = norm;

  ## degrees of freedom of the statistic
  nu = fdp_opts.dof;

  ## false alarm threshold
  if sum([isempty(paNt),isempty(sa)]) != 1
    error("%s: 'paNt' and 'sa' are mutually exclusive options", funcName);
  endif
  if !isempty(paNt)
    sa = invFalseAlarm_chi2_asym(paNt, Ns*nu);
  endif
  fdp_vars{1} = sa;
  
endfunction

## calculate false dismissal probability
function pd_rhosqr = ChiSqrFDP(pd, Ns, rhosqr, fdp_vars, fdp_opts)
  
  ## degrees of freedom of the statistic
  nu = fdp_opts.dof;

  ## false alarm threshold
  sa = fdp_vars{1};

  ## false dismissal probability
  if fdp_opts.norm

    ## use normal approximation
    mean = Ns.*( nu + rhosqr );
    stdv = sqrt( 2.*Ns .* ( nu + 2.*rhosqr ) );
    pd_rhosqr = normcdf(sa, mean, stdv);

  else

    ## use non-central chi-sqr distribution
    pd_rhosqr = ChiSquare_cdf(sa, Ns*nu, Ns.*rhosqr);

  endif

endfunction

## Test sensitivity calculated for chi^2 statistic
## against values calculated by Mathematica implementation

## calculate Rsqr_H for isotropic signal population
%!shared Rsqr_H
%! Rsqr_H = SqrSNRGeometricFactorHist;

## test SNR rho against reference value rho0
%!function __test_sens(Rsqr_H,paNt,pd,nu,Ns,rho0)
%! rho = SensitivitySNR(pd,Ns,Rsqr_H,"ChiSqr","paNt",paNt,"dof",nu);
%! assert(abs(rho - rho0) < 5e-3 * abs(rho0));

## tests
%!test __test_sens(Rsqr_H,0.01,0.05,2.,1.,6.500229404020667)
%!test __test_sens(Rsqr_H,0.01,0.05,2.,100.,1.4501786370660101)
%!test __test_sens(Rsqr_H,0.01,0.05,2.,10000.,0.43248371074365743)
%!test __test_sens(Rsqr_H,0.01,0.05,4.,1.,7.110312384844615)
%!test __test_sens(Rsqr_H,0.01,0.05,4.,100.,1.6934283709005387)
%!test __test_sens(Rsqr_H,0.01,0.05,4.,10000.,0.5132616652425249)
%!test __test_sens(Rsqr_H,0.01,0.1,2.,1.,5.6931349212023195)
%!test __test_sens(Rsqr_H,0.01,0.1,2.,100.,1.3098992538836696)
%!test __test_sens(Rsqr_H,0.01,0.1,2.,10000.,0.393946148321775)
%!test __test_sens(Rsqr_H,0.01,0.1,4.,1.,6.263389087118094)
%!test __test_sens(Rsqr_H,0.01,0.1,4.,100.,1.5333568014438428)
%!test __test_sens(Rsqr_H,0.01,0.1,4.,10000.,0.46767812813800835)
%!test __test_sens(Rsqr_H,1.e-7,0.05,2.,1.,11.002696682608635)
%!test __test_sens(Rsqr_H,1.e-7,0.05,2.,100.,2.0800155014413324)
%!test __test_sens(Rsqr_H,1.e-7,0.05,2.,10000.,0.6003920453051875)
%!test __test_sens(Rsqr_H,1.e-7,0.05,4.,1.,11.606255607179685)
%!test __test_sens(Rsqr_H,1.e-7,0.05,4.,100.,2.404848976803566)
%!test __test_sens(Rsqr_H,1.e-7,0.05,4.,10000.,0.7116957707722287)
%!test __test_sens(Rsqr_H,1.e-7,0.1,2.,1.,10.068520447374155)
%!test __test_sens(Rsqr_H,1.e-7,0.1,2.,100.,1.9433375742547598)
%!test __test_sens(Rsqr_H,1.e-7,0.1,2.,10000.,0.56589253300647)
%!test __test_sens(Rsqr_H,1.e-7,0.1,4.,1.,10.649372763801795)
%!test __test_sens(Rsqr_H,1.e-7,0.1,4.,100.,2.2522147733652567)
%!test __test_sens(Rsqr_H,1.e-7,0.1,4.,10000.,0.6710478737082527)
%!test __test_sens(Rsqr_H,1.e-12,0.05,2.,1.,14.012717225137239)
%!test __test_sens(Rsqr_H,1.e-12,0.05,2.,100.,2.441085854041298)
%!test __test_sens(Rsqr_H,1.e-12,0.05,2.,10000.,0.6898386226584616)
%!test __test_sens(Rsqr_H,1.e-12,0.05,4.,1.,14.58187475236257)
%!test __test_sens(Rsqr_H,1.e-12,0.05,4.,100.,2.8043381028604606)
%!test __test_sens(Rsqr_H,1.e-12,0.05,4.,10000.,0.8170953766321501)
%!test __test_sens(Rsqr_H,1.e-12,0.1,2.,1.,13.01088604642134)
%!test __test_sens(Rsqr_H,1.e-12,0.1,2.,100.,2.3033376553134164)
%!test __test_sens(Rsqr_H,1.e-12,0.1,2.,10000.,0.6564656248431371)
%!test __test_sens(Rsqr_H,1.e-12,0.1,4.,1.,13.562811344954063)
%!test __test_sens(Rsqr_H,1.e-12,0.1,4.,100.,2.651777751079593)
%!test __test_sens(Rsqr_H,1.e-12,0.1,4.,10000.,0.7778610228077436)
