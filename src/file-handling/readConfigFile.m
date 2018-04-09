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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{cfg} =} readConfigFile ( @var{file} )
##
## Read a .ini style configuration @var{file} into a struct.
##
## @heading Arguments
##
## @table @var
## @item cfg
## configuration @var{file} contents
##
## @item file
## configuration file
##
## @end table
##
## @end deftypefn

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

    ## store last comment
    if any(line(1) == ";#")
      comment = strtrim(line);
      continue
    endif

    ## parse section heading
    if line(1) == "["
      assert(length(line) > 2 && line(end) == "]", "%s, invalid section heading '%s'", errprefix, line);
      section = line(2:end-1);
      if !isempty(comment)
        cfg.(sprintf("_comment_%s", section)) = strtrim(comment);
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

    ## parse multi-line configuration value
    if any(line(1) == " \t")

      ## check for section
      assert(!isempty(section), "%s, no section for '%s'", errprefix, name);

      ## check for existing string value
      if isfield(cfg, section)
        assert(isfield(cfg.(section), name), "%s, configuration does not have a value for '%s.%s'", errprefix, section, name);
        assert(ischar(cfg.(section).(name)), "%s, multi-line value for '%s.%s' must be a string", errprefix, section, name);
      endif

      ## get indentation
      ii = find(line != " " & line != "\t");
      indent_name = sprintf("_indent_%s", name);
      indent_value = line(1:min(ii)-1);
      if !isfield(cfg.(section), indent_name)
        cfg.(section).(indent_name) = indent_value;
      endif

      ## append value
      cfg.(section).(name) = cstrcat(strtrim(cfg.(section).(name)), "\n", strtrim(line));

      continue

    endif

    ## could not parse line
    error("%s, could not parse '%s'", errprefix, line);

  endwhile

  ## close file
  fclose(f);

endfunction

%!test
%!  inifile = strcat(tempname(tempdir), ".ini");
%!  inicfg = struct("sec1", struct("key1", 1.23, "key2", "hi"), "sec2", struct("key3", "there"));
%!  writeConfigFile(inifile, inicfg);
%!  inicfg2 = readConfigFile(inifile);
%!  assert(inicfg.sec1.key1, inicfg2.sec1.key1);
%!  assert(inicfg.sec1.key2, inicfg2.sec1.key2);
%!  assert(inicfg.sec2.key3, inicfg2.sec2.key3);
