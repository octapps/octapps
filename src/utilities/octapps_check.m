## Copyright (C) 2013 Karl Wette
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

## Runs 'test' on each supplied filename; used by the top-level
## OctApps Makefile when running 'make check'.
## Usage:
##   octapps_check <filepath...>

function octapps_check(varargin)
  names = cell(1, length(varargin));
  for i = 1:length(varargin)
    [_, names{i}] = fileparts(varargin{i});
  endfor
  names = char(names);
  failed = false;
  pso = page_screen_output(0);
  for i = 1:length(varargin)
    printf("(%3i/%3i) %s : ", i, length(varargin), names(i,:));
    [n, m] = test(varargin{i});
    if n == 0 || n < m
      failed = true;
      printf("FAILED\n");
    else
      printf("PASSED %3i tests\n", n);
    endif
  endfor
  page_screen_output(pso);
  if failed
    error("failed tests!\n");
  endif
endfunction
