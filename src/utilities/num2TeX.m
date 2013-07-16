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

## Format a number in TeX format.
## Usage:
##   tex = num2TeX(num, fmt, ...)
## where:
##   tex = cell array of TeX strings (or string if numel(num) == 1)
##   num = any-dimensional array of numbers
##   fmt = printf()-style format string, without the leading %
## Options:
##   "dollar": symbol to wrap TeX string with (default: "$")
##   "times": TeX symbol to use for times (default: "{\times}")
##   "infstr": TeX string to use for infinity (default: "\infty")
##   "nanstr": TeX string to use for not-a-number (default: "\mathrm{NaN}")

function tex = num2TeX(num, fmt, varargin)

  ## check input
  assert(numel(num) > 0);
  assert(ischar(fmt));
  assert(length(fmt) > 0);
  assert(fmt(1) != "%");
  assert(any(fmt(end) == "diufeg"));

  ## parse options
  parseOptions(varargin,
               {"dollar", "char", "$"},
               {"times", "char", "{\\times}"},
               {"infstr", "char", "\\infty"},
               {"nanstr", "char", "\\mathrm{NaN}"},
               []);

  ## generate TeX-formatted numbers
  tex = cell(size(num));
  for n = 1:numel(num)

    ## format number using printf()-style format string
    texstr = sprintf(strcat("%", fmt), num(n));

    ## format exponent into TeX
    texstr = regexprep(texstr, "e\\+0*$", "");
    texstr = regexprep(texstr, "e\\+0*(\\d*)$", strcat(times, "10^{$1}"));
    texstr = regexprep(texstr, "e-0*(\\d*)$", strcat(times, "10^{-$1}"));

    ## format infinities and not-a-numbers into TeX
    texstr = strrep(texstr, "Inf", infstr);
    texstr = strrep(texstr, "NaN", nanstr);

    ## wrap TeX string in dollar symbols
    texstr = strcat(dollar, texstr, dollar);

    tex{n} = texstr;
  endfor

  ## just return string if num is a scalar
  if numel(num) == 1
    tex = tex{1};
  endif

endfunction
