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

## Build a TeX table from a cell array specification.
## Usage:
##   tex = buildTeXTable(spec, [numfmt="g"])
## where
##   tex    = TeX table as a string
##   spec   = table specification
##   numfmt = number format used by num2TeX to convert numbers to strings
## The specification is a 1-D cell array of rows, the elements of which are
## 1-D cell arrays of columns. Further nesting of cell arrays may be used
## to set up elements which span multiple columns. TeX numbers containing
## periods are split into 2 columns to align numbers at the period.
## Run "demo buildTeXTable" for some examples.

function tex = buildTeXTable(spec, numfmt="g")

  ## check input
  assert(iscell(spec), "%s: 'spec' spec must be a cell array", funcName);
  assert(ischar(numfmt), "%s: 'numfmt' must be a string", funcName);

  ## parse table specification
  spec = parse_spec(spec, numfmt);

  ## flatten table specification into a 2-D cell array
  tbl = flatten_cell_array(spec{1});
  for i = 2:length(spec)

    ## check length and contents of row
    tblrow = flatten_cell_array(spec{i});
    assert(any(cellfun(@(x) !isempty(x), tblrow)),
           "%s: 'spec' row #%i is completely empty", funcName, i);
    assert(length(tblrow) == size(tbl, 2),
           "%s: 'spec' rows have inconsistent number of columns", funcName);

    ## concatenate row
    tbl(i, :) = tblrow;

  endfor

  ## build TeX table columns alignment string
  texalign = cell(1, size(tbl, 2));
  for j = 1:size(tbl, 2)
    for i = 1:size(tbl, 1)
      if !isempty(tbl{i, j}) && tbl{i, j}(1) != "\\"
        if tbl{i, j}(1) == "$"
          if tbl{i, j}(end) == "$"
            texalign{j} = "r";   ## TeX numbers are aligned right
          else
            texalign{j} = "r";   ## LHS of period-split TeX numbers are aligned right
            tbl{i, j} = strcat(tbl{i, j}, "$");
          endif
        else
          if tbl{i, j}(end) == "$"
            texalign{j} = "@{.}l";   ## RHS of period-split TeX numbers are aligned left, with period
            tbl{i, j} = strcat("$", tbl{i, j});
          elseif j == 1
            texalign{j} = "l";   ## Text in column 1 are aligned left
          else
            texalign{j} = "r";   ## Text in other columns are aligned right
          endif
        endif
      endif
    endfor
    assert(!isempty(texalign{j}),
           "%s: could not decide alignment for 'tbl' column #%i", funcName, j);
  endfor

  ## build TeX table
  tex = {"\\begin{tabular}{", texalign{:}, "}\n"};
  row = 0;
  for i = 1:size(tbl, 1)

    ## get indices of non-empty row elements
    jj = find(cellfun(@(x) !isempty(x), tbl(i, :)));
    jj = [jj, size(tbl, 2) + 1];

    ## if row is just a single TeX command, e.g. \hline, print it and continue
    if length(jj) == 2 && tbl{i, jj(1)}(1) == "\\"
      tex{end+1} = sprintf("%s\n", tbl{i, jj(1)});
      continue
    endif
    ++row;

    ## add column separators for any initial empty columns
    for s = 1:jj(1)-1
      tex{end+1} = " & ";
    endfor

    ## iterate over columns
    for k = 1:length(jj) - 1

      ## add column separator
      if k > 1
        tex{end+1} = " & ";
      endif

      ## if not spanning multiple columns, just print element and continue
      cols = jj(k+1) - jj(k);
      if cols == 1
        tex{end+1} = tbl{i, jj(k)};
        continue
      endif

      ## if elements are TeX numbers ...
      if tbl{i, jj(k)}(1) == "$"
        
        ## print element in 1st column, then add empty columns
        tex{end+1} = tbl{i, jj(k)};
        for c = 2:cols
          tex{end+1} = " & ";
        endfor
          
      else   ## otherwise, use \multicolumn
          
        ## Text in column 1, row >1 are aligned left; other columns are centered
        if k == 1 && row > 1
          multicolalign = "l";
        else
          multicolalign = "c";
        endif
        
        ## print \multicolumn command
        tex{end+1} = sprintf("\\multicolumn{%i}{%s}{%s}", cols, multicolalign, tbl{i, jj(k)});
        
      endif

    endfor

    ## end row with \\ (if not last row) and newline
    if i < size(tbl, 1)
      tex{end+1} = " \\\\";
    endif
    tex{end+1} = "\n";

  endfor
  tex{end+1} = "\\end{tabular}\n";

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
    if !iscell(spec{i}) && !isempty(spec{i})

      ## if element is numeric, convert to a TeX number
      if isnumeric(spec{i})
        assert(isscalar(spec{i}), "%s: numeric elements of 'spec' must be scalars", funcName);
        spec{i} = num2TeX(spec{i}, numfmt);
      endif

      ## check that element is a string
      assert(ischar(spec{i}), "%s: non-empty elements of 'spec' must be strings", funcName);

      ## if element is a TeX number with a period, split it
      if length(spec{i}) > 2 && spec{i}(1) == "$" && spec{i}(end) == "$"
        j = find(spec{i} == ".");
        if !isempty(j)
          spec{i} = {spec{i}(1:j-1), spec{i}(j+1:end)};
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
  for i = 1:length(spec)
    [spec{i}{length(spec{i})+1:cellmaxlen}] = deal([]);
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


function fc = flatten_cell_array(c)

  ## recursively flatten the cell array 'c'
  assert(iscell(c));
  fc = {};
  for i = 1:length(c)
    if iscell(c{i})
      fc = {fc{:}, flatten_cell_array(c{i}){:}};
    else
      fc{end+1} = c{i};
    endif
  endfor
  fc = reshape(fc, 1, []);

endfunction


%!demo
%! disp(buildTeXTable({{1, 2, 3}, {4, 5, 6}}))

%!demo
%! disp(buildTeXTable({"\\hline", {1, 2, 3}, {4, 5, 6}, "\\hline"}))

%!demo
%! disp(buildTeXTable({"\\hline", {1, 2.2, 3}, {4, 5, 6}, "\\hline"}))

%!demo
%! disp(buildTeXTable({"\\hline", {"A", "B", "C"}, "\\hline", {1, 2.2, 3}, {4, 5, 6}, "\\hline"}))

%!demo
%! disp(buildTeXTable({"\\hline", ...
%!                    {[], "A", "B"}, ...
%!                    {[], {"A1", "A2"}, "B"}, ...
%!                    "\\hline", ...
%!                    {"x", {1, 2.2}, 3}, ...
%!                    {"y", {4, 5}, 6}, ...
%!                    "\\hline"}))
