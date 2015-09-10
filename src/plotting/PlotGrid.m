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

## A more flexible replacement for subplot().
## Usage:
##   hax = PlotGrid(rowrange, colrange, rowspace, colspace, rowfigs, colfigs, rowidx, colidx)
## where:
##   {row|col}range: range of figure coordinates in [0,1] to be covered by grid in this dimension
##   {row|col}space: spacing between figures in this dimension
##   {row|col}figs: number of figures in this dimension
##   {row|col}idx: figure index in this dimension

function hax = PlotGrid(rowrange, colrange, rowspace, colspace, rowfigs, colfigs, rowidx, colidx)

  ## check input
  assert(isvector(rowrange) && length(rowrange) == 2);
  assert(isscalar(rowspace) && rowspace >= 0);
  assert(isscalar(rowfigs) && 1 <= rowfigs && mod(rowfigs, 1) == 0);
  assert(isscalar(rowidx) && 1 <= rowidx && mod(rowfigs, 1) == 0 && rowidx <= rowfigs);
  assert(isvector(colrange) && length(colrange) == 2);
  assert(isscalar(colspace) && colspace >= 0);
  assert(isscalar(colfigs) && 1 <= colfigs && mod(colfigs, 1) == 0);
  assert(isscalar(colidx) && 1 <= colidx && mod(colfigs, 1) == 0 && colidx <= colfigs);

  ## compute row position
  top0 = min(rowrange);
  dtop = (range(rowrange) + rowspace) / rowfigs;
  top = top0 + dtop * (rowfigs - rowidx);
  height = (range(rowrange) - rowspace * (rowfigs - 1)) / rowfigs;

  ## compute column position
  left0 = min(colrange);
  dleft = (range(colrange) + colspace) / colfigs;
  left = left0 + dleft * (colidx - 1);
  width = (range(colrange) - colspace * (colfigs - 1)) / colfigs;

  ## create subfigure
  set(gcf, "currentaxes", hax = axes());
  set(hax, "position", [left, top, width, height]);

endfunction

%!demo
%!  clf reset;
%!  N = 5;
%!  M = 3;
%!  for i = 1:N
%!    for j = 1:M
%!      PlotGrid([0.1,0.9], [0.1,0.8], 0.05, 0.03, N, M, i, j);
%!      text(0.5,0.5,sprintf("%g,%g",i,j));
%!    endfor
%! endfor
