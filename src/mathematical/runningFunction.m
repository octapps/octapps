## Copyright (C) 2014 Karl Wette
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
## @deftypefn {Function File} { [ @var{y1}, @var{y2}, @dots{} ] =} runningFunction ( @var{F}, @var{n}, @var{x1}, @var{x2}, @dots{} )
##
## Compute the function @var{F} over a running window of @var{n} values of each 'x'.
##
## @heading Arguments
##
## @table @var
## @item F
## Running window function
##
## @item n
## Running window size
##
## @item x1
## @itemx x2
## @itemx @dots{}
## Input data
##
## @item y1
## @itemx y2
## @itemx @dots{}
## Output data, e.g. @var{y1} = [@var{F}(@var{x1}(1:@var{n})), @var{F}(@var{x1}(2:@var{n}+1)), @dots{}]
##
## @end table
##
## @end deftypefn

function varargout = runningFunction(F, n, varargin)

  ## check input
  assert(is_function_handle(F));
  assert(fix(n) == n && n > 0);
  assert(length(varargin) > 0);

  ## compute running function over arguments
  for k = 1:length(varargin);
    x = varargin{k};
    assert(isvector(x), "%s: 'x%i' is not a vector", funcName, k);
    varargout{k} = arrayfun(@(i) F(x(i:i+n-1)), 1:length(x)-n+1);
  endfor

endfunction

%!assert(runningFunction(@mean, 3, 1.1:0.7:9.3), 1.8:0.7:8.1, 1e-3)
%!assert(runningFunction(@median, 3, 1:10), 2:9, 1e-3)
