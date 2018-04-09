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
## @deftypefn {Function File} { [ @var{rho}, @var{tms} ] =} AnalyticSensitivitySNRExpr ( @var{za}, @var{pd}, @var{Ns}, @var{nu} )
##
## Implements an expression used in analytic sensitivity estimation
## for a chi^2 detection statistic
##
## @heading Arguments
##
## @table @var
## @item rho
## detectable r.m.s. SNR (per segment)
##
## @item tms
## terms of the second factor of the expression
##
## @item za
## normalised false alarm threshold
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
  q = sqrt(2).*erfcinv_asym(2.*pd);

  ## terms of the second factor of the expression
  tms = cell(1,3);
  tms{1} = za;
  tms{2} = q .* sqrt(1 + za.*sqrt(8./(Ns*nu)));
  tms{3} = q.^2 .* sqrt(2./(Ns*nu));

  ## sensitivity SNR
  rho = (2*nu./Ns).^0.25 .* sqrt(tms{1}+tms{2}+tms{3});

endfunction

%!assert(AnalyticSensitivitySNRExpr(0.01, 0.1, 100, 4), 0.6312, 1e-3)
