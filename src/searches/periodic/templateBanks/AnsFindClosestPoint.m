%% return the closest point of the An*-lattice to the given point x in R^n
%% based on Chap.20.3 'Algorithm 4' in Conway&Sloane (1999)
%% [this function can handle vector input]
%%
%% The boolean option input 'embedded' (default=false) governs whether
%% the input vectors are interpreted as vectors in the (n+1) dimensional
%% embedding space of the lattice, otherwise they are interpreted as
%% n-dimensional vectors in an n-dimensional lattice
%% NOTE: The returned lattice vectors use the same representation as
%% the input-vectors (i.e. 'embedded' or not)


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

function closest = AnsFindClosestPoint ( x, embedded )

  if ( !exist("embedded") )
    embedded = false;		%% normal n-dimensional representation of n-dim lattice
  endif

  [ rows, numPoints ] = size ( x );

  %% ----- find input-vectors in embedding space -----
  if ( embedded )
    dim = rows - 1;	%% space is (n+1)-dimensional, lattice is n-dimensional
    x0 = x;
  else
    dim = rows;		%% space == lattice == n-dimensional
    [ gen, rot ] = AnsGenerator ( dim );
    %% map n-dimensional input points x "back" into x0 in the n+1-dimensional
    %% embedding lattice space of the original generator space
    x0 = rot * x;
  endif

  %% compute closest point to coset r_i + An:
  niMin = 1e6 * ones ( 1, numPoints );	%% keep track of smallest norms achieved for various glue-vectors
  y0iMin = zeros (dim+1, numPoints );
  for i = 0:dim		%% exceptionally counting from 0 for better alignment with CS99
    %% generate glue vector [i]	: Chap.4, Eq.(55) in CS99
    j = dim + 1 - i;
    pA =  i / ( dim + 1 ) * ones ( j, numPoints );
    pB = -j / ( dim + 1 )  * ones ( i, numPoints );
    gluei0 = [ pA; pB ];	%% (n+1)x numPoints matrix (glue-vectors are columns!)

    %% -----
    y0i = AnFindClosestPoint ( x0 - gluei0, true ) + gluei0;	%% central step: try each glue-vector with An

    ni = sumsq ( x0 - y0i, 1 );

    indsMin = find ( ni <= niMin );
    niMin ( indsMin ) = ni ( indsMin );
    y0iMin ( :, indsMin ) = y0i ( :, indsMin );		%% update record-holders

  endfor %% i = 0:numGlueVectors-1

  close0 = y0iMin;

  if ( !embedded )
    %% rotate (n+1)-dim lattice-vectors back into the n-dim lattice-space representation
    closest = rot' * close0;
  else
    closest = close0;
  endif


  return;

endfunction
