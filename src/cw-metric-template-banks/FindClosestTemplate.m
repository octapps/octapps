## Copyright (C) 2014 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{closest} =} FindClosestTemplate ( @var{points}, @var{metric}, @var{max_mismatch}, @var{lattice} )
##
## Given a set of @var{points}, find the @var{closest} template to each in a 'virtual'
## lattice template bank, constructed using a given @var{metric} and maximum mismatch.
##
## @heading Arguments
##
## @table @var
## @item points
## set of @var{points} (in columns) to find @var{closest} template
##
## @item metric
## parameter-space @var{metric} associated with @var{points}'
##
## @item max_mismatch
## maximum mismatch of @var{lattice} template bank
##
## @item lattice
## type of @var{lattice} to use; see @command{LatticeFindClosestPoint()}
##
## @item closest
## closest template to each point
##
## @end table
##
## @end deftypefn

function closest = FindClosestTemplate(points, metric, max_mismatch, lattice)

  ## check input
  assert(ismatrix(points));
  assert(issymmetric(metric) > 0);
  assert(size(points, 1) == size(metric, 1));
  assert(isscalar(max_mismatch) && max_mismatch > 0);
  assert(ischar(lattice));

  ## get lattice covering radius
  lattice_R = LatticeCoveringRadius(size(metric, 1), lattice);

  ## diagonally normalise metric
  [D_metric, DN_metric, IDN_metric] = DiagonalNormaliseMetric(metric);

  ## compute Cholesky decomposition of metric
  tolattice = chol(D_metric) * IDN_metric;

  ## re-scale to account for covering radius and maximum mismatch
  tolattice *= lattice_R / sqrt(max_mismatch);

  ## find closest template in lattice space
  closest = tolattice \ LatticeFindClosestPoint(tolattice * points, lattice);

endfunction

%!test
%!  x = unifrnd(-10, 10, [3,100]);
%!  metric = [7,3,5; 3,6,2; 5,2,5];
%!  max_mismatch = 0.4;
%!  dx = x - FindClosestTemplate(x, metric, max_mismatch, "Zn");
%!  assert(dot(dx, metric * dx) <= max_mismatch);
%!test
%!  x = unifrnd(-10, 10, [3,100]);
%!  metric = [7,3,5; 3,6,2; 5,2,5];
%!  max_mismatch = 0.4;
%!  dx = x - FindClosestTemplate(x, metric, max_mismatch, "Ans");
%!  assert(dot(dx, metric * dx) <= max_mismatch);
