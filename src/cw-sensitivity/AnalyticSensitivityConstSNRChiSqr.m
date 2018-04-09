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

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{rhob}, @var{tms} ] =} AnalyticSensitivityConstSNRChiSqr ( @var{paNt}, @var{pd}, @var{Ns}, @var{nu} )
##
## Calculate sensitivty in terms of the root-mean-square SNR for
## a population of constant-SNR signals, and for a chi^2 detection
## statistic
##
## @heading Arguments
##
## @table @var
## @item rhob
## detectable r.m.s. SNR (per segment)
##
## @item tms
## terms of the second factor of the expression
##
## @item paNt
## false alarm probability (per template)
##
## @item pd
## false dismissal probability
##
## @item Ns
## number of segments
##
## @item nu
## degrees of freedom per segment
##
## @end table
##
## @end deftypefn

function [rhob,tms] = AnalyticSensitivityConstSNRChiSqr(paNt, pd, Ns, nu)

  ## check input
  assert(all(paNt > 0));
  assert(all(pd > 0));
  assert(all(Ns > 0));
  assert(isscalar(nu));

  ## make sure paNt, pd, and Ns are the same size
  [cserr, paNt, pd, Ns] = common_size(paNt, pd, Ns);
  if cserr > 0
    error("%s: paNt, pd, and Ns are not of common size", funcName);
  endif

  ## normalised false alarm threshold
  sa = invFalseAlarm_chi2(paNt, Ns*nu);
  za = (sa - Ns*nu) ./ sqrt(2*Ns*nu);

  ## sensitivity SNR
  [rhob,tms] = AnalyticSensitivitySNRExpr(za, pd, Ns, nu);

endfunction

## Test sensitivity calculated for chi^2 statistic
## against values calculated by SensitivityDepth(),
## corrected for constant SNR
##  - test SNR depth against reference value depth0
%!function __test_sens_chisqr(paNt,pd,nu,Ns,depth0)
%!  rho = AnalyticSensitivityConstSNRChiSqr(paNt,pd,Ns,nu);
%!  TdataSeg = 86400;
%!  depthInv = 5/2 .* rho .* TdataSeg.^(-1/2);
%!  depth = 1 ./ depthInv;
%!  depth0 = depth0 * 1.527;
%!  assert(abs(depth - depth0) < 0.2 * abs(depth0));
## - tests
%!test __test_sens_chisqr(0.01,0.05,2,1,17.9751)
%!test __test_sens_chisqr(0.01,0.05,2,100,80.4602)
%!test __test_sens_chisqr(0.01,0.05,2,10000,269.687)
%!test __test_sens_chisqr(0.01,0.05,4,1,16.429)
%!test __test_sens_chisqr(0.01,0.05,4,100,68.8944)
%!test __test_sens_chisqr(0.01,0.05,4,10000,227.24)
%!test __test_sens_chisqr(0.01,0.1,2,1,20.5666)
%!test __test_sens_chisqr(0.01,0.1,2,100,89.3568)
%!test __test_sens_chisqr(0.01,0.1,2,10000,297.123)
%!test __test_sens_chisqr(0.01,0.1,4,1,18.6925)
%!test __test_sens_chisqr(0.01,0.1,4,100,76.3345)
%!test __test_sens_chisqr(0.01,0.1,4,10000,250.28)
%!test __test_sens_chisqr(1e-07,0.05,2,1,10.5687)
%!test __test_sens_chisqr(1e-07,0.05,2,100,55.9013)
%!test __test_sens_chisqr(1e-07,0.05,2,10000,193.411)
%!test __test_sens_chisqr(1e-07,0.05,4,1,10.0133)
%!test __test_sens_chisqr(1e-07,0.05,4,100,48.3342)
%!test __test_sens_chisqr(1e-07,0.05,4,10000,163.153)
%!test __test_sens_chisqr(1e-07,0.1,2,1,11.589)
%!test __test_sens_chisqr(1e-07,0.1,2,100,60.1536)
%!test __test_sens_chisqr(1e-07,0.1,2,10000,206.551)
%!test __test_sens_chisqr(1e-07,0.1,4,1,10.9521)
%!test __test_sens_chisqr(1e-07,0.1,4,100,51.9024)
%!test __test_sens_chisqr(1e-07,0.1,4,10000,174.182)
%!test __test_sens_chisqr(1e-12,0.05,2,1,8.29336)
%!test __test_sens_chisqr(1e-12,0.05,2,100,47.5524)
%!test __test_sens_chisqr(1e-12,0.05,2,10000,168.007)
%!test __test_sens_chisqr(1e-12,0.05,4,1,7.96925)
%!test __test_sens_chisqr(1e-12,0.05,4,100,41.3759)
%!test __test_sens_chisqr(1e-12,0.05,4,10000,141.831)
%!test __test_sens_chisqr(1e-12,0.1,2,1,8.97247)
%!test __test_sens_chisqr(1e-12,0.1,2,100,50.7244)
%!test __test_sens_chisqr(1e-12,0.1,2,10000,177.979)
%!test __test_sens_chisqr(1e-12,0.1,4,1,8.60838)
%!test __test_sens_chisqr(1e-12,0.1,4,100,44.0545)
%!test __test_sens_chisqr(1e-12,0.1,4,10000,150.205)
