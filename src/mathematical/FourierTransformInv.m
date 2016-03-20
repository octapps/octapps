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

%% timeSeries = FourierTransformInv ( fk, xk, oversampleby )
%%
%% Computes inverse Fourier-transform of input frequency-series with
%% frequency steps fk and data-points xk. This function complies with
%% the LSC convention for inverse Fourier-transforms, i.e.
%% xi(t) = df * sum_{k=0}^{n-1} x_k * e^{2pi i f_k t}
%%
%% The optional argument 'oversampleby' specifies an INTEGER
%% factor to oversample the FFT by

function timeSeries = FourierTransformInv ( fk, xk, oversampleby = 1 )

  df = mean ( diff ( fk ) );

  N = length(fk);

  if ( ( round(oversampleby) != oversampleby ) || (oversampleby <= 0) )
    error ("Input argument 'oversampleby' must be a positive integer! (%f)", oversampleby);
  endif

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

