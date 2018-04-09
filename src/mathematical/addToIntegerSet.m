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
## @deftypefn {Function File} {@var{intset} =} addToIntegerSet ( @var{intset}, @var{ints} )
##
## Add integers to an set of integers, stored as contiguous intervals.
##
## @heading Arguments
##
## @table @var
## @item intset
## set of integers, stored as a Nx2 matrix of intervals:
## @verbatim
## [min1, max1; min2, max2; min3, max3; ...]
## @end verbatim
##
## @item ints
## integers to add to set
##
## @end table
##
## @end deftypefn

function intset = addToIntegerSet(intset, ints)

  ## check input
  if !isempty(intset)
    assert(ismatrix(intset) && size(intset, 2) == 2);
  endif
  assert(ismatrix(ints));
  assert(all(mod(ints, 1) == 0));

  ## ensure integer set intervals are sorted
  if !isempty(intset)
    intset = [min(intset(:,1), intset(:,2)), max(intset(:,1), intset(:,2))];
  endif

  ## return if no integers to add
  if isempty(ints)
    return
  endif

  ## get unique sorted integers
  ints = unique(ints(:));

  ## identify continuous integer intervals, and create integer set to be added
  jump = find(diff(ints) > 1);
  addintset = [ints([1; jump + 1]), ints([jump; length(ints)])];

  ## add integer set to existing set, then sort intervals
  newintset = sortrows([intset; addintset]);

  ## merge overlapping intervals when creating new integer set
  intset = newintset(1, :);
  for i = 2:size(newintset, 1)
    a = intset(end, 1);
    b = intset(end, 2);
    c = newintset(i, 1);
    d = newintset(i, 2);
    if c <= b + 1 && b < d
      intset(end, :) = [a, d];
    elseif b < c
      intset(end+1, :) = [c, d];
    endif
  endfor

endfunction

## tests
%!assert(isempty(addToIntegerSet([], [])))
%!assert(addToIntegerSet([], 1:4) == [1,4])
%!assert(addToIntegerSet([], [1:3, 5:9]) == [1,3; 5,9])
%!assert(addToIntegerSet([], [1, 1:5, 5, 4:8, 11]) == [1,8; 11,11])
%!assert(addToIntegerSet([1,4], []) == [1,4])
%!assert(addToIntegerSet([1,4], 1:4) == [1,4])
%!assert(addToIntegerSet([1,4], 6:8) == [1,4; 6,8])
%!assert(addToIntegerSet([1,4], [1:3, 5:9]) == [1,9])
%!assert(addToIntegerSet([1,4], [1, 1:5, 5, 4:8, 11]) == [1,8; 11,11])
%!assert(addToIntegerSet([1,3; 5,6; 8,11; 15,20], [4, 4, 13, 21]) == [1,6; 8,11; 13,13; 15,21])
