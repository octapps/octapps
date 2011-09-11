## Copyright (C) 2011 Karl Wette
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
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## Make logarithmic tick labels for current axes
## Syntax:
##   MakeLogTickLabels(axes)
## where:
##   axes = "x","y","z","xy",etc.

function MakeLogTickLabels(axes)

  ## check input
  assert(ischar(axes));

  ## loop over axes
  for a = axes

    ## get axis ticks
    ticks = get(gca, strcat(a, "tick"));
    
    ## make logarithmic tick labels
    ticklabels = cell(size(ticks));
    for i = 1:length(ticks)
      switch ticks(i)
        case 0
          ticklabels{i} = "$1$";
        case 1
          ticklabels{i} = "$10$";
        otherwise
          ticklabels{i} = sprintf("$10^{%d}$", ticks(i));
      endswitch
    endfor
    
    ## set axis tick labels
    set(gca, strcat(a, "ticklabel"), ticklabels);

  endfor

endfunction
