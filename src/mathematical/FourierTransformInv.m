## Copyright (C) 2008 Reinhard Prix
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
## @deftypefn {Function File} {@var{timeSeries} =} FourierTransformInv ( @var{fk}, @var{xk}, @var{oversampleby} )
##
## Computes inverse Fourier-transform of input frequency-series with
## frequency steps @var{fk} and data-points @var{xk}. This function complies with
## the LSC convention for inverse Fourier-transforms, i.e.
## xi(t) = df * sum_@{k=0@}^@{n-1@} x_k * e^@{2pi i f_k t@}
##
## The optional argument @var{oversampleby} specifies an INTEGER
## factor to oversample the FFT by
##
## @end deftypefn

function timeSeries = FourierTransformInv ( fk, xk, oversampleby = 1 )

  ## ----- input sanity checks ----------
  assert ( isvector ( fk ), "Frequency bins 'fk' must be a 1D vector\n");
  assert ( ismatrix(xk) );
  assert ( isscalar(oversampleby) && mod(oversampleby,1)==0 && oversampleby >= 1 );

  df = mean ( diff ( fk ) );
  N = length(fk);

  if ( isvector(xk) )
    Nbins = length ( xk );
    xk = reshape ( xk, 1, Nbins );
  else
    [Nseries, Nbins] = size ( xk );
  endif
  assert ( Nbins == N, "Number of frequency bins 'fk' (%d) does not agree with number of samples in 'xk' (%d)!\n", N, Nbins );

  N1 = oversampleby * N;
  Band1 = N1 * df;

  xk1 = ifftshift ( xk );

  xi = N1 * df * ifft ( xk1, N1 );

  dt = 1 / Band1;
  Tobs = N1 * dt;
  ti = 0:dt:Tobs - dt;
  assert ( length(ti) == length(xi) );

  timeSeries.ti = ti;
  timeSeries.xi = xi;

  return;

endfunction

%!test
%! dt = 0.1;
%! ti = dt * [ 0:999 ];
%! xi = zeros ( size ( ti ) );
%! xi ( 555 ) = 1;
%! ft = FourierTransform ( ti, xi );
%! ts = FourierTransformInv ( ft.fk, ft.xk );
%! err = max ( abs ( ts.xi - xi ) );
%! assert ( err < 1e-9 );
