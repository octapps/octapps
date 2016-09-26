## Copyright (C) 2016 Karl Wette
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

## Read a .ini style configuration file into a struct.
## Usage:
##   cfg  = readConfigFile(file)
## where
##   cfg  = configuration file contents
##   file = configuration file

function cfg = readConfigFile(file)

  ## check input
  assert(ischar(file));

  ## open file
  f = fopen(file, "r");
  assert(f >= 0, "%s: could not open file '%s'", funcName, file);

  ## setup configuration
  cfg = struct;
  section = "";

  ## read lines from file
  while !feof(f)
    line = fgetl(f);

    ## remove comments and whitespace
    for c = "#%;"
      ii = find(line == c);
      if length(ii) > 0
        line = line(1:max(ii)-1);
      endif
    endfor
    line = strtrim(line);

    ## skip empty lines
    if length(line) == 0
      continue
    endif

    ## parse section heading
    if line(1) == "["
      assert(length(line) > 2 && line(end) == "]", "%s: invalid section heading '%s'", funcName, line);
      section = line(2:end-1);
      continue
    endif

    ## parse configuration value
    ii = find(line == "=");
    if length(ii) > 0

      ## extract name and value
      name = strtrim(line(1:min(ii)-1));
      value = strtrim(line(min(ii)+1:end));

      ## try to make value numeric
      v = str2double(value);
      if !isnan(v)
        value = v;
      endif

      ## assign configuration value
      if isempty(section)
        if isfield(cfg, name)
          error("%s: configuration already has a value for '%s'", funcName, name);
        endif
        cfg.(name) = value;
      else
        if isfield(cfg, section) && isfield(cfg.(section), name)
          error("%s: configuration already has a value for '%s.%s'", funcName, section, name);
        endif
        cfg.(section).(name) = value;
      endif

      continue

    endif

    ## could not parse line
    error("%s: could not parse line '%s'", funcName, line);

  endwhile

  ## close file
  fclose(f);

endfunction
