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

function varargin = struct2varargin ( in_struct )
  %% varagin = struct2varagin ( in_struct )
  assert ( isstruct ( in_struct ) );

  names = fieldnames ( in_struct );
  vals  = struct2cell ( in_struct );

  varargin = [ names'; vals' ];
  return;
endfunction
