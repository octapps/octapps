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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{tex} =} buildTeXTable ( @var{spec}, @var{opt}, @var{val}, @dots{} )
##
## Build a TeX table from a cell array specification.
##
## @heading Arguments
##
## @table @var
## @item tex
## TeX table as a string
##
## @item spec
## table specification
##
## @end table
##
## @heading Options
##
## @table @code
## @item numfmt
## num2TeX() format for formatting numbers [default: "g"]
##
## @item tblwidth
## TeX command specifying table width [optional]
##
## @item fillcols
## space-filling columns: "first", "all", "byrow" or "none" [default]
##
## @item fillcolrow
## which row to use when setting space-filling columns with "byrow"
##
## @item defcolsep
## default non-space-filling column separation [default: 1]
##
## @end table
##
## The table specification @var{spec} is a 1-D cell array of rows, the elements of
## which are 1-D cell arrays of columns. Further nesting of cell arrays may be
## used to set up elements which span multiple columns. TeX numbers containing
## periods are split into 2 columns to align numbers at the period.
##
## Run @code{demo buildTeXTable} for some examples.
##
## @end deftypefn

function tex = buildTeXTable(spec, varargin)

  ## check input
  assert(iscell(spec), "%s: 'spec' spec must be a cell array", funcName);
  parseOptions(varargin,
               {"numfmt", "char", "g"},
               {"tblwidth", "char", []},
               {"fillcols", "char", "none"},
               {"fillcolrow", "strictpos,integer", []},
               {"defcolsep", "real,strictpos,scalar", 1},
               []);

  ## parse table specification
  spec = parse_spec(spec, numfmt);

  ## flatten table specification into a 2-D cell array
  tbl = cellflatten(spec{1});
  for i = 2:length(spec)

    ## check length and contents of row
    tblrow = cellflatten(spec{i});
    assert(any(cellfun(@(x) !isempty(x), tblrow)),
           "%s: 'spec' row #%i is completely empty", funcName, i);
    assert(length(tblrow) == size(tbl, 2),
           "%s: 'spec' rows have inconsistent number of columns", funcName);

    ## concatenate row
    tbl(i, :) = tblrow;

  endfor

  ## build TeX table column alignment and spacing
  texalign = cell(1, size(tbl, 2));
  texcolsep = cell(1, size(tbl, 2));
  for j = 1:size(tbl, 2)
    for i = 1:size(tbl, 1)

      ## skip empty elements and TeX command elements
      if isempty(tbl{i, j}) || (ischar(tbl{i, j}) && tbl{i, j}(1) == "\\")
        continue
      endif

      if isstruct(tbl{i, j})

        ## if element is a split TeX number, get alignment and spacing from it
        if isfield(tbl{i, j}, "align")
          texalign{j} = tbl{i, j}.align;
        endif
        if isfield(tbl{i, j}, "colsep")
          texcolsep{j} = tbl{i, j}.colsep;
        endif

      elseif j == 1

        ## if in column 1, align left
        texalign{j} = "l";

      endif

    endfor

    ## align right by default
    if isempty(texalign{j})
      texalign{j} = "r";
    endif

  endfor

  ## add column spacing required by 'fillcols'
  switch fillcols
    case "first"
      jj = 1;
    case "all"
      jj = 1:length(texcolsep);
    case "byrow"
      if fillcolrow > size(tbl, 1)
        error("%s: value of 'fillcolrow' exceeds number of table rows", funcName);
      endif
      jj = find(cellfun(@(x) !isempty(x), tbl(fillcolrow, :))) - 1;
      jj(jj < 1) = [];
    case "none"
      jj = [];
    otherwise
      error("%s: unknown column fill option '%s'", funcName, fillcols);
  endswitch
  for j = jj
    if isempty(texcolsep{j})
      texcolsep{j} = "\\fill";
    endif
  endfor

  ## add default column spacings
  texcolsep{end} = [];
  for j = 1:1:length(texcolsep)
    if isempty(texcolsep{j})
      texcolsep{j} = sprintf("%g\\tabcolsep", defcolsep + 1);
    endif
  endfor

  ## start TeX table environment
  if !isempty(tblwidth)
    textblenv = "tabular*";
    tex = {"\\begin{", textblenv, "}{", tblwidth, "}"};
  else
    textblenv = "tabular";
    tex = {"\\begin{", textblenv, "}"};
  endif
  tex{end+1} = "{";
  for j = 1:1:length(texalign)
    tex{end+1} = sprintf("%s@{\\extracolsep{%s}}", texalign{j}, texcolsep{j});
  endfor
  tex{end+1} = "}\n";

  ## build TeX table
  row = 0;
  for i = 1:size(tbl, 1)

    ## get indices of non-empty row elements
    jj = find(cellfun(@(x) !isfield(x, "fill"), tbl(i, :)));
    jj = [jj, size(tbl, 2) + 1];

    ## if row is just a single TeX command, e.g. \hline, print it and continue
    if length(jj) == 2 && tbl{i, jj(1)}(1) == "\\"
      tex{end+1} = sprintf("%s\n", tbl{i, jj(1)});
      continue
    endif
    ++row;

    ## add column separators for any initial empty columns
    col = 0;
    for s = 1:jj(1)-1
      tex{end+1} = " & ";
      ++col;
    endfor

    ## iterate over columns
    for k = 1:length(jj) - 1
      ++col;

      ## add column separator
      if k > 1
        tex{end+1} = " & ";
      endif

      ## if not spanning multiple columns, just print element and continue
      cols = jj(k+1) - jj(k);
      if cols == 1
        if isstruct(tbl{i, jj(k)})   ## if element is a split TeX number, print value
          tex{end+1} = tbl{i, jj(k)}.value;
        elseif isempty(tbl{i, jj(k)})
          tex{end+1} = "";
        else
          assert(ischar(tbl{i, jj(k)}), "%s: encountered non-string TeX fragment", funcName);
          tex{end+1} = tbl{i, jj(k)};
        endif
        continue
      endif

      ## if table element is empty, print empty columns
      if isempty(tbl{i, jj(k)})
        [tex{end+(1:cols-1)}] = deal(" & ");
        continue
      endif

      ## otherwise use \multicolumn
      if col == 1 && row > 1 && length(jj) > 2
        ## text in column 1, row >1, not spanning an entire row are aligned left
        multicolalign = "l";
      else
        ## text in all other columns are centered
        multicolalign = "c";
      endif
      if isstruct(tbl{i, jj(k)})
        error("%s: cannot split number '%s' over multiple columns", funcName, tbl{i, jj(k)}.value);
      endif
      tex{end+1} = sprintf("\\multicolumn{%i}{%s}{%s}", cols, multicolalign, tbl{i, jj(k)});

    endfor

    ## end row with \\ (if not last row) and newline
    if i < size(tbl, 1)
      tex{end+1} = " \\\\";
    endif
    tex{end+1} = "\n";

  endfor

  ## end TeX table environment
  tex = {tex{:}, "\\end{", textblenv, "}\n"};

  ## concatenate TeX table string
  tex = cstrcat(tex{:});

