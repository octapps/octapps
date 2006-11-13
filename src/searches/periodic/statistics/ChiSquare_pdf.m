%%
%% Copyright (C) 2006 Reinhard Prix
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

%% matlab might have a function for this, but octave doesn't

function chi2 = ChiSquare_pdf ( z, N, lambda )
  %% compute the general, NON-CENTRAL or central chi^2-distribution with
  %% N degrees of freedom and non-centrality parameter lambda, for the (vector)
  %% input argument z

  if ( lambda == 0 )
    chi2 = chisquare_pdf ( z , N);
  else
    chi2 = e.^(-0.5 .* (z + lambda) ) .* z.^((N-1)/2) .* \
	sqrt(lambda) .* besseli(N/2 - 1, sqrt( z .* lambda ) ) ./ ( 2 .* (z .* lambda).^(N/4) );
  endif

endfunction

