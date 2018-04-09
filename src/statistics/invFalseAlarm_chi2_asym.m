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
## @deftypefn {Function File} {@var{sa} =} invFalseAlarm_chi2_asym ( @var{pa}, @var{k} )
##
## Calculate the threshold of a central chi^2 distribution which gives
## a certain false alarm probability. Uses an analytic, asymptotic
## inversion of the chi^2 CDF that is accurate for very small
## false alarm probabilities and very large degrees of freedom.
##
## @heading Arguments
##
## @table @var
## @item sa
## threshold
##
## @item pa
## false alarm probability
##
## @item k
## degrees of freedom of the chi^2 distribution
##
## @end table
##
## @end deftypefn

function sa = invFalseAlarm_chi2_asym(pa, k)

  ## make input and output the same size
  [err, pa, k] = common_size(pa, k);
  if err > 0
    error("%s: pa and k are not of common size", funcName);
  endif
  assert(all(pa(:) > 0) && all(k(:) > 0));

  ## calculate threshold
  eta0 = 2 ./ sqrt(k) .* erfcinv_asym(2*pa);
  eta = eta0 + 2 ./ (k .* eta0) .* log(eta0 ./ (lambdaFunction(eta0) - 1));
  sa = k .* lambdaFunction(eta);

endfunction

function lambda = lambdaFunction(x)

  ## lambda1 function
  ii = (x <= 4);
  lambda1 = zeros(size(x));
  lambda1(ii) = 1 + x(ii) + x(ii).^2./3 + x(ii).^3./36 - x(ii).^4./270;

  ## lambda2 function
  jj = (2 <= x);
  lambda2 = y = zeros(size(x));
  y(jj) = 1 + x(jj).^2./2;
  lambda2(jj) = y(jj) + (1 + y(jj).^(-1) + y(jj).^(-2)) .* log(y(jj));

  ## lambda function
  lambda = g = zeros(size(x));
  lambda(!jj) = lambda1(!jj);
  lambda(!ii) = lambda2(!ii);
  kk = ii & jj;
  g(kk) = tanh(5.*(x(kk) - 3));
  lambda(kk) = 0.5.*((1 - g(kk)).*lambda1(kk) + (1 + g(kk)).*lambda2(kk));

endfunction

%!assert(invFalseAlarm_chi2_asym(logspace(-4, -20, 17), 4), [23.467 28.411 33.557 38.442 43.258 48.051 52.827 57.590 62.341 67.082 71.816 76.539 81.257 85.968 90.675 95.376 100.074], 1e-3)