endfunction

function spec = parse_spec(spec, numfmt)

  ## check that 'spec' is a 1-D cell array
  assert(isvector(spec), "%s: 'spec' must be a 1-D cell array", funcName);

  ## save if any elements of 'spec' are cell arrays
  anycell = any(cellfun(@(x) iscell(x), spec));

  ## check cell array elements of 'spec'
  celllen = 0;
  for i = 1:length(spec)
    if iscell(spec{i})

      ## check that element is a 1-D cell array
      assert(isvector(spec{i}),
             "%s: cell array elements of 'spec' must be 1-D cell arrays", funcName);

      ## check that cell array elements have equal length
      if celllen == 0
        celllen = length(spec{i});
      else
        assert(celllen == length(spec{i}),
               "%s: cell array elements of 'spec' must have equal length", funcName);
      endif

    endif
  endfor

  ## check scalar elements of 'spec'
  for i = 1:length(spec)

    if !iscell(spec{i}) && !isstruct(spec{i}) && !isempty(spec{i})

      ## if element is numeric, convert to a TeX number
      if isnumeric(spec{i})
        assert(isscalar(spec{i}), "%s: numeric elements of 'spec' must be scalars", funcName);
        spec{i} = num2TeX(spec{i}, numfmt);
      endif

      ## check that element is a string
      assert(ischar(spec{i}), "%s: non-empty elements of 'spec' must be strings", funcName);

      ## if element is a TeX number with a period, split it
      if length(find(spec{i} == "$")) == 2 && all(spec{i}([1,end]) == "$")
        j = find(spec{i} == ".");
        if !isempty(j)
          spec{i} = {struct("align", "r", "colsep", "0pt", "value", strcat(spec{i}(1:j-1), "$")), ...
                     struct("align", "l", "value", strcat("$", spec{i}(j:end)))};
        endif
      endif

    endif
  endfor

  ## make all elements of 'spec' into cell arrays, and determine maximum length
  cellmaxlen = 0;
  for i = 1:length(spec)
    if !iscell(spec{i})
      spec{i} = {spec{i}};
    endif
    cellmaxlen = max(cellmaxlen, length(spec{i}));
  endfor

  ## pad out all cell array elements of 'spec' to the same length
  ## with special 'fill' struct, which determine column spanning
  for i = 1:length(spec)
    [spec{i}{length(spec{i})+1:cellmaxlen}] = deal(struct("fill", true));
  endfor

  ## if any elements of (original) 'spec' are cell arrays
  ## iterate over all 2nd-level elements of 'spec'
  if anycell
    for j = 1:cellmaxlen

      ## get all 2nd-level elements of 'spec' (j) at constant 1st level (i)
      specj = cell(1, length(spec));
      for i = 1:length(spec)
        specj{i} = spec{i}{j};
      endfor

      ## recursively parse 'specj'
      specj = parse_spec(specj, numfmt);

      ## assign returned 'specj' back to 'spec'
      for i = 1:length(spec)
        spec{i}{j} = specj{i};
      endfor

    endfor

  endif

endfunction

%!test
%! buildTeXTable({{1, 2, 3}, {4, 5, 6}})
%!test
%! buildTeXTable({"\\hline", {1, 2, 3}, {4, 5, 6}, "\\hline"})
%!test
%! buildTeXTable({"\\hline", {1, 2.2, 3}, {4, 5, 6}, "\\hline"})
%!test
%! buildTeXTable({"\\hline", {"A", "B", "C"}, "\\hline", {1, 2.2, 3}, {4, 5, 6}, "\\hline"})
%!test
%! buildTeXTable({"\\hline", {[], "A", "B"}, {[], {"A1", "A2"}, "B"}, "\\hline", {"x", {1, 2.2}, 3}, {"y", {4, 5}, 6}, "\\hline"})
