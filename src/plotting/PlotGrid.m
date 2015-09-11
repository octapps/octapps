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
##   PlotGrid(rowrange, colrange, rowspace, colspace, rowfigs, colfigs)
##   hax = PlotGrid(rowidx, colidx)
## where:
##   {row|col}range: range of figure coordinates in [0,1] to be covered by grid in this dimension
##   {row|col}space: spacing between figures in this dimension
##   {row|col}figs: number of figures in this dimension
##   {row|col}idx: figure index in this dimension

function hax = PlotGrid(varargin)

  switch length(varargin)

    case 6   ## initial setup

      ## parse input
      [rowrange, colrange, rowspace, colspace, rowfigs, colfigs] = deal(varargin{:});
      assert(isvector(rowrange) && length(rowrange) == 2);
      assert(isscalar(rowspace) && rowspace >= 0);
      assert(isscalar(rowfigs) && 1 <= rowfigs && mod(rowfigs, 1) == 0);
      assert(isvector(colrange) && length(colrange) == 2);
      assert(isscalar(colspace) && colspace >= 0);
      assert(isscalar(colfigs) && 1 <= colfigs && mod(colfigs, 1) == 0);

      ## create struct to store grid
      grid = struct;
      grid.rowfigs = rowfigs;
      grid.colfigs = colfigs;

      ## compute row position
      for rowidx = 1:rowfigs
        top0 = min(rowrange);
        dtop = (range(rowrange) + rowspace) / rowfigs;
        grid.top(rowidx) = top0 + dtop * (rowfigs - rowidx);
        grid.height(rowidx) = (range(rowrange) - rowspace * (rowfigs - 1)) / rowfigs;
      endfor

      ## compute column position
      for colidx = 1:colfigs
        left0 = min(colrange);
        dleft = (range(colrange) + colspace) / colfigs;
        grid.left(colidx) = left0 + dleft * (colidx - 1);
        grid.width(colidx) = (range(colrange) - colspace * (colfigs - 1)) / colfigs;
      endfor

      ## setup figure and store grid in property
      clf reset;
      try
        set(gcf, "plotgrid", grid);
      catch
        addproperty("plotgrid", gcf, "any", grid);
      end_try_catch

    case 2   ## create subfigure

      ## retrieve grid from figure property
      try
        grid = get(gcf, "plotgrid");
      catch
        error("figure has not been set up with %s()", funcName);
      end_try_catch

      ## parse input
      [rowidx, colidx] = deal(varargin{:});
      assert(isscalar(rowidx) && 1 <= rowidx && mod(rowidx, 1) == 0 && rowidx <= grid.rowfigs);
      assert(isscalar(colidx) && 1 <= colidx && mod(colidx, 1) == 0 && colidx <= grid.colfigs);

      ## create subfigure
      set(gcf, "currentaxes", hax = axes());
      set(hax, "position", [grid.left(colidx), grid.top(rowidx), grid.width(colidx), grid.height(rowidx)]);

    otherwise
      error("%s() takes either 6 or 2 arguments", funcName);
      print_usage();

  endswitch

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
