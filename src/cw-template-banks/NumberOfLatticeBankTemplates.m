## Copyright (C) 2014, 2017 Karl Wette
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

## Estimate the number of templates in a lattice template bank.
## Usage:
##   N = NumberOfLatticeBankTemplates("opt", val, ...)
## where
##   N              = Number of templates
## Options:
##   "lattice"      : Type of lattice; see LatticeNormalizedThickness()
##   "metric"       : Parameter-space metric
##   "max_mismatch" : Maximum metric mismatch
##   "param_vol"    : Parameter space volume

function N = NumberOfLatticeBankTemplates(varargin)

  ## parse options
  parseOptions(varargin,
               {"lattice", "char"},
               {"metric", "symmetric"},
               {"max_mismatch", "real,strictpos,scalar"},
               {"param_vol", "real,strictpos,scalar"},
               []);
  assert(issquare(metric));
  dim = size(metric, 1);

  ## calculate determinant of metric
  det_metric = det(metric);

  ## get normalised lattice thickness
  thickness = LatticeNormalizedThickness(dim, lattice);

  ## return number of templates (e.g. Eq. 24 of Prix 2007, CQG 24 S481)
  N = thickness * max_mismatch^(-0.5*dim) * sqrt(det_metric) * param_vol;

endfunction
