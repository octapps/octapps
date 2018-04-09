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
## @deftypefn {Function File} { [ @var{ua}, @var{ub} ] =} TwoLineIntersection ( @var{p1a}, @var{p2a}, @var{p1b}, @var{p2b} )
##
## Returns the intersection of two lines defined by the locus of points
## pa = @var{p1a} + @var{ua}*(@var{p2a} - @var{p1a}) and
## pb = @var{p1b} + @var{ub}*(@var{p2b} - @var{p1b})
## i.e. the values of @var{ua} and @var{ub} such that pa == pb.
##
## @end deftypefn

function [ua, ub] = TwoLineIntersection(p1a, p2a, p1b, p2b)

  ## check input
  assert(isvector(p1a) && length(p1a) == 2);
  assert(isvector(p1b) && length(p1b) == 2);
  assert(isvector(p2a) && length(p2a) == 2);
  assert(isvector(p2b) && length(p2b) == 2);

  ## determine intersection
  A = [p2a(:) - p1a(:), p1b(:) - p2b(:)];
  b = (p1b(:) - p1a(:));
  u = A \ b;
  ua = u(1);
  ub = u(2);

endfunction

%!test
%!  [ua,ub] = TwoLineIntersection([-1;-1], [3;3], [-1;1], [1;-1]);
%!  assert(ua, 0.25, 1e-3);
%!  assert(ub, 0.5, 1e-3);
