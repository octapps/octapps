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
## @deftypefn {Function File} { [ @var{generator}, @var{rotator} ] =} ZnGenerator ( @var{dim} )
##
## Return an nxn full-rank generating matrix for the Zn lattice;
## this is trivial, of course, but added for completeness.
##
## @end deftypefn

function [ generator, rotator ] = ZnGenerator ( dim )

  generator = eye ( dim, dim );
  rotator = eye ( dim, dim );

  return;

endfunction

%!assert(issquare(ZnGenerator(1)))
%!assert(issquare(ZnGenerator(2)))
%!assert(issquare(ZnGenerator(3)))
%!assert(issquare(ZnGenerator(4)))
%!assert(issquare(ZnGenerator(5)))
