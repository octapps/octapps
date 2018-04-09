## Copyright (C) 2012 Karl Wette
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
## @deftypefn {Function File} { [ @var{xcross}, @var{mucross} ] =} metricEllipseCrossSections ( @var{x}, @var{mu}, @var{metric}, @var{cross} )
##
## Return the ellipse centers and mismatches for a template bank @var{cross} section.
##
## @heading Arguments
##
## @table @var
## @item xcross
## Centers of @var{metric} ellipses in the @var{cross} section.
##
## @item mucross
## Mismatches of @var{metric} ellipses in the @var{cross} section.
##
## @item x
## Template bank to find @var{cross} section of.
##
## @item mu
## Maximum mismatch of templates.
##
## @item metric
## Parameter-space @var{metric}.
##
## @item cross
## NAs indicate dimensions to @var{cross} section (only 2 allowed),
## otherwise give values of @var{cross} section in other dimensions
##
## @end table
##
## @end deftypefn

function [xcross, mucross] = metricEllipseCrossSections(x, mu, metric, cross)

  ## check input
  assert(ismatrix(x));
  assert(isrow(mu));
  if isscalar(mu)
    mu = mu * ones(1, size(x, 2));
  else
    assert(length(mu) == size(x, 2));
  endif
  assert(issymmetric(metric));
  assert(size(metric, 1) == size(x, 1));
  assert(iscolumn(cross));
  assert(length(cross) == size(metric, 1));

  ## get indices of non-cross section dimensions
  crossii = find(isna(cross));
  if length(crossii) != 2
    error("%s: can only plot 2 dimensions, i.e. 'cross' can only contain 2 NAs", funcName);
  endif
  noncrossii = setdiff(1:size(metric, 1), crossii);

  ## diagonally normalise metric
  [M, D, iD] = DiagonalNormaliseMetric(metric);

  ## partition metric into cross section and non-cross section blocks
  Mcross = M(crossii, crossii);
  Mmixed = M(crossii, noncrossii);
  Mnoncross = M(noncrossii, noncrossii);

  ## calculate offsets from cross section plane in non-cross section dimensions
  dxnoncross = iD(noncrossii, noncrossii) * (x(noncrossii, :) - cross(noncrossii, ones(1, size(x, 2))));

  ## calculate centre offsets of metric ellipses in cross section plane
  dxcross = Mcross \ Mmixed * dxnoncross;

  ## calculate effective mismatches in cross section plane
  mucross = mu - dot(dxnoncross, Mnoncross * dxnoncross, 1) + dot(dxcross, Mcross * dxcross, 1);

  ## get indices of metric ellipses which intersect cross section plane
  jj = find(mucross > 0.0);

  ## calculate metric ellipse centres in cross section plane
  xcross = x(crossii, jj) + D(crossii, crossii) * dxcross(:, jj);
  mucross = mucross(jj);

  ## return only unique points
  [xcross, xcrossjj] = unique(xcross', "rows");
  xcross = xcross';
  mucross = mucross(xcrossjj);

endfunction

%!test
%!  [xcross,mucross] = metricEllipseCrossSections([1;2;3], 0.5, [6,4,4;4,4,2;4,2,1], [NA;2;NA]);
%!  assert(xcross, [1;3], 1e-3);
%!  assert(mucross, 0.5, 1e-3);
