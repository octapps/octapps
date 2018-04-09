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
## @deftypefn {Function File} {@var{iseq} =} CompareSegmentLists ( @var{seglist}, @var{seglist_1}, @var{seglist_2}, @dots{} )
## @deftypefnx{Function File} {@var{iseq} =} CompareSegmentLists ( @var{seglist}, @var{@{seglist_1}, @var{seglist_2}, @var{...@}} )
##
## Return true if the segment list 'seglist' equals any of the segment
## lists @var{seglist_1}, @var{seglist_2}, etc., and false otherwise.
##
## @end deftypefn

function iseq = CompareSegmentLists(seglist, varargin)

  ## check input
  assert(ismatrix(seglist) && size(seglist, 2) == 2, "%s: argument #%i is not a segment list", 1);
  if numel(varargin) == 1
    if iscell(varargin{1})
      seglists = varargin{1};
    else
      seglists = {varargin{1}};
    endif
  else
    seglists = varargin;
  endif
  for i = 1:numel(seglists)
    assert(ismatrix(seglists{i}) && size(seglists{i}, 2) == 2, "%s: argument #%i is not a segment list", i + 1);
  endfor

  ## compare segment lists
  iseq = false(size(numel(seglists)));
  for i = 1:numel(seglists)
    iseq(i) = (size(seglist) == size(seglists{i})) && (max(max(abs(seglist - seglists{i}))) < 5e-10);
  endfor

endfunction

%!test
%!  seglists = CreateSegmentList(123, [2, 3, 5, 9, 17], [1.2, 4.5, 9.7], [], [0.7, 0.9]);
%!  for n = 1:numel(seglists)
%!    assert(find(CompareSegmentLists(seglists{n}, seglists)) == n);
%!  endfor
