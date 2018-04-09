## Copyright (C) 2016 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{rotMatrix} =} rotationMatrix ( @var{angle}, @var{rotAxis} )
##
## computes the rotation matrix for an *active* rotation by @var{angle} around
## the axis @var{rotAxis} (3d vector)
##
## @end deftypefn

function rotMatrix = rotationMatrix ( angle, rotAxis )

  assert ( isvector ( rotAxis ) && (length(rotAxis) == 3), "%s: rotation Axis must be a 3-vector.\n", funcName );

  u = rotAxis / norm(rotAxis);  ## unit vector
  x = u(1); y = u(2); z = u(3);

  ## Taken from wikipedia: http://en.wikipedia.org/wiki/Rotation_matrix
  c = cos(angle); s = sin(angle); C = 1-c;
  xs = x*s;   ys = y*s;   zs = z*s;
  xC = x*C;   yC = y*C;   zC = z*C;
  xyC = x*yC; yzC = y*zC; zxC = z*xC;

  rotMatrix = [ x * xC + c, xyC - zs,  zxC + ys ;
                xyC + zs,    y * yC + c,    yzC - xs ;
                zxC - ys,    yzC + xs,   z * zC + c ];

endfunction ## rotationMatrix()

%!shared rotMatrix
%!  rotMatrix = rotationMatrix(1.357, [0.9, 8.7, 6.5]);
%!assert(ismatrix(rotMatrix))
%!assert(rotMatrix' * rotMatrix, eye(3), 1e-3)
