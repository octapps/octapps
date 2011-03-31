%%
%% NOTE: This function is DEPRECATED, use ChiSquare_cdf() instead, which is about 2 orders of magnitude faster!
%%
%% beta = falseDismissal_2F ( thresh, rho2, dof )
%%
%% compute the false-dismissal rate for given threshold 'thresh' = 2F* and
%% non-centrality parameter lambda = rho^2, for 2F being Chi-square
%% distributed with 'dof' degrees of freedom (default = 4)
%% new version 2011/01: use anonymous functions instead of obsolete inline/formula commands
%%

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

function beta = falseDismissal_2F ( thresh, rho2, dof )

  printf ("WARNING: falseDismissal_2F() is DEPRECATED. Use ChiSquare_cdf(), which is about 2 orders of magnitude faster!\n");

  if ( !exist("dof") )
    dof = 4;
  endif

  N = length(thresh);
  M = length (rho2);
  beta = zeros ( M, N);

  for jj = 1:M

    for ii = 1:N
      if ( thresh(ii) == 0 )
	beta(jj, ii) = 0;
      else
	beta(jj, ii) = quad (@(x) ChiSquare_pdf (x, dof, rho2(jj)), 0, thresh(ii));

      endif
    endfor %% ii

  endfor %% jj

endfunction
