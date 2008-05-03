%% return matrix containing the 2(n+1) 'Voronoi-relevant' vectors for An*
%% in n dimensions. Given in Conway&Sloane(1991) "The cell Structure of Certain Lattices"

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

function relevants = AnsRelevantVectors ( dim )

  val1 = dim / ( dim + 1 );
  val0 = - ( 1 / ( dim + 1 ) );

  baseVplus = zeros ( dim, dim + 1 );
  for i = [ 1:dim+1 ]
    p0 = val0 * ones ( 1, i - 1);
    p1 = val0 * ones ( 1, dim - i + 1 );
    baseVplus(i,:) = [ p0, val1, p1 ];
  endfor

  baseVminus = - baseVplus;

  rel0 = [ baseVplus; baseVminus ];

  %% NOTE: similar to AnsLatticeGenerator(),
  %% we follow our own convention where column == lattice-vectors
  %% so we need to transpose the final result

  rel0 = rel0';

  %% now convert this to a full-rank matrix so we have an n x n generator
  [ generator, base ] = AnsGenerator ( dim );
  relevants = base' * rel0;

endfunction %% AnsRelevantVectors()
