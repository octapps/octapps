## Copyright (C) 2010 Karl Wette
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
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## Compiles all .oct modules in OCTAPPS
## Syntax:
##   octapps_build_oct [-clean]

function octapps_build_oct(varargin)

  ## turn of paging for this function
  pso = page_screen_output(0);

  ## find the path of the octapps base directory,
  ## using the location of this script
  my_path = fileparts(mfilename("fullpathext"));

  ## directory where oct-files will be installed
  octdir = fullfile(my_path, "oct");
  [status, msg] = mkdir(octdir);
  if status == 0
    error("%s: error from mkdir: %s\n", funcName, msg);
  endif
  octdir = fullfile(octdir, OCTAVE_VERSION);

  ## do cleanup if asked for
  if length(varargin) == 1 && strcmp(varargin{1}, "clean") == 0
    if exist(octdir, "dir")
      [status, msg] = rmdir(octdir, "s");
      if status == 0
        error("%s: error from rmdir: %s\n", funcName, msg);
      endif
    endif
    return;
  endif

  ## create the oct-file directory
  [status, msg] = mkdir(octdir);
  if status == 0
    error("%s: error from mkdir: %s\n", funcName, msg);
  endif

  ## change to oct-file directory
  old_wd = pwd();
  cd(octdir);

  ## look at all subdirectories of src/ for C++ and SWIG interface files
  dirs = strsplit(genpath(fullfile(my_path, "src")), pathsep, true);
  sources = {};
  for i = 1:length(dirs)
    sources = {sources{:}, ...
               glob(fullfile(dirs{i}, "*.i")){:}, ...
               glob(fullfile(dirs{i}, "*.cpp")){:} ...
               };
  endfor

  ## loop over sources
  for i = 1:length(sources)
    if !isempty(strfind(sources{i}, [filesep,"deprecated",filesep]))
      printf("Skipping deprecated source '%s'\n", sources{i});
      continue
    endif

    ## names of source file, object file, and oct-file
    srcfile = sources{i};
    [srcdir, srcname, srcext] = fileparts(srcfile);
    ofile = fullfile(octdir, [srcname, ".o"]);
    octfile = fullfile(octdir, [srcname, ".oct"]);
    printf("Making '%s' from '%s'\n", octfile, srcfile);

    ## compile SWIG interface
    if strcmp(srcext, ".i")

      ## find SWIG binary in PATH, fail if none is found
      if !exist("swig_bin", "var")
        swig_bin = file_in_path(getenv("PATH"), "swig2.0");
        if isempty(swig_bin)
          swig_bin = file_in_path(getenv("PATH"), "swig");
          if isempty(swig_bin)
            error("Could not find SWIG executable in PATH");
          endif
        endif
      endif

      ## compile SWIG interface file
      srccpp = fullfile(octdir, [srcname, "_wrap.cpp"]);
      runCommand(sprintf("'%s' -c++ -octave -globals '%s_cvar' '-I%s' -o '%s' '%s'", swig_bin, srcname, srcdir, srccpp, srcfile));

    else

      ## otherwise compile C++ code
      srccpp = srcfile;

    endif

    ## compile oct-file
    runCommand(sprintf("g++ -fpic -c -o '%s' '%s' '-I%s'", ofile, srccpp, octave_config_info("includedir")));
    runCommand(sprintf("g++ -shared -o '%s' '%s' -lgsl", octfile, ofile));

  endfor

  ## restore working directory and paging
  cd(old_wd);
  page_screen_output(pso);

  ## refresh octapps path
  octapps_setup;

endfunction

function runCommand(cmd)
  printf("%s\n", cmd);
  err = system(cmd);
  if err != 0
    error("Error executing %s", cmd);
  endif
endfunction
