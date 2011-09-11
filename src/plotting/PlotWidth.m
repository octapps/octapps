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

## Generate options for 'print' for producing a figure of a given width
## Syntax:
##   opts = PlotWidth(width, dpi)
## where:
##   width = width in points
##   dpi   = figure resolution (default: 300)
## Usage:
##   print(PlotWidth(width){:},...)

function opts = PlotWidth(width, dpi=300)

  ## convert width from points to inches
  width /= 72;

  ## determine height via golden ratio
  golden = 0.5*(1 + sqrt(5));
  height = width / golden;

  ## generate 'print' options
  opts = cell(1, 2);
  opts{1} = sprintf("-r%d", dpi);
  opts{2} = sprintf("-S%d,%d", floor([width,height]*dpi));

endfunction
