## Copyright (C) 2012 Reinhard Prix
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
## @deftypefn {Function File} {@var{gOut_ij} =} projectMetric ( @var{g_ij}, @var{c} = 1 )
##
## project out metric dimension @var{c} from the input n x n metric @var{g_ij},
## by projecting onto the subspace orthogonal to the coordinate-axis of @var{c}, namely
## gOut_ij = @var{g_ij} - ( g_ic * g_jc / g_cc )
##
## Returns a 'projected' n x n metric, where the projected-out dimension @var{c} is replaced
## by zeros, consistent with the behavior of @command{XLALProjectMetric()}
##
## @end deftypefn

function gOut_ij = projectMetric ( g_ij, c=1 )

  assert ( issymmetric ( g_ij ) > 0, "Input metric 'g_ij' must be a symmetric square matrix" );

  n = columns ( g_ij );

  gOut_ij = zeros ( n, n );

  for i = 1:n
    for j = 1:n
      if ( i == c || j == c )
        gOut_ij(i, j) = 0;      ## exact result to avoid roundoff issues
      else
        gOut_ij( i, j ) = g_ij( i, j ) - g_ij(c, i) * g_ij ( c, j ) / g_ij ( c, c );
      endif
    endfor
  endfor

  return;

endfunction

%!assert(projectMetric(hadamard(4)), -[0,0,0,0;0,2,0,2;0,0,2,2;0,2,2,0], 1e-3)
