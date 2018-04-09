## Copyright (C) 2016, 2018 Reinhard Prix
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
## @deftypefn {Function File} {} function p ( @var{x} ) = maxChi2FromNdraws_pdf ( @var{x}, @var{Ndraws}, @var{dof = 4} )
##
## Probability density (pdf) for the maximum out of @var{Ndraws} independent draws from a
## (central) chi2 distribution with @var{dof} degrees of freedom.
##
## Return p(@var{x}): pdf over (vector of) maxChi2 statistics values @var{x}'
##
## @end deftypefn

function p = maxChi2FromNdraws_pdf ( x, Ndraws, dof = 4 )

  assert ( isscalar ( Ndraws ) );
  assert ( isscalar ( dof ) );

  p = NaN( size(x) );

  ## deal with special input values +-inf
  ii = isinf(x);
  if any(ii(:))
    p(ii) = 0;
  endif

  ii = !isfinite(p);
  if any(ii(:))
    logp = log(Ndraws) + log(ChiSquare_pdf ( x(ii), dof, lambda=0)) +  (Ndraws-1) * log ( ChiSquare_cdf( x(ii), dof, lambda=0 ) );
    p(ii) = e.^logp;
  endif

  return;
endfunction
%!test
%! max2F = linspace ( 30, 60, 100 );
%! p = maxChi2FromNdraws_pdf ( max2F, 2e7, dof=4 );
%! dFmax = mean(diff(max2F));
%! Emax2F = sum ( max2F .* p ) * dFmax;
%! assert ( Emax2F, 40.901, -1e-3 );    ## 1e-3 relative tolerance
