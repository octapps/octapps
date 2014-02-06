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

## Given a set of points, find the closest template to each in a 'virtual'
## lattice template bank, constructed using a given metric and maximum mismatch.
## Usage:
##   closest = FindClosestTemplate(points, metric, max_mismatch, lattice)
## where:
##   points       = set of points (in columns) to find closest template
##   metric       = parameter-space metric associated with 'points'
##   max_mismatch = maximum mismatch of lattice template bank
##   lattice      = type of lattice to use; see LatticeFindClosestPoint()
##   closest      = closest template to each point

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
  [D_metric, DN_metric] = DiagonalNormaliseMetric(metric);

  ## compute Cholesky decomposition of metric
  tolattice = chol(D_metric) * inv(DN_metric);

  ## re-scale to account for covering radius and maximum mismatch
  tolattice *= lattice_R / sqrt(max_mismatch);

  ## find closest template in lattice space
  closest = tolattice \ LatticeFindClosestPoint(tolattice * points, lattice);

endfunction
