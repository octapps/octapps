%% Copyright (C) 2013 David Keitel
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with with program; see the file COPYING. If not, write to the
%% Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%% MA  02111-1307  USA

function version_string = getLalAppsVersionInfo (lalapps_command);

 version_string = ["# version info from ", lalapps_command, ":\n"];

 % get version info from the given lalapps code
 params_lalapps.version = 1;
 lalapps_version_output = runCode ( params_lalapps, lalapps_command );

 % reformat it: remove trailing whitespaces and newlines, replace '%%' comment markers by '#'
 lalapps_version_output = strsplit(lalapps_version_output,"\n");
 for n=1:1:length(lalapps_version_output)
  lalapps_version_line = lalapps_version_output{n};
  if ( length(lalapps_version_line) > 0 )
   if ( strncmp(lalapps_version_line,"%%", 2) )
    lalapps_version_line = lalapps_version_line(3:end);
   endif
   version_string = [version_string, "# ", strtrim(lalapps_version_line), "\n"];
  endif
 endfor

endfunction # getLalAppsVersionInfo()