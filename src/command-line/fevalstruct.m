## Copyright (C) 2017 Karl Wette
## Copyright (C) 2015 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} fevalstruct ( @var{name}, @var{argstruct} )
## @deftypefnx{Function File} {} fevalstruct ( @dots{}, @var{property}, @var{value}, @dots{} )
## Evaluate the function named @var{name}, using the keyword-value
## arguments given by @var{argstruct}.
##
## If @var{property} "stripempty" is true, empty fields are first removed from @var{argstruct}.
## @seealso{feval}
## @end deftypefn

function varargout = fevalstruct(name, argstruct, varargin)

  ## parse input
  assert(isstruct(argstruct));
  parseOptions(varargin,
               {"stripempty", "logical,scalar", false},
               []);

  ## strip empty fields, if requested
  if stripempty
    keys = fieldnames(argstruct);
    for n = 1:length(keys)
      if isempty(getfield(argstruct, keys{n}))
        argstruct = rmfield(argstruct, keys{n});
      endif
    endfor
  endif

  ## create keyword-value arguments
  keys = fieldnames(argstruct);
  vals = struct2cell(argstruct);
  keyvals = [ keys'; vals' ];

  ## evaluate function
  [varargout{1:nargout}] = feval(name, keyvals{:});

endfunction

%!test
%!  args = struct;
%!  args.real_strictpos_scalar = 1.23;
%!  args.integer_vector = [-5, 3];
%!  args.string = "Hi";
%!  args.cell = {1, 9};
%!  fevalstruct(@__test_parseOptions__, args);
