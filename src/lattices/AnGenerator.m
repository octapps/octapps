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
## @deftypefn {Function File} { [ @var{generator}, @var{rotator} ] =} AnGenerator ( @var{dim} )
##
## return an nxn full-rank generating matrix for an An lattice,
## based on the (n+1)xn @var{generator} of Chap.4,Eq.(52) in Conway&Sloane(1999)
##
## also returns the rotation-matrix that takes the nxn @var{generator} back to the
## (n+1)x n representation of the lattice space in n+1 dimensions,
## which is simply obtained by QR-decomposition of the (n+1)x n dimensional @var{generator}.
##
## @end deftypefn

function [ generator, rotator ] = AnGenerator ( dim )

  gen0 = zeros(dim,dim+1);
  for row = [1:dim]

    for col = [1:dim+1]

      if ( col == row )
        gen0(row,col) = -1;
      elseif ( col == row + 1 )
        gen0(row,col) = +1;
      endif

    endfor ## for col < dim + 1

  endfor ## for row < dim

  ## NOTE: the above is the An generator in CS99 conventions,
  ## i.e. each *LINE* of the generator-matrix represents one lattice vector.
  ## However, in CQG 24, 481 (2007) we used a convention where the *COLUMNS*
  ## of the generator contain the lattice-vectors. I'm afraid I'm stuck with
  ## that latter convention now ...

  gen0 = gen0'; ## use transpose matrix: columns == lattice-vectors

  ## now convert this to a full-rank matrix so we have an n x n generator,
  ## simply using octave's QR-decomposition
  [q, r, p] = qr ( gen0 );

  generator = r(1:dim,:);
  rotator = q(:,1:dim);
  return;

endfunction

%!assert(issquare(AnsGenerator(1)))
%!assert(issquare(AnsGenerator(2)))
%!assert(issquare(AnsGenerator(3)))
%!assert(issquare(AnsGenerator(4)))
%!assert(issquare(AnsGenerator(5)))
