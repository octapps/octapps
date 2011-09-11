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

## Set margins around current axes, and add axis labels
## Syntax:
##   PlotMarginsAndLabels(xl, yb, xr, yt, xlbl, ylbl)
## where:
##   xl,xr = x-direction left/right margins
##   yb,yt = y-direction bottom/top margins
##   xlbl  = x-axis label
##   ylbl  = y-axis label

function PlotMarginsAndLabels(xl, yb, xr, yt, xlbl, ylbl, p=0.7)

  ## extend of axes in x and y directions
  xe = 1 - xl - xr;
  ye = 1 - yb - yt;

  ## set axes position
  set(gca, "position", [xl, yb, xe, ye]);

  ## create axes labels, centered on the appropriate axis,
  ## positioned within margins, and rotated (y-axis)
  text(0.5, -p*yb/ye, xlbl,
       "horizontalalignment", "center",
       "verticalalignment", "middle",
       "units", "normalized");
  text(-p*xl/xe, 0.5, ylbl,
       "horizontalalignment", "center",
       "verticalalignment", "middle",
       "units", "normalized",
       "rotation", 90);
  
endfunction
