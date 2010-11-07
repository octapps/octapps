%% Compiles SWIG wrappings in OCTAPPS
%% Syntax:
%%   octapps_makeSWIG [-force]
%% where:
%%   -force = disregard timestamps

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

function octapps_makeSWIG(arg)

  %% check input arguments
  debug = nargin > 0 && strcmp(arg, "-debug");

  %% turn of paging for this function
  pso = page_screen_output(0);

  %% find SWIG binary in PATH, fail if none is found
  swig_bin = file_in_path(getenv("PATH"), "swig");
  if isempty(swig_bin)
    error("Could not find SWIG executable in PATH");
  endif

  %% find mkoctfile binary where it's supposed to be, fail if it is not there
  mkoct_bin = fullfile(octave_config_info("bindir"), ["mkoctfile-" OCTAVE_VERSION]);
  if !exist(mkoct_bin, "file")
    error("Could not find mkoctfile in Octave binary directory");
  endif

  %% find the path of the octapps SWIG directory,
  %% using the location of this script
  base_path = fileparts(mfilename("fullpathext"));

  %% list of SWIG interfaces to compile
  sources =  glob(fullfile(base_path, "*", "*.i"));

  %% directory for the compiled .oct files,
  %% make it if is doesn't exist
  lib_path = fullfile(base_path, "lib");
  if !exist(lib_path, "dir")
    status = mkdir(lib_path);
    if status != 1
      error(["Error: mkdir('" lib_path "')"]);
    endif
  endif
  
  for i = 1:length(sources)
    
    %% names of the source file, intermediate
    %% SWIG wrapping code files, and output .oct file
    src = sources{i};
    [srcdir, srcname, srcext] = fileparts(src);
    wrapc = fullfile(base_path, [srcname "_wrap.cpp"]);
    wrapo = fullfile(base_path, [srcname "_wrap.o"]);
    oct = fullfile(lib_path, [srcname ".oct"]);

    %% get timestamps of source and output file
    [srcstat, err] = stat(src);
    if err != 0
      error(["Error: stat('" src "')"]);
    endif
    [octstat, err] = stat(oct);
    if err != 0
      octstat = struct("mtime", -inf);
    endif
    
    %% if source is newer than output (or -debug), compile it
    if debug || srcstat.mtime > octstat.mtime

      %% run SWIG
      cmd = sprintf("'%s' -c++ -octave -o '%s' '%s'", swig_bin, wrapc, src);
      err = system(cmd);
      if err != 0
	error(["Error executing: " cmd]);
      endif

      %% run mkoctfile
      cmd = sprintf("'%s' -lgsl -o '%s' '%s'", mkoct_bin, oct, wrapc);
      err = system(cmd);
      if err != 0
	error(["Error executing: " cmd]);
      endif

      %% delete intermediate files (unless -debug)
      if !debug
	delete(wrapc);
	delete(wrapo);
      endif

      printf("Made '%s' from '%s'\n", oct, src);

    endif
    
  endfor
  
  page_screen_output(pso);

endfunction
