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

## Calculate sensitivty in terms of the root-mean-square SNR for
## a population of constant-SNR signals, and for a chi^2 detection
## statistic
## Syntax:
##   rhob = AnalyticSensitivityConstSNRChiSqr(paNt, pd, Ns, nu)
## where:
##   rhob = detectable r.m.s. SNR (per segment)
##   paNt = false alarm probability (per template)
##   pd   = false dismissal probability
##   Ns   = number of segments
##   nu   = degrees of freedom of the chi^2 statistic

function rhob = AnalyticSensitivityConstSNRChiSqr(paNt, pd, Ns, nu)
  
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
  sa = invFalseAlarm_chi2_asym(paNt, Ns*nu);
  za = (sa - Ns*nu) ./ sqrt(2*Ns*nu);

  ## sensitivity SNR
  rhob = AnalyticSensitivitySNRExpr(za, pd, Ns, nu);

endfunction
