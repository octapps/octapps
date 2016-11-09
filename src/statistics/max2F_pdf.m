%% Copyright (C) 2016 Reinhard Prix
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

%% p = max2F_pdf ( maxTwoF, Ntrials, Nseg = 1 )
%%
%% Probability density for maximum 2F(semi-coherent over Nseg segment) out of Ntrials
%% independent draws.
%% Can take vector-arguments for maxTwoF.
%%

function p = max2F_pdf ( maxTwoF, Ntrials, Nseg = 1 )
  assert ( isscalar ( Nseg ) );
  assert ( isscalar ( Ntrials ) );

  dof = 4 * Nseg;
  logp = log(Ntrials) + log(ChiSquare_pdf ( maxTwoF, dof, lambda=0)) +  (Ntrials-1) * log ( ChiSquare_cdf( maxTwoF, dof, lambda=0 ) );
  p = e.^logp;
endfunction
