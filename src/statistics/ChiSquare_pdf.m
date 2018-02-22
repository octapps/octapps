## Copyright (C) 2006 Reinhard Prix
## Copyright (C) 2011 Karl Wette
## Copyright (C) 2017 Christoph Dreissigacker
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

function p = ChiSquare_pdf(x, k, lambda=0)

  ## check for common size input
  [cserr, x, k, lambda] = common_size(x, k, lambda);
  if cserr > 0
    error("All input arguments must be either of common size or scalars");
  endif
  p = NaN(size(x));

  ## deal with special input values +-inf
  ii = isinf(x);
  if any(ii(:))
    p(ii) = 0;
  endif

  ## compute the central chi^2 PDF for special case lambda==0
  ii = !isfinite(p) & (lambda == 0);
  if any(ii(:))
    p(ii) = chi2pdf(x(ii), k(ii));
  endif

  ## compute the non-central chi^2 PDF for special case x==0
  ii = !isfinite(p) & (x == 0);
  if any(ii(:))
    p(ii) = 0.5 .* exp( -0.5.*lambda(ii) ) ./ gamma(k(ii)./2);
  endif

  ## compute the non-central chi^2 PDF in the general case
  ii = !isfinite(p);
  normal_approx = 0;
  if any(ii(:))

     ## compute terms in logarithm of PDF
     logp_t1 = logp_t2 = nu = z = logp_t3 = logp_ts = zeros(size(p));
     logp_t1(ii) = -log(2) - 0.5.*( x(ii) + lambda(ii) );
     logp_t2(ii) = (k(ii)./4 - 0.5).*log( x(ii) ./ lambda(ii) );
     nu(ii) = k(ii)./2 - 1;
     z(ii) = sqrt(x(ii) .* lambda(ii));
     logp_t3(ii) = log( besseli( nu(ii), z(ii) ) );
     logp_ts(ii) = logp_t1(ii) + logp_t2(ii) + logp_t3(ii);

     ## compute PDF
     p(ii) = exp( logp_ts(ii) );

     ## approximate by normal distribution if chi^2 failed
     kk = ii & ( !isfinite(logp_ts) | (logp_ts > 0) );
     if any(kk)
       p(kk) = normpdf(x(kk), k(kk) + lambda(kk), sqrt( 2.* ( k(kk) + 2.*lambda(kk) ) ));
       normal_approx = 1;
     endif

  endif

  ## check for valid probabilities
  ii = !isfinite(p) | (p < 0) | (p > 1);
  for i = find(ii(:)')
    warning( "%s: got p=%g for x=%g, k=%g, lambda=%g, normal_approx=%d", funcName, p(i), x(i), k(i), lambda(i), normal_approx );
  endfor
  if any(ii(:))
    error( "%s: got invalid probabilities for some inputs", funcName );
  endif

endfunction


%!assert(ChiSquare_pdf(10^-2, 10^-2, 1), 0.44224, 1e-3)
%!assert(ChiSquare_pdf(10^+2, 10^+2, 2), 0.027895, 1e-3)
%!assert(ChiSquare_pdf(10^10, 10^10, 3), 2.8209e-06, 1e-3)
%!assert(ChiSquare_pdf(10^30, 10^30, 4), 2.8209e-16, 1e-3)
