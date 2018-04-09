## Copyright (C) 2014 Karl Wette
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
## @deftypefn {Function File} { [ @var{val} ] =} getoptfield ( @var{def}, @var{S}, @dots{} )
##
## Return getfield (@var{S}, @dots{}), if it exists, otherwise return @var{def}.
##
## @seealso{getfield}
## @end deftypefn

function val = getoptfield(def, varargin)
  try
    val = getfield(varargin{:});
  catch
    val = def;
  end_try_catch
endfunction

%!assert(getoptfield(1, []), 1)
%!assert(getoptfield([], struct("a", 1), "a"), 1)
%!assert(getoptfield([], struct("a", 1), "b"), [])
