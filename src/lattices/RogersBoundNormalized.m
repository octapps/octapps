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
## @deftypefn {Function File} {@var{ret} =} RogersBoundNormalized ( @var{n} )
##
## Rogers' upper bound on (normalized) packing density in @var{n} dimensions
## from Chap.1, Conway&Sloane(1999)
##
## @heading Note
## can handle vector input
##
## @end deftypefn

function ret = RogersBoundNormalized ( n )
  ## a few 'exact' numbers taken from Conway&Sloane(1999) Table 1.2:
  rogersLow24 = [ 0.5,  0.28868, 0.18470, 0.13127, 0.09987, 0.08112, 0.06981, 0.06326, 0.06007, 0.05953, ...
                  0.06136, 0.06559, 0.07253, 0.08278, 0.09735, 0.11774, 0.14624, 0.18629, 0.24308, 0.32454, ...
                  0.44289, 0.61722, 0.87767, 1.27241 ];
  ret = [];

  for ni = n

    if ( ni < 0 )
      error ("Only positive dimensions are allowed in RogersBoundNormalized()!\n");
    endif

    if ( ni == 0 )
      ret = [ ret, 1 ];
    elseif ( ni <= 24 )
      thisret = rogersLow24 ( ni );
      ret = [ret, thisret ];
    else
      ## approximate expression for (large?) n, from C&S(1999) Chap.1, Eq.(40)
      log2ret = (ni/2) .* log2 ( ni / (4*e*pi) ) + (3/2) * log2(ni) - log2(e/sqrt(pi)) + 5.25 ./ (ni + 2.5);
      thisret = 2 .^ log2ret;
      ret = [ ret, thisret ];
    endif

  endfor

endfunction

%!assert(RogersBoundNormalized(1:5) > 0)
