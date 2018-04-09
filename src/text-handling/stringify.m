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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{s} =} stringify ( @var{x} )
##
## Convert an Octave value @var{x} into a string expression, which can be re-used
## as input, i.e. @code{eval(stringify(@var{x}))} should re-create @var{x}.
## @end deftypefn

function s = stringify(x)

  ## switch on the class of x
  switch class(x)

    case "char"

      ## strings: if x == $(...), return literal x; otherwise
      ## double-quote x, escaping special characters
      if length(x) >= 3 && strcmp(x(1:2), "$(") && all(x(3:end-1) != "(") && all(x(3:end-1) != ")") && x(end) == ")"
        s = x;
      else
        x = strrep(x, "\\", "\\\\");
        x = strrep(x, "\"", "\\\"");
        x = strrep(x, "\'", "\\\'");
        x = strrep(x, "\0", "\\0");
        x = strrep(x, "\a", "\\a");
        x = strrep(x, "\b", "\\b");
        x = strrep(x, "\f", "\\f");
        x = strrep(x, "\n", "\\n");
        x = strrep(x, "\r", "\\r");
        x = strrep(x, "\t", "\\t");
        x = strrep(x, "\v", "\\v");
        s = strcat("\"", x, "\"");
      endif

    case "cell"
      ## cells: create {} expression,
      ## calling stringify() for each element
      if length(size(x)) > 2
        error("cannot stringify cell arrays with >2 dimensions");
      endif
      s = "{";
      if numel(x) > 0
        for i = 1:size(x, 1)
          if i > 1
            s = strcat(s, ";");
          endif
          for j = 1:size(x, 2)
            if j > 1
              s = strcat(s, ",");
            endif
            s = strcat(s, stringify(x{i, j}));
          endfor
        endfor
      endif
      s = strcat(s, "}");

    case "struct"
      ## structs: create struct() expression,
      ## calling stringify() for each field value
      n = fieldnames(x);
      s = "struct(";
      if length(n) > 0
        s = strcat(s, sprintf("\"%s\",%s", n{1}, stringify({x.(n{1})})));
        for i = 2:length(n)
          s = strcat(s, sprintf(",\"%s\",%s", n{i}, stringify({x.(n{i})})));
        endfor
      endif
      s = strcat(s, ")");

    case "function_handle"
      ## functions
      s = func2str(x);

    otherwise
      ## otherwise, try mat2str() for numbers, logical, matrices, etc.
      try
        s = mat2str(x, 16);
      catch
        ## if mat2str() fails, class is not supported
        error("cannot stringify objects of class '%s'", class(x));
      end_try_catch

  endswitch

endfunction

## Test suite:

%!test
%!  x = [1 2 3.4; 5.67 8.9 0];
%!  assert(isequal(x, eval(stringify(x))));

%!test
%!  x = int32([1 2 3 7]);
%!  assert(isequal(x, eval(stringify(x))));

%!test
%!  x = [true; false];
%!  assert(isequal(x, eval(stringify(x))));

%!test
%!  x = "A string";
%!  assert(isequal(x, eval(stringify(x))));

%!test
%!  x = @(y) y*2;
%!  assert(x(7) == eval(stringify(x))(7));

%!test
%!  x = {1, 2, "three"; 4, 5, {6}};
%!  assert(isequal(x, eval(stringify(x))));

%!test
%!  x = {1, 2, "three", {4, 5, {6}, true}, 7, false, int16(9)};
%!  assert(isequal(x, eval(stringify(x))));

%!test
%!  x = struct("Hi","there","where", 2,"cell",{1,2,3,{4*5,6,{7,true}}});
%!  assert(isequal(x, eval(stringify(x))));
