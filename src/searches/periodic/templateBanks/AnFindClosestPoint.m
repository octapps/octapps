%% return the closest point of the An-lattice to the given point x in R^n
%% based on Chap.20.2 'Algorithm 3' in Conway&Sloane (1999)
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
  inds_gt0 = find ( def > 0 );
  inds_lt0 = find ( def < 0 );

  corr = zeros ( dim+1, numPoints );
  for i = inds_gt0	%% if deficiency > 0: subtract 1 from f(x_i0)...f(x_i(def-1))
    corr ( inds(1:def(i), i), i ) = -1;
  endfor
  for i = inds_lt0	%% if deficiency < 0: add 1 to f(x_dim) .... f(x_i(dim+1-def)
    corr( inds( (dim+2 + def(i)):(dim+1), i), i ) = 1;
  endfor

  close0 = fx0 + corr;

  %% rotate back from (n+1)-dim into n-dim space representation
  close = rot' * close0;
  return;

endfunction
