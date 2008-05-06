%% return the closest point of the An*-lattice to the given point x in R^n
%% based on Chap.20.3 'Algorithm 4' in Conway&Sloane (1999)
%% [this function can handle vector input]

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

function closest = AnsFindClosestPoint ( x )

  [dim, numPoints ] = size ( x );
  [gen, rot] = AnGenerator ( dim );

  %% compute closest point to coset r_i + An:
  niMin = 1e6 * ones ( 1, numPoints );	%% keep track of smallest norms achieved for various glue-vectors
  yiMin = zeros (dim, numPoints );
  for i = 0:dim		%% exceptionally counting from 0 for better alignment with CS99
    %% generate glue vector [i]
    j = dim + 1 - i;
    pA = -j / ( dim + 1 ) * ones ( i, numPoints );
    pB = i / ( dim + 1 )  * ones ( j, numPoints );
    gluei0 = [ pA; pB ];	%% (n+1)x numPoints matrix (glue-vectors are columns!)

    gluei = rot' * gluei0;	%% rotate this into the n-dimensional lattice space

    %% -----
    yi = AnFindClosestPoint ( x - gluei ) + gluei;	%% central step: try each glue-vector with An

    ni = sumsq ( x - yi, 1 );

    indsMin = find ( ni <= niMin );
    niMin ( indsMin ) = ni ( indsMin );
    yiMin ( :, indsMin ) = yi ( :, indsMin );		%% update record-holders

  endfor %% i = 0:numGlueVectors-1

  closest = yiMin;

  return;

endfunction
