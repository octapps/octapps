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

## Compute the function 'F' over a running window of 'n' values of each 'x'.
## Usage:
##   [y1, y2, ...] = runningFunction(F, n, x1, x2, ...)
## where:
##   F           = Running window function
##   n           = Running window size
##   x1, x2, ... = Input data
##   y1, y2, ... = Output data, e.g. y1 = [F(x1(1:n)), F(x1(2:n+1)), ...]

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
