## Copyright (C) 2015 Reinhard Prix
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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} DebugPrintf ( @var{level}, @var{args}@dots{} )
##
## If @var{debugLevel} >= @var{level}, then print @var{args}@dots{} using
## @code{fprintf()} to @file{stderr}.
##
## @var{debugLevel} is a global variable declared with @code{global}.
##
## @end deftypefn

function DebugPrintf ( level, varargin )
  global debugLevel;
  if ( isempty ( debugLevel ) ) debugLevel = 0; endif

  if ( debugLevel >= level )
    fprintf ( stderr, varargin{:} );
  endif
  return;
endfunction ## DebugPrintf()

%!test
%!  global debugLevel;
%!  debugLevel = 1;
%!  DebugPrintf(0, "Hi there\n");
