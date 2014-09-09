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

## Implements an expression used in analytic sensitivity estimation
## for a chi^2 detection statistic
## Syntax:
##   [rho,tms] = AnalyticSensitivitySNRExpr(za, pd, Ns, nu)
## where:
##   rho = detectable r.m.s. SNR (per segment)
##   tms = terms of the second factor of the expression
##   za  = normalised false alarm threshold
##   pd  = false dismissal probability
##   Ns  = number of segments
##   nu  = degrees of freedom per segment

function [rho,tms] = AnalyticSensitivitySNRExpr(za, pd, Ns, nu)

  ## check input
  assert(all(pd > 0));
  assert(all(Ns > 0));
  assert(isscalar(nu));

  ## make sure za, pd, and Ns are the same size
  [cserr, za, pd, Ns] = common_size(za, pd, Ns);
  if cserr > 0
    error("%s: za, pd, and Ns are not of common size", funcName);
  endif

  ## quantile of false dismissal probability
  q = sqrt(2).*erfcinv(2.*pd);

  ## terms of the second factor of the expression
  tms = cell(1,3);
  tms{1} = za;
  tms{2} = q .* sqrt(1 + za.*sqrt(8./(Ns*nu)));
  tms{3} = q.^2 .* sqrt(2./(Ns*nu));

  ## sensitivity SNR
  rho = (2*nu./Ns).^0.25 .* sqrt(tms{1}+tms{2}+tms{3});

endfunction
