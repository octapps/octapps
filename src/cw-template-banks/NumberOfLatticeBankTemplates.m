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

## Estimate the number of templates in a lattice template bank.
## Usage:
##   N = NumberOfLatticeBankTemplates("opt", val, ...)
## where
##   N              = Number of templates
## Options:
##   "lattice"      : Type of lattice; see LatticeNormalizedThickness()
##   "metric"       : Parameter-space metric
##   "max_mismatch" : Maximum metric mismatch
##   "param_space"  : Parameter space specifier(s), may be:
##                      [band...]: Fixed-size positive parameter range(s)
##                      "rssky": Special specifier for the reduced supersky metric sky
##                    Number of specifiers must match dimensionality of metric
##   "padding"      : Whether to account for boundary padding [default: true]

function N = NumberOfLatticeBankTemplates(varargin)

  ## parse options
  parseOptions(varargin,
               {"lattice", "char"},
               {"metric", "symmetric"},
               {"max_mismatch", "real,strictpos,scalar"},
               {"param_space", "cell,vector"},
               {"padding", "logical,scalar", true},
               []);

  ## calculate bounding box of metric
  bbox_metric = reshape(metricBoundingBox(metric, max_mismatch), [], 1);

  ## if not taking boundary padding into account, zero bounding box
  if !padding
    bbox_metric = zeros(size(bbox_metric));
  endif

  ## loop over parameter-space specifiers
  vol = 1;
  empty_dim = false(size(metric, 1));
  n = 0;
  for i = 1:length(param_space)

    if ischar(param_space{i})

      ## switch on special parameter-space specifiers
      switch param_space{i}

        case "rssky"
          ## volume of reduced super-sky metric sky parameter space:
          ## two unit disks for each hemisphere, plus boundary padding
          vol *= 2 * (pi + 4*bbox_metric(n+2) + bbox_metric(n+1)*bbox_metric(n+2));
          n += 2;

        otherwise
          error("%s: unknown special parameter-space specifier '%s'", funcName, param_space{i});

      endswitch

    elseif isvector(param_space{i})

      ## get fixed-size positive parameter ranges in at least one dimension
      v = reshape(param_space{i}, [], 1);
      assert(!isempty(v), "%s: parameter-space specifier #%i must be non-empty", funcName, i);
      assert(all(v >= 0), "%s: parameter-space specifier #%i must have positive elements", funcName, i);

      ## indicate empty parameter ranges
      jj = (v > 0);
      empty_dim(n+find(!jj)) = true;

      ## add boundary padding to non-zero ranges
      v(jj) += bbox_metric(n+find(jj));

      ## add to volume
      vol *= prod(v(jj));
      n += length(v);

    else
      error("%s: unknown parameter-space specifier #%i", funcName, i);

    endif
  endfor

  ## check that there are enough parameter-space specifiers
  if n != size(metric, 1)
    error("%s: number of parameter-space specifiers %i != metric dimension %i", funcName, n, size(metric, 1));
  endif

  ## remove empty parameter space dimensions
  metric(empty_dim, :) = [];
  metric(:, empty_dim) = [];
  dim = size(metric, 1);

  ## calculate determinant of metric
  det_metric = det(metric);

  ## get normalised lattice thickness
  thickness = LatticeNormalizedThickness(dim, lattice);

  ## return number of templates (e.g. Eq. 24 of Prix 2007, CQG 24 S481)
  N = thickness * max_mismatch^(-0.5*dim) * sqrt(det_metric) * vol;

endfunction
