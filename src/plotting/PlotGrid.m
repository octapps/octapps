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
## @deftypefn {Function File} {} PlotGrid ( @var{rowrange}, @var{colrange}, @var{rowspace}, @var{colspace}, @var{rowfigs}, @var{colfigs} )
## @deftypefnx{Function File} {@var{hax} =} PlotGrid ( @var{rowidx}, @var{colidx} )
## @deftypefnx{Function File} {} PlotGrid ( @var{range}, @var{space}, @var{figs} )
## @deftypefnx{Function File} {@var{hax} =} PlotGrid ( @var{idx} )
##
## A more flexible replacement for @command{subplot()}.
##
## @heading Arguments
##
## @table @var
## @item [row|col]range
## range of figure coordinates in [0,1] to be covered by grid [in this dimension]
##
## @item [row|col]space
## spacing between figures [in this dimension]
##
## @item [row|col]figs
## number of figures [in this dimension]
##
## @item [row|col]idx
## figure index [in this dimension]
##
## @end table
##
## @end deftypefn

function hax = PlotGrid(varargin)

  switch length(varargin)

    case {6, 3}   ## initial setup

      ## parse input
      if length(varargin) == 3
        [range, space, figs] = deal(varargin{1:3});
        assert(isvector(range) && length(range) == 2);
        assert(isscalar(space) && space >= 0);
        assert(isscalar(figs) && 1 <= figs && mod(figs, 1) == 0);
        rowrange = colrange = range;
        rowspace = colspace = space;
        rowfigs = round(sqrt(figs));
        colfigs = ceil(figs / rowfigs);
        clear range space;
      else
        [rowrange, colrange, rowspace, colspace, rowfigs, colfigs] = deal(varargin{1:6});
        assert(isvector(rowrange) && length(rowrange) == 2);
        assert(isscalar(rowspace) && rowspace >= 0);
        assert(isvector(colrange) && length(colrange) == 2);
        assert(isscalar(colspace) && colspace >= 0);
        assert(isscalar(rowfigs) && 1 <= rowfigs && mod(rowfigs, 1) == 0);
        assert(isscalar(colfigs) && 1 <= colfigs && mod(colfigs, 1) == 0);
        figs = rowfigs * colfigs;
      endif

      ## create struct to store grid
      grid = struct;
      grid.rowfigs = rowfigs;
      grid.colfigs = colfigs;
      grid.figs = figs;
      grid.haxes = nan(rowfigs, colfigs);

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
      clf;
      try
        set(gcf, "plotgrid", grid);
      catch
        addproperty("plotgrid", gcf, "any", grid);
      end_try_catch

    case {2, 1}   ## create subfigure

      ## retrieve grid from figure property
      try
        grid = get(gcf, "plotgrid");
      catch
        error("figure has not been set up with %s()", funcName);
      end_try_catch

      ## parse input
      if length(varargin) == 1
        idx = varargin{1};
        assert(isscalar(idx) && 1 <= idx && mod(idx, 1) == 0 && idx <= grid.figs);
        rowidx = floor((idx - 1) / grid.colfigs) + 1;
        colidx = mod((idx - 1), grid.colfigs) + 1;
        clear idx;
      else
        [rowidx, colidx] = deal(varargin{1:2});
        assert(isscalar(rowidx) && 1 <= rowidx && mod(rowidx, 1) == 0 && rowidx <= grid.rowfigs);
        assert(isscalar(colidx) && 1 <= colidx && mod(colidx, 1) == 0 && colidx <= grid.colfigs);
      endif

      ## create axes if needed
      hax = grid.haxes(rowidx, colidx);
      if isnan(hax)
        hax = grid.haxes(rowidx, colidx) = axes();
        set(gcf, "plotgrid", grid);
      endif

      ## (re)set axes position
      set(hax, "position", [grid.left(colidx), grid.top(rowidx), grid.width(colidx), grid.height(rowidx)]);

      ## select axes
      set(gcf, "currentaxes", hax);

    otherwise
      error("%s: incorrect number of input arguments", funcName);
      print_usage();

  endswitch

endfunction
%!test
%!  fig = figure("visible", "off");
%!  N = 5;
%!  M = 3;
%!  PlotGrid([0.1,0.9], [0.1,0.8], 0.05, 0.03, N, M);
%!  for i = 1:N
%!    for j = 1:M
%!      PlotGrid(i, j);
%!      text(0.5,0.5,sprintf("%g,%g",i,j));
%!    endfor
%!  endfor
%!  close(fig);
