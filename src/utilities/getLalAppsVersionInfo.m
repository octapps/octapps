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