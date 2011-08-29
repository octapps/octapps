%% Compiles all .oct modules in OCTAPPS
%% Syntax:
%%   octapps_build_oct [srcfile...]

%%
%%  Copyright (C) 2010 Karl Wette
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%

function octapps_build_oct(varargin)

  %% C++ compiler flags
  cflags = "-lgsl";

  %% turn of paging for this function
  pso = page_screen_output(0);

  %% find mkoctfile binary where it's supposed to be, fail if it is not there
  mkoct_bin = fullfile(octave_config_info("bindir"), ["mkoctfile-" OCTAVE_VERSION]);
  if !exist(mkoct_bin, "file")
    error("Could not find mkoctfile in Octave binary directory");
  endif

  %% find the path of the octapps base directory,
  %% using the location of this script
  my_path = fileparts(mfilename("fullpathext"));

  if length(varargin) > 0
    %% compile C++ and SWIG interface given on the command line
    sources = cellfun(@(x) fullfile(my_path, "src", x), varargin, "UniformOutput", false);
  else
    %% look at all subdirectories of the
    %% source directory for C++ and SWIG interface files
    dirs = strsplit(genpath(fullfile(my_path, "src")), pathsep, true);
    sources = {};
    for i = 1:length(dirs)
      sources = {sources{:}, ...
	         glob(fullfile(dirs{i}, "*.i")){:}, ...
	         glob(fullfile(dirs{i}, "*.cpp")){:} ...
	         };
    endfor
  endif
  
  for i = 1:length(sources)
    
    %% names of source file and oct-file
    srcfile = sources{i};
    [srcdir, srcname, srcext] = fileparts(srcfile);
    octfile = fullfile(srcdir, [srcname, ".oct"]);

    %% compile SWIG interface
    if strcmp(srcext, ".i")

      %% find SWIG binary in PATH, fail if none is found
      if !exist("swig_bin", "var")
	swig_bin = file_in_path(getenv("PATH"), "swig");
	if isempty(swig_bin)
	  error("Could not find SWIG executable in PATH");
	endif
      endif

      %% compile SWIG interface file
      srccpp = fullfile(srcdir, [srcname, "_wrap.C"]);
      cmd = sprintf("'%s' -c++ -octave -globals '%s_cvar' '-I%s' -o '%s' '%s'", swig_bin, srcname, srcdir, srccpp, srcfile);
      err = system(cmd);
      if err != 0
	error("Error executing %s", cmd);
	return;
      endif

    else
      
      %% otherwise compile C++ code
      srccpp = srcfile;

    endif

    %% compile oct-file
    cmd = sprintf("'%s' '-I%s' %s -o '%s' '%s'", mkoct_bin, srcdir, cflags, octfile, srccpp);
    err = system(cmd);
    if err != 0
      error("Error executing %s", cmd);
      return
    endif
    printf("Made '%s' from '%s'\n", octfile, srcfile);
    
  endfor
  
  page_screen_output(pso);

endfunction
