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
## @deftypefn {Function File} {@var{deps} =} sharedlibdeps ( @var{file}, @dots{} )
## @deftypefnx{Function File} {@var{deps} =} sharedlibdeps ( @var{exclude}, @var{file}, @dots{} )
##
## Returns in @var{deps} a list of all the shared libraries on which
## the executables/shared libraries @var{file}, @dots{} depend.
## If @var{exclude} (a cell array of strings) is given, exclude all libraries
## whose filepaths start with one of the filepath prefixes in @var{exclude}.
## @end deftypefn

function deps = sharedlibdeps(varargin)

  ## check input
  exclude = {};
  if iscell(varargin{1})
    exclude = varargin{1};
    if !all(cellfun("ischar", exclude))
      error("%s: first argument is not a cell array of strings", funcName);
    endif
    varargin = varargin(2:end);
  endif
  if !all(cellfun("ischar", varargin))
    error("%s: arguments are not strings", funcName);
  endif
  files = "";
  for i = 1:length(varargin)
    if !exist(varargin{i}, "file")
      error("%s: '%s' is not a file", funcName, varargin{i});
    endif
    files = cstrcat(files, " ", varargin{i});
  endfor

  ## get shared library dependencies
  deps = varargin;
  if isunix()

    ## run ldd
    [status, output] = system(strcat("ldd", files));

    ## parse output of ldd
    lines = strsplit(output, "\n", true);
    for i = 1:length(lines)
      if !strncmp(lines{i}, "\t", 1)
        continue
      endif
      tokens = strsplit(strtrim(lines{i}), " ", true);
      for j = 1:length(tokens)
        if strncmp(tokens{j}, filesep, 1) && exist(tokens{j}, "file")
          deps{end+1} = tokens{j};
          break;
        endif
      endfor
    endfor

  else
    error("%s: unsupported operating system", funcName);
  endif

  ## only keep unique entries
  deps = unique(deps);

  ## filter out excluded prefixes
  for i = 1:length(exclude)
    deps = deps(!strncmp(exclude{i}, deps, length(exclude{i})));
  endfor

endfunction

%!test
%!  deps = sharedlibdeps(glob(fullfile(octave_config_info("libdir"), "liboct*.so")){:});
