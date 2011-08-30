## Copyright (C) 2010 Karl Wette
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

## Compute the cumulative density of the
## non-central chi-squared distribution.
## Syntax:
##   cdf = ChiSquare_cdf(x, k, lambda)
## where:
##   x      = value of the non-central
##            chi-squared variable
##   k      = number of degrees of freedom
##   lambda = non-centrality parameter

function p = ChiSquare_cdf(x, k, lambda)

  ## check for common size input
  [errcode, k, lambda, x] = common_size(k, lambda, x);
  if errcode > 0
    error("All input arguments must be either of common size or scalars");
  endif

  ## flatten input after saving sizes
  siz = size(k);
  k = k(:)';
  lambda = lambda(:)';
  x = x(:)';

  ## allocate result matrix
  p = zeros(1, prod(siz));

  ## if lambda = 0, return value of central chi-squared distribution
  ii = (lambda > 0);
  if any(!ii)
    p(!ii) = chi2cdf(x(!ii), k(!ii));
  endif

  ## if lambda > 0, return value of non-central chi-squared distribution
  if any(ii)

    ## half of lambda
    hlamb = lambda / 2;

    ## compute 10 series elements at a time
    Nstep = 10;

    ## set up matrices to compute series of non-central chi-squared distribution
    ## rows are elements of the series, columns map to input values where ii==1
    N = (0:Nstep-1)'(:, ones(size(find(ii))));
    k = k(ones(Nstep,1), ii);
    hlamb = hlamb(ones(Nstep,1), ii);
    x = x(ones(Nstep,1), ii);
    pN = zeros(1, size(N, 2));

    ## add up series
    err = inf;
    do

      ## compute element of series of non-central chi-squared distribution
      pN = sum(poisspdf(N, hlamb) .* chi2cdf(x, k + 2*N), 1);

      ## if this is not the first iteration, see if we should stop
      if N(1,1) > 0
	Nmax = N(end,1);
	err = max(reshape(abs(pN) ./ abs(p(ii)), 1, []));
      endif

      ## add computed elements to total, and increment element indices
      p(ii) += pN;
      N += Nstep;

      ## loop until maximum error is small enough
    until err <= 1e-4

  endif

  ## reshape output to original size of input
  p = reshape(p, siz);

endfunction
