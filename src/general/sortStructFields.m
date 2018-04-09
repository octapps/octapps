## Copyright (C) 2015 Karl Wette
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
## @deftypefn {Function File} { [ @var{s} ] =} sortStructFields ( @var{s} )
##
## Return the struct @var{S} with its fields sorted alphabetically.
##
## @end deftypefn

function S = sortStructFields(S)

  ## check input
  assert(isstruct(S));

  ## convert struct to cell array
  V = struct2cell(S);

  ## sort field names
  [N, P] = sort(fieldnames(S));

  ## rearrange field values to correspond to new name order
  siz = size(V);
  V = reshape(reshape(V, siz(1), [])(P, :), siz);

  ## reconstruct struct
  S = cell2struct(V, N);

endfunction

%!test
%!  S1 = struct('name', {'Peter', 'Hannah', 'Robert'}, 'age', {23, 16, 3});
%!  S2 = sortStructFields(S1);
%!  assert(all(strcmp({S1.name}, {S2.name})));
%!  assert(all([S1.age] == [S2.age]));
