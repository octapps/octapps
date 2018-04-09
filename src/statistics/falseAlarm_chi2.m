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
## @deftypefn {Function File} {@var{fA} =} falseAlarm_chi2 ( @var{thresh}, @var{dof} )
##
## compute the false-alarm probability for given threshold @var{thresh}'
## for a (central) chi-squared distribution with @var{dof} degrees-of-freedom
##
## @end deftypefn

function fA = falseAlarm_chi2 ( thresh, dof )

  eta = ChiSquare_cdf( thresh, dof, 0 );
  fA = 1 - eta;

endfunction

%!assert(falseAlarm_chi2([23.513 28.473 33.377 38.442 43.258 48.051 52.827 57.590 62.341 67.082 71.816 76.539 81.257 85.968 90.675 95.376 100.074], 4), logspace(-4, -20, 17), 1e-3)
