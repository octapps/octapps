## Copyright (C) 2006 Reinhard Prix
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

## Compute the probability density function of the
## non-central chi^2 distribution.
## Syntax:
##   p  = ChiSquare_pdf(x, k, lambda)
## where:
##   x      = value of the non-central chi^2 variable
##   k      = number of degrees of freedom
##   lambda = non-centrality parameter

function p = ChiSquare_pdf(x, k, lambda)

  ## check for common size input
  if !exist("lambda")
    lambda = 0;
  endif
  [cserr, x, k, lambda] = common_size(x, k, lambda);
  if cserr > 0
    error("All input arguments must be either of common size or scalars");
  endif
  p = zeros(size(x));

  ## for zero lambda, compute the central chi^2 PDF
  ii = (lambda > 0);
  if any(!ii(:))
    p(!ii) = chi2pdf(x(!ii), k(!ii));
  endif

  ## otherwise compute the non-central chi^2 PDF
  if any(ii(:))
    p(ii) = e.^(-0.5 .* (x(ii) + lambda(ii)) ) .* x(ii).^((k(ii)-1)/2) .* \
        sqrt(lambda(ii)) .* besseli(k(ii)/2 - 1, sqrt( x(ii) .* lambda(ii) ) ) ./ ( 2 .* (x(ii) .* lambda(ii)).^(k(ii)/4) );
    if ( isnan (p(ii)) )
      error ("ChiSquare_pdf(): Got NaN for x=%g, k=%d, lambda=%g\n", x(ii), k(ii), lambda(ii) );
    endif
  endif

endfunction
