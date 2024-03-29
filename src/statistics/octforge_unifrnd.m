## Copyright (C) 2012 Rik Wehbring
## Copyright (C) 1995-2016 Kurt Hornik
## Copyright (C) 2019 Anthony Morast
##
## This program is free software: you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {} {} octforge_unifrnd (@var{a}, @var{b})
## @deftypefnx {} {} octforge_unifrnd (@var{a}, @var{b}, @var{r})
## @deftypefnx {} {} octforge_unifrnd (@var{a}, @var{b}, @var{r}, @var{c}, @dots{})
## @deftypefnx {} {} octforge_unifrnd (@var{a}, @var{b}, [@var{sz}])
## Return a matrix of random samples from the uniform distribution on
## [@var{a}, @var{b}].
##
## When called with a single size argument, return a square matrix with
## the dimension specified.  When called with more than one scalar argument the
## first two arguments are taken as the number of rows and columns and any
## further arguments specify additional matrix dimensions.  The size may also
## be specified with a vector of dimensions @var{sz}.
##
## If no size arguments are given then the result matrix is the common size of
## @var{a} and @var{b}.
## @end deftypefn

## Author: KH <Kurt.Hornik@wu-wien.ac.at>
## Description: Random deviates from the uniform distribution

function rnd = octforge_unifrnd (a, b, varargin)

  if (nargin < 2)
    print_usage ();
  endif

  if (! isscalar (a) || ! isscalar (b))
    [retval, a, b] = common_size (a, b);
    if (retval > 0)
      error ("octforge_unifrnd: A and B must be of common size or scalars");
    endif
  endif

  if (iscomplex (a) || iscomplex (b))
    error ("octforge_unifrnd: A and B must not be complex");
  endif

  if (nargin == 2)
    sz = size (a);
  elseif (nargin == 3)
    if (isscalar (varargin{1}) && varargin{1} >= 0)
      sz = [varargin{1}, varargin{1}];
    elseif (isrow (varargin{1}) && all (varargin{1} >= 0))
      sz = varargin{1};
    else
      error ("octforge_unifrnd: dimension vector must be row vector of non-negative integers");
    endif
  elseif (nargin > 3)
    if (any (cellfun (@(x) (! isscalar (x) || x < 0), varargin)))
      error ("octforge_unifrnd: dimensions must be non-negative integers");
    endif
    sz = [varargin{:}];
  endif

  if (! isscalar (a) && ! isequal (size (a), sz))
    error ("octforge_unifrnd: A and B must be scalar or of size SZ");
  endif

  if (isa (a, "single") || isa (b, "single"))
    cls = "single";
  else
    cls = "double";
  endif

  if (isscalar (a) && isscalar (b))
    if ((-Inf < a) && (a <= b) && (b < Inf))
      rnd = a + (b - a) * rand (sz, cls);
    else
      rnd = NaN (sz, cls);
    endif
  else
    rnd = a + (b - a) .* rand (sz, cls);

    k = !(-Inf < a) | !(a <= b) | !(b < Inf);
    rnd(k) = NaN;
  endif

endfunction


%!assert (size (octforge_unifrnd (1,2)), [1, 1])
%!assert (size (octforge_unifrnd (ones (2,1), 2)), [2, 1])
%!assert (size (octforge_unifrnd (ones (2,2), 2)), [2, 2])
%!assert (size (octforge_unifrnd (1, 2*ones (2,1))), [2, 1])
%!assert (size (octforge_unifrnd (1, 2*ones (2,2))), [2, 2])
%!assert (size (octforge_unifrnd (1, 2, 3)), [3, 3])
%!assert (size (octforge_unifrnd (1, 2, [4 1])), [4, 1])
%!assert (size (octforge_unifrnd (1, 2, 4, 1)), [4, 1])

## Test class of input preserved
%!assert (class (octforge_unifrnd (1, 2)), "double")
%!assert (class (octforge_unifrnd (single (1), 2)), "single")
%!assert (class (octforge_unifrnd (single ([1 1]), 2)), "single")
%!assert (class (octforge_unifrnd (1, single (2))), "single")
%!assert (class (octforge_unifrnd (1, single ([2 2]))), "single")

## Test input validation
%!error octforge_unifrnd ()
%!error octforge_unifrnd (1)
%!error octforge_unifrnd (ones (3), ones (2))
%!error octforge_unifrnd (ones (2), ones (3))
%!error octforge_unifrnd (i, 2)
%!error octforge_unifrnd (2, i)
%!error octforge_unifrnd (1,2, -1)
%!error octforge_unifrnd (1,2, ones (2))
%!error octforge_unifrnd (1, 2, [2 -1 2])
%!error octforge_unifrnd (1,2, 1, ones (2))
%!error octforge_unifrnd (1,2, 1, -1)
%!error octforge_unifrnd (ones (2,2), 2, 3)
%!error octforge_unifrnd (ones (2,2), 2, [3, 2])
%!error octforge_unifrnd (ones (2,2), 2, 2, 3)

%!assert (octforge_unifrnd (0,0), 0)
%!assert (octforge_unifrnd (1,1), 1)
%!assert (octforge_unifrnd (1,0), NaN)

