%% Copyright (C) 2008 Reinhard Prix
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with with program; see the file COPYING. If not, write to the
%% Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%% MA  02111-1307  USA

%% freqSeries = FourierTransform ( ti, xi, oversampleby )
%%
%% Computes Fourier-transform of input timeseries with timestamps {t_j}
%% and data-points {x_j}, where j = 0 ... N-1
%% This function complies with the LSC convention for Fourier-transforms, i.e.
%% xFT(f) = dt * sum_{j=0}^{N-1} x_j * e^{-2pi i f t_j}
%%
%% The optional argument 'oversampleby' specifies an INTEGER
%% factor to oversample the FFT by, using zero-padding of the time-series.
%%
%% The returned 'freqSeries' is a struct with two array-fields:
%% freqSeries.fk = { f_k }, the frequency-bins, and
%% freqSeries.xk = { x_k }, the (complex) Fourier bins,
%% where k = 0 ... N-1, and DFT frequency-bins f_k = k / N
%%
%% Note: Matrix inputs
%% The input can contain several time-series data vectors xi over the same N time-samples,
%% where each time-series is a row-vector, ie the dimension of xi must be Nseries x N,
%% where 'Nseries' is the number of parallel time-series.
%% The FFT is therefore performed along rows of xi, and the resulting x_k has the same arrangement.

function freqSeries = FourierTransform ( ti, xi, oversampleby )

  %% ----- input sanity checks ----------
  if ( ! isvector ( ti ) )
    error ("Time-steps input 'ti' must be a 1D vector\n");
  endif
  N = length(ti);
  dt = ti(2) - ti(1);

  [Nseries, Nsamp] = size ( xi );
  if ( Nsamp != N )
    error ("Number of time-steps 'ti' (%d) does not agree with samples in 'xi' (%d)!\n", N, Nsamp );
  endif

  if ( !exist("oversampleby") )
    oversampleby = 1;
  endif
  if ( ( round(oversampleby) != oversampleby ) || (oversampleby <= 0) )
    error ("Input argument 'oversampleby' must be a positive integer! (%f)", oversampleby);
  endif

  N1 = oversampleby * N;
  Tobs1 = N1 * dt;
  df1 = (1/Tobs1);

  xFFT = dt * fft ( xi, N1, 2 );	%% FFT over columns, ie "along rows"

  xk = [ xFFT(:, floor(N1/2)+2 : N1), xFFT(:, 1:floor(N1/2)+1) ];
  fk = df1 * [ - floor(N1/2)+1 : floor(N1/2) ];

  freqSeries.fk = fk;
  freqSeries.xk = xk;

  return;

endfunction
