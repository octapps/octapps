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
## @deftypefn{Function File} {@var{x} =} randu(@var{xmin}, @var{xmax}, @var{dims}...)
##
## Return an array of size @var{dims} of random values
## uniformly distributed between @var{xmin} and @var{xmax}.
## @end deftypefn

function x = randu(xmin, xmax, varargin)

  ## check input
  assert(nargin >= 2);
  if nargin == 2
    if !isscalar(xmax)
      siz = size(xmax);
    else
      siz = size(xmin);
    endif
  elseif nargin == 3
    assert(isvector(varargin{1}));
    siz = varargin{1};
  else
    assert(all(cellfun("isscalar", varargin)));
    siz = [varargin{:}];
  endif
  assert(isscalar(xmin) || all(size(xmin) == siz));
  assert(isscalar(xmax) || all(size(xmax) == siz));

  ## generate random values
  x = xmin + rand(siz) .* (xmax - xmin);

endfunction
