## Copyright (C) 2012 Karl Wette
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

## Diagonally normalise a metric.
## Usage:
##   [metric, dnorm, invdnorm] = DiagonalNormaliseMetric(metric, ["tolerant"])
## where:
##   metric   = metric
##   dnorm    = diagonal normalisation coefficients
##   invdnorm = inverse of diagonal normalisation coefficients
## If "tolerant" option is given, tolerate zero or negative diagonal elements.

function [metric, dnorm, invdnorm] = DiagonalNormaliseMetric(metric, tolerant="")

  ## check input
  assert(ismatrix(metric) && issquare(metric));
  diagmetric = diag(metric);
  if !strcmp(tolerant, "tolerant")
    assert(all(diagmetric > 0.0));
  endif

  ## compute diagonal normalisation coefficients
  dnorm = diag(1.0 ./ sqrt(abs(diagmetric)));
  dnorm(!isfinite(dnorm)) = 1.0;
  invdnorm = diag(1.0 ./ diag(dnorm));

  ## diagonally normalise metric
  metric = dnorm' * metric * dnorm;

endfunction
