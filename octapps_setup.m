#!/usr/bin/octave -qf
##
## Setup script for OCTAPPS paths.
## It can be run in a shell:
##    eval `/path/to/octapps_setup.m <name of shell>`
## or within Octave:
##    octave_setup
##

##
##  Copyright (C) 2010 Karl Wette
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with with program; see the file COPYING. If not, write to the
##  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
##  MA  02111-1307  USA
##

## this is a script
1;

## put everything in an internal function, so workspace
## isn't contaminated when run from within Octave
function octapps_setup_function(my_path)

  ## this must match the name of this file!
  my_name = "octapps_setup.m";

  ## if run as a script, program_name == my_name
  ## if run within Octave, program_name == 'octave'
  run_as_script = strcmp(program_name, my_name);

  if run_as_script

    ## check for name of shell on command line
    if length(argv) != 1
      printf("Usage: %s <name of shell>", my_name);
      return;
    endif
    
    ## get the filename component
    [shell{1:2}] = fileparts(argv(){1});
    shell = shell{2};

  endif

  ## get the absolute path to this file
  if my_path(1) == filesep
    my_path = canonicalize_file_name(my_path);
  else
    my_path = canonicalize_file_name(fullfile(pwd, my_path));
  endif

  ## get the directory containing this file, which
  ## is assumed to be the OCTAPPS root directory
  my_path = fileparts(my_path);

  ## look at all subdirectories of the
  ## source directory for *.{m,cpp,i} files
  dirs = strsplit(genpath(fullfile(my_path, "src")), pathsep, true);
  octapps_path = {my_path};
  for i = 1:length(dirs)
    octfiles = 0;
    for patt = {"*.m", "*.cpp", "*.i"}
      octfiles += length(glob(fullfile(dirs{i}, patt{1})));
    endfor
    if octfiles > 0
      octapps_path{end+1} = dirs{i};
    endif
  endfor
  
  ## get the full Octave path
  octave_path = strsplit(path, pathsep, true);

  ## get the Octave path set by the environment
  octave_path_env = strsplit(getenv("OCTAVE_PATH"), pathsep, true);

  ## remove any existing OCTAPPS directories
  ## from the Octave full/environment paths
  for i = 1:length(octapps_path)
    j = strcmp(octave_path, octapps_path{i});
    if !isempty(j)
      octave_path(j) = [];
    endif
    j = strcmp(octave_path_env, octapps_path{i});
    if !isempty(j)
      octave_path_env(j) = [];
    endif
  endfor

  ## add the OCTAPPS directories to the Octave path
  ## (these will persist if this script is run within Octave)
  ## make sure "." stays at the top of the path
  if strcmp(octave_path{1}, ".")
    path(octave_path{1}, octapps_path{:}, octave_path{2:end});
  else
    path(octapps_path{:}, octave_path{:});
  endif

  ## if run as a script, also print
  ## commands to be eval'd within a shell
  if run_as_script
    
    ## build the shell environment string
    octave_path_env = {octapps_path{:}, octave_path_env{:}};
    octave_path_env_str = "";
    for i = 1:length(octave_path_env)
      octave_path_env_str = strcat(octave_path_env_str, pathsep, octave_path_env{i});
    endfor
    
    ## print the shell-appropriate command
    switch shell
      case {"bash"}
	printf("export OCTAVE_PATH=%s", octave_path_env_str);
      case {"csh" "tcsh"}
	printf("setenv OCTAVE_PATH %s", octave_path_env_str);
      otherwise
	error(["Unrecognised shell '" shell "'"]);
    endswitch
    
  endif
  
endfunction

## call the internal setup function, giving it
## the full path of this file (which is not
## available within the function itself)
octapps_setup_function(mfilename("fullpathext"));
