## Copyright (C) 2011 Karl Wette
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
## @deftypefn {Function File} {@var{p} =} randPointInNSphere ( @var{n}, @var{u} )
##
## Generate random points (with)in a @var{n}-dimensional sphere
##
## @heading Arguments
##
## @table @var
## @item n
## dimensionality of sphere
##
## @item u
## vector of numbers used to chose the radius; set
##
## @table @asis
## @item u = rand(1, m)
## to generate m points uniformly within the sphere, or
##
## @item u = ones(1, m)
## to generate m points uniformly over the sphere's surface
##
## @end table
##
## @end table
##
## @end deftypefn

function p = randPointInNSphere(n, u)

  ## check input
  assert(isscalar(n));
  assert(isvector(u));
  assert(0 <= u && u <= 1);
  u = u(:)';

  ## algorithm from:
  ## see http://en.wikipedia.org/wiki/N-sphere#Generating_random_points

  ## generate column vectors of normally-distributed random values
  p = randn(n, length(u));

  ## calculate the radius of each column
  r = sqrt(sumsq(p, 1));

  ## divide each column by its radius and scale by u^(1/n)
  s = u.^(1/n) ./ r;
  p = p .* s(ones(n, 1), :);

endfunction

%!assert(norm(randPointInNSphere(1, 1)), 1.0, 1e-4)
%!assert(norm(randPointInNSphere(2, 1)), 1.0, 1e-4)
%!assert(norm(randPointInNSphere(3, 1)), 1.0, 1e-4)
%!assert(norm(randPointInNSphere(4, 1)), 1.0, 1e-4)
%!assert(norm(randPointInNSphere(5, 1)), 1.0, 1e-4)
