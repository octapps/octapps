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

## Helper function for SensitivityDepth:
## Calculate the false dismissal probability of a chi^2 detection
## statistic, such as the F-statistic
## Options:
##   "paNt" = false alarm probability per template
##   "sa"   = false alarm threshold
##   "dof"  = degrees of freedom per segment (default: 4)
##   "norm" = use normal approximation to chi^2 (default: false)

function [pd, Ns, FDP, fdp_vars, fdp_opts] = SensitivityChiSqrFDPBayes(pd, Ns, args)

  FDP = @ChiSqrFDP;

  ## options
  parseOptions(args,
               {"paNt", "real,strictunit,matrix", []},
               {"sa", "real,strictpos,matrix", []},
               {"dof", "real,strictpos,scalar", 4},
               {"norm", "logical,scalar", false}
               );
  fdp_opts.dof = dof;
  fdp_opts.norm = norm;

  ## false alarm threshold
  if !xor(isempty(paNt), isempty(sa))
    error("%s: 'paNt' and 'sa' are mutually exclusive options", funcName);
  endif
  if !isempty(paNt)
    [cserr, paNt, pd, Ns] = common_size(paNt, pd, Ns);
    if cserr > 0
      error("%s: paNt, pd, and Ns are not of common size", funcName);
    endif
    sa = invFalseAlarm_chi2(paNt, Ns.*dof);
  else
    [cserr, sa, pd, Ns] = common_size(sa, pd, Ns);
    if cserr > 0
      error("%s: sa, pd, and Ns are not of common size", funcName);
    endif
  endif

  ## variables
  fdp_vars{1} = sa;

endfunction

## calculate false dismissal probability
function pd_rhosqr = ChiSqrFDP(Ns, rhosqr, fdp_vars, fdp_opts)

  ## degrees of freedom per segment
  nu = fdp_opts.dof;

  ## false alarm threshold
  sa = fdp_vars{1};

  ## false dismissal probability
  if fdp_opts.norm

    ## use normal approximation
    mean = Ns.*( nu + rhosqr );
    stdv = sqrt( 2.*Ns .* ( nu + 2.*rhosqr ) );
    pd_rhosqr = normpdf(sa, mean, stdv);

  else

    ## use non-central chi-sqr distribution
    pd_rhosqr = ChiSquare_pdf(sa, Ns*nu, Ns.*rhosqr);

  endif

endfunction

## Test sensitivity calculated for chi^2 statistic
## against values calculated by Mathematica implementation

## calculate Rsqr for isotropic signal population
%!shared Rsqr
%!  Rsqr = SqrSNRGeometricFactorHist;

## test SNR depth against reference value depth0
%!function __test_sens(Rsqr,paNt,pd,nu,Ns,depth0)
%!  depth = SensitivityDepth("Tdata",86400*Ns,"pd",pd,"Ns",Ns,"Rsqr",Rsqr,"stat",{"ChiSqr","paNt",paNt,"dof",nu});
%!  assert(abs(depth - depth0) < 1e-2 * abs(depth0));

## tests
%!test __test_sens(Rsqr,0.01,0.05,2,1,17.9751)
%!test __test_sens(Rsqr,0.01,0.05,2,100,80.4602)
%!test __test_sens(Rsqr,0.01,0.05,2,10000,269.687)
%!test __test_sens(Rsqr,0.01,0.05,4,1,16.429)
%!test __test_sens(Rsqr,0.01,0.05,4,100,68.8944)
%!test __test_sens(Rsqr,0.01,0.05,4,10000,227.24)
%!test __test_sens(Rsqr,0.01,0.1,2,1,20.5666)
%!test __test_sens(Rsqr,0.01,0.1,2,100,89.3568)
%!test __test_sens(Rsqr,0.01,0.1,2,10000,297.123)
%!test __test_sens(Rsqr,0.01,0.1,4,1,18.6925)
%!test __test_sens(Rsqr,0.01,0.1,4,100,76.3345)
%!test __test_sens(Rsqr,0.01,0.1,4,10000,250.28)
%!test __test_sens(Rsqr,1e-07,0.05,2,1,10.5687)
%!test __test_sens(Rsqr,1e-07,0.05,2,100,55.9013)
%!test __test_sens(Rsqr,1e-07,0.05,2,10000,193.411)
%!test __test_sens(Rsqr,1e-07,0.05,4,1,10.0133)
%!test __test_sens(Rsqr,1e-07,0.05,4,100,48.3342)
%!test __test_sens(Rsqr,1e-07,0.05,4,10000,163.153)
%!test __test_sens(Rsqr,1e-07,0.1,2,1,11.589)
%!test __test_sens(Rsqr,1e-07,0.1,2,100,60.1536)
%!test __test_sens(Rsqr,1e-07,0.1,2,10000,206.551)
%!test __test_sens(Rsqr,1e-07,0.1,4,1,10.9521)
%!test __test_sens(Rsqr,1e-07,0.1,4,100,51.9024)
%!test __test_sens(Rsqr,1e-07,0.1,4,10000,174.182)
%!test __test_sens(Rsqr,1e-12,0.05,2,1,8.29336)
%!test __test_sens(Rsqr,1e-12,0.05,2,100,47.5524)
%!test __test_sens(Rsqr,1e-12,0.05,2,10000,168.007)
%!test __test_sens(Rsqr,1e-12,0.05,4,1,7.96925)
%!test __test_sens(Rsqr,1e-12,0.05,4,100,41.3759)
%!test __test_sens(Rsqr,1e-12,0.05,4,10000,141.831)
%!test __test_sens(Rsqr,1e-12,0.1,2,1,8.97247)
%!test __test_sens(Rsqr,1e-12,0.1,2,100,50.7244)
%!test __test_sens(Rsqr,1e-12,0.1,2,10000,177.979)
%!test __test_sens(Rsqr,1e-12,0.1,4,1,8.60838)
%!test __test_sens(Rsqr,1e-12,0.1,4,100,44.0545)
%!test __test_sens(Rsqr,1e-12,0.1,4,10000,150.205)
