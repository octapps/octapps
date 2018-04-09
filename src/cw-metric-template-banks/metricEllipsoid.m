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
## @deftypefn {Function File} {function [ @var{xx}, @var{yy}, @var{zz} ] =} metricEllipsoid ( @var{gij}, @var{mismatch}, @var{Nsteps}=20, @var{method}=1 )
##
## return a metric iso-@var{mismatch} ellipsoid for given metric @var{gij} and @var{mismatch}, using
## '@var{Nsteps} points per surface direction.
## The function can generate both 2D or 3D ellipses, depending on the input dimension of @var{gij}.
## using either @var{method}=1: Cholesky, or @var{method}=2: Eigenvectors
##
## The output in the 3D case is a meshgrid, which can be plotted using @command{mesh()}, @command{surface()}, ...
##
## The output in the 2D case lies in the x-y plane, @var{zz} is returned as zeros
##
## @heading Note
##
## this function agrees with and supercedes the older @command{calcMetric2DEllipse()} and @command{plotMetricEllipse()}
## @end deftypefn

function [xx, yy, zz] = metricEllipsoid ( gij, mismatch, Nsteps=20, method=1 )
  dimgij = size(gij);
  assert ( ( dimgij == [2,2] ) || dimgij == [3,3], "%s: Metric 'gij' needs to be 2x2 or 3x3, got %d x %d\n", funcName, dimgij(1), dimgij(2) );
  assert ( issymmetric ( gij ) > 0, "%s: Metric 'gij' needs to be a symmetric matrix!\n", funcName );

  assert( mismatch > 0, "%s: mismatch must be strictly positive!", funcName );

  nDim = dimgij(1);

  ## sample the unit sphere/circle
  switch ( nDim )
    case 2
      [xx, yy] = unitCircle ( Nsteps );
      zz = zeros (size ( xx ) );
    case 3
      [xx, yy, zz] = unitSphere3D ( Nsteps );
    otherwise
      error ("Invalid 'nDim' = %d, allowed are '2' or '3'\n", nDim );
  endswitch

  ## scale circle to mismatch radius
  r = sqrt(mismatch);
  xx *= r; yy *= r; zz *= r;

  ## decompose metric
  switch ( method )
    case 1              ## Cholesky decompose the metric
      R = chol ( gij );
      Rinv = inv ( R );
    case 2              ## Eigenvalue-decompose metric
      [ev, ew] = eig ( gij );
      dd = (ev * sqrt(ew))';    ## such that gij = trans(d) * d
      Rinv = inv ( dd );
    otherwise
      error ("Invalid method = %d, supported '1'=Cholesky, '2'=eigenvalues\n", method );
  endswitch

  for i = 1:length( xx(:) )

    uui = [ xx(i); yy(i); zz(i) ];      ## one point on the 'metric sphere'

    vvi = Rinv * uui(1:nDim);           ## transform this point from sphere onto metric ellipsoid

    xx(i) = vvi(1); yy(i) = vvi(2);
    if ( nDim == 3 ) zz(i) = vvi(3); endif

  endfor

  return;

endfunction ## metricEllipsoid()

## ----- helper functions for metricEllipsoid() --------------------

function [xx, yy] = unitCircle ( Nsteps )
  ## return 'Nsteps' points drawn isotropically on a unit circle,
  ## returns matrix of dimension 'Nsteps x 2'

  alphas = linspace ( 0, 2*pi, Nsteps );

  xx = cos(alphas);
  yy = sin(alphas);

  return;
endfunction ## unitCircle()

function [xx, yy, zz] = unitSphere3D ( Nsteps )
  ## return points drawn quasi-isotropically on a unit sphere, using Nsteps steps per direction

  deltas = linspace ( -pi/2, pi/2, Nsteps );
  alphas = linspace ( 0, 2*pi, Nsteps );

  [aa, dd] = meshgrid ( alphas, deltas );

  xx = cos(aa) .* cos(dd);
  yy = sin(aa) .* cos(dd);
  zz = sin(dd);

  return;
endfunction

%!test
%!  [xx, yy, zz] = metricEllipsoid([4,1;1,1], 0.25, 4);
%!  assert(xx, [0.25, -0.25, 0, 0.25], 1e-3);
%!  assert(yy, [0.0, 0.5, -0.5, 0.0], 1e-3);
%!  assert(zz, [0.0, 0.0, 0.0, 0.0], 1e-3);
