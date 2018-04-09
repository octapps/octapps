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
## @deftypefn {Function File} {@var{ret} =} AnsMinimalVectors ( @var{dim} )
##
## return matrix containing the tau/2=(n+1) 'minimal' vectors for An*,
## (tau is the kissing number) in n dimensions. The second half of minimal
## vectors is simply obtained by multiplying these by (-1).
## From Conway&Sloane(1991) "The cell Structure of Certain Lattices"
##
## @end deftypefn

function ret = AnsMinimalVectors ( dim )

  val1 = dim / ( dim + 1 );
  val0 = - ( 1 / ( dim + 1 ) );

  baseVplus = zeros ( dim, dim + 1 );
  for i = [ 1:dim+1 ]
    p0 = val0 * ones ( 1, i - 1);
    p1 = val0 * ones ( 1, dim - i + 1 );
    baseVplus(i,:) = [ p0, val1, p1 ];
  endfor

  ## NOTE: similar to AnsLatticeGenerator(),
  ## we follow our own convention where column == lattice-vectors
  ## so we need to transpose the final result

  mini = baseVplus';

  ## now convert this to vectors in the n-dimensional lattice-space,
  ## using the (n+1)-dimensional description of the n-basis vectors

  [ gen, rot ] = AnsGenerator ( dim );
  ret = rot' * mini;

  return;

endfunction ## AnsMinimalVectors()

%!assert(size(AnsMinimalVectors(1)), [1, 2])
%!assert(size(AnsMinimalVectors(2)), [2, 3])
%!assert(size(AnsMinimalVectors(3)), [3, 4])
%!assert(size(AnsMinimalVectors(4)), [4, 5])
%!assert(size(AnsMinimalVectors(5)), [5, 6])
