## Copyright (C) 2018 Karl Wette
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
## @deftypefn
##
## Helper function for OctApps @command{make html}.
##
## @end deftypefn

function __octapps_make_html__(f)
  crash_dumps_octave_core(0);
  fn = strrep(f, "::", "/");
  [d, n] = fileparts(fn);
  fn = fullfile(d, n);
  [htext, hfmt] = get_help_text(fn);
  assert(length(strtrim(htext)) > 0, "help message is missing");
  assert(strcmp(hfmt, "texinfo"), "help message is not in Texinfo format");
  if htext(2) == " "
    htext = strrep(htext, "\n ", "\n");
  endif
  if isempty(strfind(htext, "@heading Example"))
    ffn = file_in_loadpath(fn, "all");
    if isempty(ffn)
      ffn = file_in_loadpath([fn ".m"], "all");
    endif
    if isempty(ffn)
      ffn = file_in_loadpath([fn ".cc"], "all");
    endif
    assert(iscell(ffn));
    ffn = ffn{1};
    fid = fopen(ffn, "rt");
    assert(fid >= 0, "could not open '%s' for reading", ffn);
    etext = "";
    while ischar(line = fgets(fid))
      if strncmp(line, "%!assert", 8)
        etext = strcat(etext, sprintf("\n@verbatim\n%s\n@end verbatim\n", line(9:end)));
      elseif strncmp(line, "%!test disp", 11)
        continue
      elseif strncmp(line, "%!test", 6) || strncmp(line, "%!shared", 8)
        econtents = "";
        linestart = 0;
        while ischar(line = fgets(fid)) && strncmp(line, "%!", 2)
          line = line(3:end);
          if linestart == 0 && any(!isspace(line))
            linestart = min(find(!isspace(line)));
          endif
          if linestart > 0
            line = line(linestart:end);
          endif
          econtents = strcat(econtents, line);
        endwhile
        etext = strcat(etext, sprintf("\n@verbatim\n%s\n@end verbatim\n", strtrim(econtents)));
      endif
    endwhile
    if length(strfind(etext, "@verbatim"))
      etext = strcat("@heading Examples\n", etext);
    else
      etext = strcat("@heading Example\n", etext);
    endif
    endhtext = strfind(htext, "@end deftypefn");
    assert(length(endhtext) == 1);
    htext = cstrcat(htext(1:endhtext-1), etext, "\n", htext(endhtext:end));
  endif
  of = fullfile(getenv("OCTAPPS_TMPDIR"), sprintf("%s.texi", f));
  fid = fopen(of, "w");
  assert(fid >= 0, "could not open '%s' for writing", of);
  fprintf(fid, "%s\n", htext);
  fclose(fid);
endfunction
