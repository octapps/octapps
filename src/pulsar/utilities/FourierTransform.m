%% freqSeries = FourierTransform ( ti, xi, oversampleby )
%%
%% Computes Fourier-transform of input timeseries with timestamps ti
%% and data-points xi. This function complies with the LSC convention
%% for Fourier-transforms, i.e.
%% xk(f) = dt * sum_{j=0}^{n-1} x_j * e^{-2pi i f t_j}
%%
%% The optional argument 'oversampleby' specifies an INTEGER
%% factor to oversample the FFT by
%%

%%
%% Copyright (C) 2008 Reinhard Prix
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%

function freqSeries = FourierTransform ( ti, xi, oversampleby )

  dt = ti(2) - ti(1);

  N = length(ti);

  if ( !exist("oversampleby") )
    oversampleby = 1;
  endif
  if ( ( round(oversampleby) != oversampleby ) || (oversampleby <= 0) )
    error ("Input argument 'oversampleby' must be a positive integer! (%f)", oversampleby);
  endif

  N1 = oversampleby * N;
  Tobs1 = N1 * dt;
  xi1 = [ xi, zeros(1, (N1 - N) ) ];	%% zero-padding

  xFFT = dt * fft ( xi1 );

  xk = [ xFFT(floor(N1/2)+2 : N1), xFFT(1:floor(N1/2)+1) ];
  fk = [ - floor(N1/2)+1 : floor(N1/2) ] * (1/Tobs1);

  freqSeries.fk = fk;
  freqSeries.xk = xk;

  return;

endfunction
