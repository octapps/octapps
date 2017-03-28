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

  ## open file for reading
  f = fopen(file, "r");
  assert(f >= 0, "%s: could not open file '%s'", funcName, file);

  ## setup configuration
  cfg = struct;
  comment = "";
  section = "";

  ## read lines from file
  lineno = 0;
  while !feof(f)
    line = fgetl(f);
    lineno += 1;
    errprefix = sprintf("%s: at %s:%i", funcName, file, lineno);

    ## skip empty lines
    if length(line) == 0
      continue
    endif
    line = strtrim(line);

    ## store last comment
    if any(line(1) == ";#")
      comment = line;
      continue
    endif

    ## parse section heading
    if line(1) == "["
      assert(length(line) > 2 && line(end) == "]", "%s, invalid section heading '%s'", errprefix, line);
      section = line(2:end-1);
      if !isempty(comment)
        cfg.(sprintf("_comment_%s", section)) = comment;
        comment = "";
      endif
      continue
    endif

    ## parse configuration value
    ii = find(line == "=");
    if length(ii) > 0

      ## extract name
      name = strtrim(line(1:min(ii)-1));

      ## check for section
      assert(!isempty(section), "%s, no section for '%s'", errprefix, name);

      ## check for existing value
      if isfield(cfg, section)
        assert(!isfield(cfg.(section), name), "%s, configuration already has a value for '%s.%s'", errprefix, section, name);
      endif

      ## extract value
      valueinlinecomment = strtrim(line(min(ii)+1:end));
      ii = find(valueinlinecomment == ";" | valueinlinecomment == "#");
      if length(ii) > 0
        value = strtrim(valueinlinecomment(1:min(ii)-1));
        inlinecomment = strtrim(valueinlinecomment(min(ii):end));
      else
        value = valueinlinecomment;
        inlinecomment = "";
      endif

      ## assign configuration value, preferably numeric
      v = str2double(value);
      if isnan(v)
        cfg.(section).(name) = value;
      else
        cfg.(section).(name) = v;
        cfg.(section).(sprintf("_str_%s", name)) = value;
      endif

      ## preserve comments
      if !isempty(comment)
        cfg.(section).(sprintf("_comment_%s", name)) = comment;
        comment = "";
      endif
      if !isempty(inlinecomment)
        cfg.(section).(sprintf("_inlinecomment_%s", name)) = inlinecomment;
      endif

      continue

    endif

    ## could not parse line
    error("%s, could not parse '%s'", errprefix, line);

  endwhile

  ## close file
  fclose(f);

endfunction
