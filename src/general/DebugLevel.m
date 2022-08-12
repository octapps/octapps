## Copyright (C) 2022 Karl Wette, Reinhard Prix
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
## @deftypefn {Function File} {} DebugLevel @var{level}
## @deftypefnx{Function File} {} DebugLevel ( @var{level} )
## @deftypefnx{Function File} {@var{level} = } DebugLevel ( )
##
## Sets and/or returns the OctApps debug level @var{level}.
##
## @end deftypefn

function varargout = DebugLevel ( level )

  persistent debugLevel;
  if ( isempty ( debugLevel ) )
    debugLevel = 0;
  endif

  if nargin > 0
    if ischar ( level )
      level = str2double ( level );
    endif
    if !isreal ( level ) || level != round ( level ) || level < 0
      error ( "%s: OctApps debug level must be a positive integer", funcName );
    endif
    debugLevel = level;
  endif

  if nargout > 0
    varargout = { debugLevel };
  endif

endfunction ## DebugLevel()

%!test
%!  assert(DebugLevel() == 0);
%!  DebugLevel 1;
%!  assert(DebugLevel() == 1);
%!  DebugLevel(2);
%!  assert(DebugLevel() == 2);
