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
## @deftypefn {Function File} {@var{freqSeries} =} FourierTransform ( @var{ti}, @var{xi}, @var{oversampleby} )
##
## Computes Fourier-transform of input timeseries with timestamps @{t_j@}
## and data-points @{x_j@}, where j = 0 ... N-1
## This function complies with the LSC convention for Fourier-transforms, i.e.
## xFT(f) = dt * sum_@{j=0@}^@{N-1@} x_j * e^@{-2pi i f t_j@}
##
## The optional argument @var{oversampleby} specifies an INTEGER
## factor to oversample the FFT by, using zero-padding of the time-series.
##
## The returned 'freqSeries' is a struct with two array-fields:
## @itemize
## @item freqSeries.fk = @{ f_k @}, the frequency-bins, and
## @item freqSeries.xk = @{ x_k @}, the (complex) Fourier bins,
## @end itemize
##
## where k = 0 ... N-1, and DFT frequency-bins f_k = k / N
##
## @heading Note
##
## Matrix inputsThe input can contain several time-series data vectors @var{xi} over the same N time-samples,
## where each time-series is a row-vector, ie the dimension of @var{xi} must be Nseries x N,
## where 'Nseries' is the number of parallel time-series.
##
## The FFT is therefore performed along rows of @var{xi}, and the resulting x_k has the same arrangement.
##
## @end deftypefn

function freqSeries = FourierTransform ( ti, xi, oversampleby = 1 )

  ## ----- input sanity checks ----------
  assert ( isvector ( ti ), "Time-steps input 'ti' must be a 1D vector\n");
  assert ( ismatrix(xi) );
  assert ( isscalar(oversampleby) && mod(oversampleby,1)==0 && oversampleby >= 1 );

  N = length(ti);
  dt = mean ( diff ( ti ) );

  if ( isvector(xi) )
    Nsamp = length ( xi );
    xi = reshape ( xi, 1, Nsamp );
  else
    [Nseries, Nsamp] = size ( xi );
  endif
  assert ( Nsamp == N, "Number of time-steps 'ti' (%d) does not agree with samples in 'xi' (%d)!\n", N, Nsamp );

  N1 = oversampleby * N;
  Tobs1 = N1 * dt;
  df1 = (1/Tobs1);

  xFFT = dt * fft ( xi, N1, 2 );        ## FFT over columns, ie "along rows"

  xk = fftshift ( xFFT );
  fk = [ -(ceil((N1-1)/2):-1:1)*df1, 0, (1:floor((N1-1)/2))*df1 ];      ## taken from fftshift()

  assert ( length(fk) == length(xk) );
  freqSeries.fk = fk;
  freqSeries.xk = xk;

  return;

endfunction

%!test
%!  f0 = 10.0;
%!  t = 0:0.01:1;
%!  F = FourierTransform(t, sin(2*pi*f0*t));
%!  [~, ii] = max(abs(F.xk));
%!  assert(abs(F.fk(ii)), f0, 0.1);
