## Copyright (C) 2014 Karl Wette
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

## Helper script used by the top-level OctApps Makefile to run tests and demos.
## Usage:
##   octapps_test <script paths...>

function octapps_test(varargin)
  global octapps_skipped_tests;
  scripts = sortrows(strvcat(varargin{:}));
  for i = 1:size(scripts, 1)
    if !isempty(strfind(scripts(i, :), "/deprecated/"))
      continue
    endif
    [~, name] = fileparts(strtrim(scripts(i, :)));
    total = 0;
    fid = fopen(which(name), "r");
    assert(fid >= 0);
    do
      s = fgets(fid);
      if ischar(s) && any(strncmp(s, {"%!test", "%!asse", "%!demo"}, 6))
        ++total;
      endif
    until !ischar(s)
    fclose(fid);
    if total > 0
      printf("\nSCRIPT Checking %s...\n", strrep(scripts(i, :), " ", "."));
      octapps_skipped_tests = 0;
      [ntests, ~] = test(name, "quiet");
      [demos, idx] = example(name);
      for i = 1:length(idx)-1
        eval_success = [];
        str = strcat(strtrim(demos(idx(i):idx(i+1)-1)), "; eval_success=true;");
        eval(str, "eval_success=false;");
        if eval_success
          ++ntests;
        else
          break
        endif
      endfor
      if octapps_skipped_tests > 0
        status = "SKIPPED";
        ntests = octapps_skipped_tests;
      elseif ntests < total
        status = "FAILED ";
        ntests = total - ntests;
      else
        status = "passed ";
      endif
      printf("\nSTATUS %s %2i of %2i tests/demos\n", status, ntests, total);
    endif
  endfor
endfunction
