## Setup script for OCTAPPS paths.
## It can be run in a shell:
##    eval `/path/to/octapps_setup.m`
## or within Octave:
##    octapps_setup

## Copyright (C) 2011 Karl Wette
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

## Since this file is marked executable, and has no she-bang, it will
## be executed by the user's choice of shell, e.g. bash, csh. When the
## shell encounters the following line, it will concatenate the two
## strings together, and execute the resulting shell command, which
## replaces the current process with octave (whichever version is first
## in the current PATH), which in turn executes this same script! But,
## when octave encounters the following line, it interprets it as a call
## to the function eval(TRY,CATCH) with string arguments TRY and CATCH.
## Since the TRY string is empty, eval() does nothing, and the CATCH 
## string containing the shell commands is never evaluated by octave.
##
## The back-quoted argument passed to this script tests which shell
## is being used by the user. A C shell will recognise the 'setenv'
## command, set the environment variable CSH, and print its value;
## thus the script receives the argument 'csh'. A Bourne shell will
## not recognise the 'setenv' command, thus the environment variable
## CSH has no value, and the script received no argument.
eval '' 'exec octave -qfH $0 `unset CSH; setenv CSH csh >&/dev/null; echo ${CSH}`'

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
    if length(argv) > 0 && strcmp(argv(){1}, "csh")
      csh_shell = true;
    else
      csh_shell = false;
    endif

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

  ## look at all subdirectories of src/ for *.m files
  dirs = strsplit(genpath(fullfile(my_path, "src")), pathsep, true);
  octapps_path = {my_path};
  for i = 1:length(dirs)
    octfiles = 0;
    for patt = {"*.m"}
      octfiles += length(glob(fullfile(dirs{i}, patt{1})));
    endfor
    if octfiles > 0
      octapps_path{end+1} = dirs{i};
    endif
  endfor

  ## add oct-directory to path
  octdir = fullfile(my_path, "oct", OCTAVE_VERSION);
  if exist(octdir, "dir")
    octapps_path = {octdir, octapps_path{:}};
  endif

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
    octave_path_env_str = octave_path_env{i};
    for i = 2:length(octave_path_env)
      octave_path_env_str = strcat(octave_path_env_str, pathsep, octave_path_env{i});
    endfor

    ## print the shell-appropriate command
    if csh_shell
      printf("setenv OCTAVE_PATH %s", octave_path_env_str);
    else
      printf("export OCTAVE_PATH=%s", octave_path_env_str);
    endif

  endif

endfunction

## call the internal setup function, giving it
## the full path of this file (which is not
## available within the function itself)
octapps_setup_function(mfilename("fullpathext"));
