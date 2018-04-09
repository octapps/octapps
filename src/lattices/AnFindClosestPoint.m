## Copyright (C) 2008 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {@var{closest} =} AnFindClosestPoint ( @var{x}, @var{embedded} )
##
## return the closest point of the An-lattice to the given point @var{x} in R^n
## based on Chap.20.2 'Algorithm 3' in Conway&Sloane (1999)
## @heading Note
## this function can handle vector input
##
## The boolean option input @var{embedded} (default=false) governs whether
## the input vectors are interpreted as vectors in the (n+1) dimensional
## embedding space of the lattice, otherwise they are interpreted as
## n-dimensional vectors in an n-dimensional lattice
##
## @heading Note
##
## The returned lattice vectors use the same representation asthe input-vectors (i.e. @var{embedded} or not)
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function closest = AnFindClosestPoint ( x, embedded )

  if ( !exist("embedded") )
    embedded = false;           ## normal n-dimensional representation of n-dim lattice
  endif

  [ rows, numPoints ] = size ( x );

  ## ----- find input-vectors in embedding space -----
  if ( embedded )
    dim = rows - 1;     ## space is (n+1)-dimensional, lattice is n-dimensional
    x1 = x;
  else
    dim = rows;         ## space == lattice == n-dimensional
    [ gen, rot ] = AnGenerator ( dim );
    ## map n-dimensional input points x "back" into x0 in the n+1-dimensional
    ## embedding lattice space of the original generator space, satisfying sum(x0) = 0
    x1 = rot * x;
  endif

  ## ----- Step 1: make sure the input vectors lie in the lattice-subspace: Chap.20, Eq.(3) in CS99
  s = sum ( x1, 1 ) / ( dim + 1 );
  sMat = ones ( dim+1, 1 ) * s;
  x0 = x1 - sMat;

  ## ----- Step 2 -----
  fx0 = round ( x0 );           ## f(x)
  dx0 = x0 - fx0;               ## delta(x)
  def = sum ( fx0, 1 );         ## deficiency Delta

  ## ----- Step 3 -----
  [ s, inds ] = sort ( dx0, 1 );

  ## ----- Step 4 -----
  inds_gt0 = find ( def > 0 );
  inds_lt0 = find ( def < 0 );

  corr = zeros ( dim+1, numPoints );
  for i = inds_gt0      ## if deficiency > 0: subtract 1 from f(x_i0)...f(x_i(def-1))
    corr ( inds(1:def(i), i), i ) = -1;
  endfor
  for i = inds_lt0      ## if deficiency < 0: add 1 to f(x_dim) .... f(x_i(dim+1-def)
    corr( inds( (dim+2 + def(i)):(dim+1), i), i ) = 1;
  endfor

  close0 = fx0 + corr;

  if ( !embedded )
    ## rotate (n+1)-dim lattice-vectors back into the n-dim lattice-space representation
    closest = rot' * close0;
  else
    closest = close0;
  endif

  return;

endfunction

%!test
%!  x = rand(3, 100000);
%!  dx = x - AnFindClosestPoint(x);
%!  assert(max(sqrt(dot(dx, dx))) <= AnCoveringRadius(3));
