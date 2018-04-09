## Copyright (C) 2013 Karl Wette
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
## @deftypefn {Function File} {@var{tex} =} num2TeX ( @var{num}, @var{fmt}, @var{opt}, @var{val}, @dots{} )
##
## Format a number in TeX format.
##
## @heading Arguments
##
## @table @var
## @item tex
## cell array of TeX strings (or string if numel(@var{num}) == 1)
##
## @item num
## any-dimensional array of numbers
##
## @item fmt
## printf()-style format string, without the leading %
##
## @end table
##
## @heading Options
##
## @table @code
## @item prefix
## ": string to add at start of TeX string (default: "")
##
## @item suffix
## ": string to add at end of TeX string (default: "")
##
## @item dollar
## symbol to wrap TeX string with (default: "$")
##
## @item times
## TeX symbol to use for @var{times} (default: "@{\@var{times}@}")
##
## @item infstr
## TeX string to use for infinity (default: "\infty")
##
## @item nanstr
## TeX string to use for not-a-number (default: "\mathrm@{NaN@}")
##
## @item dbslash
## double backslash characters, i.e. replace "\" with "\\"
##
## @end table
##
## @end deftypefn

function tex = num2TeX(num, fmt, varargin)

  ## check input
  assert(numel(num) > 0);
  assert(ischar(fmt));
  assert(length(fmt) > 0);
  assert(fmt(1) != "%");
  assert(any(fmt(end) == "diufeg"));

  ## parse options
  parseOptions(varargin,
               {"prefix", "char", ""},
               {"suffix", "char", ""},
               {"dollar", "char", "$"},
               {"times", "char", "{\\times}"},
               {"infstr", "char", "\\infty"},
               {"nanstr", "char", "\\mathrm{NaN}"},
               {"dbslash", "logical,scalar", false},
               []);

  ## generate TeX-formatted numbers
  tex = cell(size(num));
  for n = 1:numel(num)

    ## format number using printf()-style format string
    texstr = sprintf(strcat("%", fmt), num(n));

    ## format exponent into TeX
    texstr = regexprep(texstr, "e\\+0*$", "");
    texstr = regexprep(texstr, "^1e\\+0*(\\d*)$", "10^{$1}");
    texstr = regexprep(texstr, "^1e-0*(\\d*)$", "10^{-$1}");
    ptimes = strrep(times, "\\", "\\\\");
    texstr = regexprep(texstr, "e\\+0*(\\d*)$", strcat(ptimes, "10^{$1}"));
    texstr = regexprep(texstr, "e-0*(\\d*)$", strcat(ptimes, "10^{-$1}"));

    ## format infinities and not-a-numbers into TeX
    texstr = strrep(texstr, "Inf", infstr);
    texstr = strrep(texstr, "NaN", nanstr);

    ## wrap TeX string with prefix/suffix in dollar symbols
    texstr = strcat(dollar, prefix, texstr, suffix, dollar);

    ## double backslash characters
    if dbslash
      texstr = strrep(texstr, "\\", "\\\\");
    endif

    tex{n} = texstr;
  endfor

  ## just return string if num is a scalar
  if numel(num) == 1
    tex = tex{1};
  endif

endfunction

%!assert(num2TeX([1.234, 5.67e-8], "g"), {"$1.234$", "$5.67{\\times}10^{-8}$"})
