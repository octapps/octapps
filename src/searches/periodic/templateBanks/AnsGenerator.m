%% return an nxn full-rank generating matrix for an An* lattice,
%% based on the (n+1)xn generator of Eq.(76) in Conway&Sloane99,
%% and an orthonormal basis of the original lattice space in n+1 dimensions
%% adapted from implementation in LAL/packages/pulsar/src/LatticeCovering.c:XLALGetLatticeGenerator()

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

function [ generator, base ] = AnsGenerator ( dim )

  gen0 = zeros(dim,dim+1);
  for row = [1:dim]

    for col = [1:dim+1]
      %% ---------- find value for that matrix element ----------*/
      if ( row < dim )

	if ( col == 1 )
	  val = 1.0;
	elseif (col == row + 1)
	  val = -1.0;
	else
	  continue;
	endif
      else
	if ( col == 1 )
	  val = - 1.0 * dim / ( dim + 1.0);
	else
	  val =   1.0 / (dim + 1.0);
	endif
      endif
      %% ---------- set matrix element ---------- */
      gen0 ( row, col ) = val;

    endfor %% for col < dim + 1

  endfor %% for row < dim

  %% NOTE: the above is the An* generator in CS99 conventions,
  %% i.e. each *LINE* of the generator-matrix represents one lattice vector.
  %% However, for some reason, the git of CQG 24, 481 (2007)
  %% decided to use a convention where the *COLUMNS* of the generator contain
  %% the lattice-vectors. I'm afraid I'm stuck with the latter convention now ...

  gen0 = gen0';	%% use transpose matrix: columns == lattice-vectors

  %% now convert this to a full-rank matrix so we have an n x n generator
  base = orth ( gen0 );
  generator = base' * gen0;

  return;

endfunction %% AnsGenerator()
