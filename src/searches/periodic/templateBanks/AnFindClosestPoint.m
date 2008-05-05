%% return the closest lattice point to the given point x in R^n
%% based on 'Algorithm 5' in Conway&Sloane, IEEE 28, 227 (1982)
%% "Fast Quantizing and Decoding Algorithms for Lattice Quantizers and Codes"


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

function [ close, close0 ] = AnFindClosestPoint ( x )

  [ dim, numPoints ] = size ( x );

  [ gen, rot ] = AnGenerator ( dim );

  %% map n-dimensional point x "back" into xp in the n+1-dimensional
  %% lattice space of the original generator space, satisfying sum(xp) = 0
  x0 = rot * x;

  %% ----- Step 2 -----
  fx0 = round ( x0 );		%% f(x)
  dx0 = x0 - fx0;		%% delta(x)
  def = sum ( fx0, 1 );		%% deficiency Delta

  %% ----- Step 3 -----
  [ s, inds ] = sort ( dx0, 1 );

  %% ----- Step 4 -----
  corr = zeros ( dim+1, numPoints );
  inds_gt0 = find ( def > 0 );
  inds_lt0 = find ( def < 0 );

  for i = inds_gt0
    corr ( inds(1:(def(i))), i ) = -1;
  endfor
  for i = inds_lt0
    corr( inds( (dim+1):(dim+2-abs(def(i)))), i ) = 1;
  endfor

  close0 = fx0 + corr;

  %% rotate back into n-dim space representation
  close = rot' * close0;
  return;

endfunction
