## Copyright (C) 2006 Reinhard Prix
## Copyright (C) 2013 Karl Wette
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
## @deftypefn {Function File} {@var{y} =} erfcinv_asym ( @var{X} )
## Compute the inverse complementary error function, i.e., @var{Y} such that
##
## @example
## erfc(@var{y}) == @var{x}
## @end example
##
## An asymptotic expression is used for small @var{X}.
## @end deftypefn

function y = erfcinv_asym(x)

  ## initialise output
  y = zeros(size(x));

  ## for large x, use erfinv
  ii = (x < 1e-14);
  if any(!ii(:))
    y(!ii) = erfinv( 1 - x(!ii) );
  endif

  ## use asymptotic expression for small x:
  ## from http://dlmf.nist.gov/7.17#iii
  if any(ii(:))
    x = x(ii(:));
    u = -2 ./ log(pi .* x.^2 .* log(1./x));
    v = log(log(1./x)) - 2 + log(pi);
    a2 = (1/8) .* v;
    a3 = (-1/32) .* (v.^2 + 6.*v - 6);
    a4 = (1/384) .* (4.*v.^3 + 27.*v.^2 + 108.*v - 300);
    y(ii) = u.^(-1/2) + a2.*u.^(3/2) + a3.*u.^(5/2) + a4.*u.^(7/2);
  endif

endfunction

%!assert(erfcinv_asym(logspace(-4, -20, 17)), [2.751 3.123 3.459 3.767 4.052 4.320 4.573 4.813 5.042 5.261 5.473 5.676 5.872 6.063 6.247 6.427 6.602], 1e-3)
