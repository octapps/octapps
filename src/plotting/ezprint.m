## Copyright (C) 2012 Karl Wette
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

## Print a figure to a file, with some common options.
## Usage:
##   ezprint(filepath, ...)
## Options:
##   "width": width of printed figure, in points
##   "aspect": aspect ratio of height to width (default: 0.75)
##   "dpi": resolution of printed figure, in dots per inch (default: 300)
##   "fontsize": font size of printed figure, in points (default: 10)
##   "linescale": factor to scale line width of figure objects (default: 1)

function ezprint(filepath, varargin)

  ## parse options
  parseOptions(varargin,
               {"width", "real,strictpos,scalar"},
               {"aspect", "real,strictpos,scalar", 0.75},
               {"dpi", "integer,strictpos,scalar", 300},
               {"fontsize", "integer,strictpos,scalar", 10},
               {"linescale", "real,strictpos,scalar", 1.0},
               []);

  ## convert width from points to inches
  width = width / 72;

  ## scale figure line widths
  H = findall(gcf, "-property", "linewidth");
  for i = 1:length(H);
    set(H(i), "linewidth", get(H(i), "linewidth") * linescale);
  endfor

  ## set figure width and height
  paperpos = get(gcf, "paperposition");
  height = aspect * width;
  if width > height
    set(gcf, "paperorientation", "landscape");
  else
    set(gcf, "paperorientation", "portrait");
  endif
  set(gcf, "papertype", "<custom>");
  set(gcf, "papersize", [width, height]);
  set(gcf, "paperposition", [0, 0, width, height]);

  ## select printing device from file extension
  [filedir, filename, fileext] = fileparts(filepath);
  if isempty(fileext)
    error("%s: file '%s' has no extension", funcName, filepath);
  else
    switch fileext
      case ".tex"
        device = "epslatexstandalone";
      otherwise
        device = fileext(2:end);
    endswitch
  endif

  ## print figure
  print(sprintf("-d%s", device), ...
        sprintf("-r%d", dpi), ...
        sprintf("-F:%i", fontsize), ...
        filepath);

  ## undo scale figure line widths
  for i = 1:length(H);
    set(H(i), "linewidth", get(H(i), "linewidth") / linescale);
  endfor

  if strcmp(fileext, ".tex")

    ## get the name of the just-printed EPS file
    epsfilepath = fullfile(filedir, strcat(filename, "-inc.eps"));

    ## remove the CreationDate information from the EPS file, so that re-generated
    ## figures do not show up as changed in e.g. git unless their content has changed
    sedcmd = sprintf("sed --in-place '\\!^\\(%%%%\\| */\\)CreationDate!d' %s", epsfilepath);
    [sedstatus, sedoutput] = system(sedcmd);
    if sedstatus != 0
      error("%s: command '%s' failed", funcName, sedcmd);
    endif

  endif

endfunction
