## Copyright (C) 2017 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{path} =} mkpath ( @var{dirs}, @dots{} )
##
## Makes the directory path @var{dirs}, including all parent directories.
## Returns the final directory in @var{path}.
##
## @seealso{mkdir}
## @end deftypefn

function dir = mkpath(varargin)
  if length(varargin) == 0
    print_usage
  endif
  for n = 1:length(varargin)
    dir = fullfile(varargin{1:n});
    [status, msg] = mkdir(dir);
    if status == 0
      error("%s: could not make directory '%s': %s", funcName, dir, msg);
    endif
  endfor
endfunction

%!test
%!  dir0 = tempname(tempdir);
%!  mkpath(dir0, "a", "b", "c");
%!  assert(isdir(fullfile(dir0, "a", "b", "c")));
