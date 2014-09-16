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

## Given the lines lines [x, y1], [x, y2], ..., reduce the number of
## points in each line to 'Nmax'. Points are eliminated based on
## whether they are redundant with other points in each line.
## Usage:
##   [X, [Y1, Y2, ...]] = simplifyLines(x, [y1, y2, ...], Nmax)
## where:
##   x, y1, y2, ... = Input lines
##   Nmax           = Number of points to keep
##   X, Y1, Y2, ... = Output lines

## Contains code from 'simplifypolyline.m' from 'geometry' package v1.5.0:
##
%% Copyright (c) 2012 Juan Pablo Carbajal <carbajal@ifi.uzh.ch>
%%
%%    This program is free software: you can redistribute it and/or modify
%%    it under the terms of the GNU General Public License as published by
%%    the Free Software Foundation, either version 3 of the License, or
%%    any later version.
%%
%%    This program is distributed in the hope that it will be useful,
%%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%    GNU General Public License for more details.
%%
%%    You should have received a copy of the GNU General Public License
%%    along with this program. If not, see <http://www.gnu.org/licenses/>.

function [X, Y] = simplifyLines(x, y, Nmax)

  ## check for geometry package
  assert(exist("distancePointEdge") == 2, "%s: needs 'geometry' package", funcName);

  ## check input
  assert(iscolumn(x));
  assert(ismatrix(y) && size(y, 1) == length(x));
  assert(fix(Nmax) == Nmax && Nmax > 2);

  ## build vector of indices of 'x' to keep
  idx = [1, length(x)];
  while length(idx) < Nmax

    ## loop over lines 'y'
    maxdist = -inf;
    for j = 1:size(y, 2)

      ## find point with maximum distance
      [dist_j, ii_j] = maxdistance([x, y(:,j)], idx);
      [maxdist_j maxii_j] = max(dist_j);

      ## keep the maximum distance over 'y'
      if maxdist_j > maxdist
        maxdist = maxdist_j;
        maxii = maxii_j;
        ii = ii_j;
      endif

    endfor

    ## save index
    idx(end+1) = ii(maxii);
    idx = sort(idx);

  endwhile

  ## return only indexed values of 'x' and 'y'
  X = x(idx);
  Y = y(idx, :);

endfunction


function [dist ii] = maxdistance (p, idx)

  %% Separate the groups of points according to the edge they can divide.
  func = @(x,y) x:y;
  idxc   = arrayfun (func, idx(1:end-1), idx(2:end), "UniformOutput",false);
  points = cellfun (@(x)p(x,:), idxc, "UniformOutput",false);

  %% Build the edges
  edges = [p(idx(1:end-1),:) p(idx(2:end),:)];
  edges = mat2cell (edges, ones(1,size(edges,1)), 4)';

  %% Calculate distance between the points and the corresponding edge
  [dist ii] = cellfun(@dd, points,edges,idxc);

endfunction


function [dist ii] = dd (p,e,idx)
  [d pos] = distancePointEdge(p,e);
  [dist ii] = max(d);
  ii = idx(ii);
endfunction
