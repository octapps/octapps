## Copyright (C) 2017 Karl Wette
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
## @deftypefn {Function File} {} writeConfigFile ( @var{file}, @var{cfg} )
##
## Write a .ini style configuration @var{file} from a struct.
##
## @heading Arguments
##
## @table @var
## @item file
## configuration file
##
## @item cfg
## configuration @var{file} contents
##
## @end table
##
## @end deftypefn

function writeConfigFile(file, cfg)

  ## check input
  assert(ischar(file));
  assert(isstruct(cfg));

  ## write to new file
  new_file = strcat(file, ".writeConfigFile.tmp");
  f = fopen(new_file, "w");
  assert(f >= 0, "%s: could not open file '%s'", funcName, new_file);

  ## write configuration file
  sections = fieldnames(cfg);
  sections = sections(cellfun(@(section) section(1) != "_", sections));
  for i = 1:length(sections)

    ## write section heading
    if i > 1
      fprintf(f, "\n");
    endif
    comment = getoptfield("", cfg, sprintf("_comment_%s", sections{i}));
    if !isempty(comment)
      assert(any(comment(1) == ";#"), "%s: invalid comment '%s'", funcName, comment);
      fprintf(f, "%s\n", comment);
    endif
    fprintf(f, "[%s]\n", sections{i});

    ## write section names and values
    names = fieldnames(cfg.(sections{i}));
    names = names(cellfun(@(name) name(1) != "_", names));
    for j = 1:length(names)
      cfg_section = cfg.(sections{i});

      ## write comment
      comment = getoptfield("", cfg_section, sprintf("_comment_%s", names{j}));
      if !isempty(comment)
        assert(any(comment(1) == ";#"), "%s: invalid comment '%s'", funcName, comment);
        fprintf(f, "%s\n", comment);
      endif

      ## write name
      fprintf(f, "%s = ", names{j});

      ## write value
      value = cfg_section.(names{j});
      if ischar(value)
        indent_value = getoptfield("  ", cfg_section, sprintf("_indent_%s", names{j}));
        fprintf(f, "%s", strrep(value, "\n", cstrcat("\n", indent_value)));
      else
        valuestr = getoptfield("", cfg_section, sprintf("_str_%s", names{j}));
        if !isempty(valuestr) && str2double(valuestr) != value
          valuestr = "";
        endif
        if !isempty(valuestr)
          fprintf(f, "%s", valuestr);
        else
          valuefmt = strcat("%", getoptfield("g", cfg_section, sprintf("_format_%s", names{j})));
          fprintf(f, valuefmt, value)
        endif
      endif

      ## write inline comment
      inlinecomment = getoptfield("", cfg_section, sprintf("_inlinecomment_%s", names{j}));
      if !isempty(inlinecomment)
        assert(any(inlinecomment(1) == ";#"), "%s: invalid inline comment '%s'", funcName, inlinecomment);
        fprintf(f, "   %s\n", inlinecomment);
      else
        fprintf(f, "\n");
      endif

    endfor

  endfor

  ## close file
  fclose(f);

  ## replace old configuration file
  [status, msg] = movefile(new_file, file, "f");
  assert(status == 1, "%s: could not replace '%s' with '%s': %s", funcName, file, new_file, msg);

endfunction

%!test
%!  inifile = strcat(tempname(tempdir), ".ini");
%!  inicfg = struct("sec1", struct("key1", 1.23, "key2", "hi"), "sec2", struct("key3", "there"))
%!  writeConfigFile(inifile, inicfg);
