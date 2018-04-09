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

## -*- texinfo -*-
## @deftypefn {Function File} {} ezprint ( @var{filepath}, @var{opt}, @var{val}, @dots{} )
##
## Print a figure to a file, with some common options.
##
## @heading Options
##
## @table @code
## @item width
## width of printed figure, in points
##
## @item aspect
## aspect ratio of @var{height} to @var{width} (default: 0.75)
##
## @item height
## @var{height} of printed figure, in points (overrides "@var{aspect}")
##
## @item dpi
## resolution of printed figure, in dots per inch (default: 300)
##
## @item fontsize
## font size of printed figure, in points (default: 10)
##
## @item linescale
## factor to scale line @var{width} of figure objects (default: 1)
##
## @item texregex
## regular expression to apply to TeX output files
##
## @end table
##
## @end deftypefn

function ezprint(filepath, varargin)

  ## parse options
  parseOptions(varargin,
               {"width", "real,strictpos,scalar"},
               {"aspect", "real,strictpos,scalar", 0.75},
               {"height", "real,strictpos,scalar", []},
               {"dpi", "integer,strictpos,scalar", 300},
               {"fontsize", "integer,strictpos,scalar", 10},
               {"linescale", "real,strictpos,scalar", 1.0},
               {"texregex", "char", ""},
               []);

  ## can only reliably switch to gnuplot with Octave < 4.0.0
  if !strncmp(version, "3.", 2) && !strcmp(get(gcf, "__graphics_toolkit__"), "gnuplot")
    error("%s: only works with gnuplot", funcName);
  endif

  ## set width and height, converting from points to inches
  width = width / 72;
  if isempty(height)
    height = width * aspect;
  else
    height = height / 72;
  endif

  ## set figure width and height
  paperpos = get(gcf, "paperposition");
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

  ## set graphics toolkit to gnuplot
  toolkit = get(gcf, "__graphics_toolkit__");
  unwind_protect
    graphics_toolkit(gcf, "gnuplot");

    ## scale figure line widths
    H = findall(gcf, "-property", "linewidth");
    linewidths = get(H, "linewidth");
    unwind_protect
      set(H, {"linewidth"}, cellfun(@(x) x*linescale, linewidths, "uniformoutput", false));

      ## print figure
      print(sprintf("-d%s", device), ...
            sprintf("-r%d", dpi), ...
            sprintf("-FHelvetica:%i", fontsize), ...
            filepath);

      ## reset scale figure line widths
    unwind_protect_cleanup
      set(H, {"linewidth"}, linewidths);
    end_unwind_protect

    ## reset graphics toolkit to gnuplot
  unwind_protect_cleanup
    graphics_toolkit(gcf, toolkit);
  end_unwind_protect

  if strcmp(fileext, ".tex")

    ## escape slashes in 'texregex'
    texregex = strrep(texregex, "\\", "\\\\");

    ## get the name of the just-printed EPS file
    epsfilepath = fullfile(filedir, strcat(filename, "-inc.eps"));

    ## run 'sed' on EPS file to:
    ## - remove the CreationDate informatio, so that re-generated figures do
    ##   not show up as changed in e.g. git unless their content has changed
    [status, output] = system(cstrcat("sed -i.bak '\\!^\\(%%\\| */\\)CreationDate!d' ", epsfilepath));
    if status != 0
      error("%s: 'sed' failed", funcName);
    else
      unlink ( strcat(epsfilepath, ".bak" ) );
    endif

    ## run 'sed' on TeX file to:
    ## - replace 10^0 with 1, and 10^1 with 10, in plot tick labels in the TeX file
    ## - apply any user-specified regular expression in 'texregex'
    [status, output] = system(cstrcat("sed -i.bak 's|\\$10\\^{0}\\$|$1$|g;s|\\$10\\^{1}\\$|$10$|g;", texregex, "' ", filepath));
    if status != 0
      error("%s: 'sed' failed", funcName);
    else
      unlink ( strcat( filepath, ".bak" ) );
    endif

  else
    assert(isempty(texregex), "'texregex' only works with TeX figures");
  endif

endfunction

%!test
%!  graphics_toolkit gnuplot;
%!  figname = strcat(tempname(tempdir), ".tex");
%!  fig = figure("visible", "off");
%!  plot(0:100, mod(0:100, 10));
%!  ezprint(figname, "width", 100);
%!  close(fig);
%!  assert(exist(figname, "file"));
