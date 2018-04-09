## Copyright (C) 2011 Reinhard Prix
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
## @deftypefn {Function File} {@var{thresh} =} invFalseAlarm_chi2 ( @var{fA}, @var{dof} )
##
## compute the threshold on a central chi^2 distribution with @var{dof}
## degrees of freedom, corresponding to a false-alarm probability
## of @var{fA}
##
## @end deftypefn

function thresh = invFalseAlarm_chi2 ( fA, dof )

  ## make inputs common size
  [err, fA, dof] = common_size( fA, dof );
  if err > 0
    error( "%s: fA and dof are not of common size", funcName );
  endif
  thresh = zeros(size(fA));

  ## large N, low-fA case better handled by asymptotic expression
  ii = (fA < 1e-6) | (dof > 1000);
  thresh(ii) = invFalseAlarm_chi2_asym( fA(ii), dof(ii) );

  ## otherwise use Octave function
  thresh(!ii) = chi2inv( 1 - fA(!ii), dof(!ii) );

endfunction

%!assert(invFalseAlarm_chi2(logspace(-4, -20, 17), 4), [23.513 28.473 33.377 38.442 43.258 48.051 52.827 57.590 62.341 67.082 71.816 76.539 81.257 85.968 90.675 95.376 100.074], 1e-3)
