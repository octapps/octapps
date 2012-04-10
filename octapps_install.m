#!/usr/bin/octave -qf
##
## Install OCTAPPS files under a given prefix
## Syntax:
##   octapps_install prefix

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

function octapps_install(octapps_prefix)

  ## make absolute file name and strip trailing /s
  octapps_prefix = make_absolute_filename(octapps_prefix);
  [octapps_prefix_d, octapps_prefix_n] = fileparts(octapps_prefix);
  octapps_prefix = fullfile(octapps_prefix_d, octapps_prefix_n);

  ## octave install locations
  octave_prefix = octave_config_info("prefix");
  octave_mfiledir = octave_config_info("localfcnfiledir");
  octave_octfiledir = octave_config_info("localveroctfiledir");

  ## octapps install locations, deduced from octave ones
  if strncmp(octave_mfiledir, octave_prefix, length(octave_prefix))
    octapps_mfiledir = fullfile(octapps_prefix, octave_mfiledir(length(octave_prefix)+2:end), "octapps");
  else
    error("%s: '%s' does not begin with '%s'", funcName, octave_mfiledir, octave_prefix);
  endif
  if strncmp(octave_octfiledir, octave_prefix, length(octave_prefix))
    octapps_octfiledir = fullfile(octapps_prefix, octave_octfiledir(length(octave_prefix)+2:end), "octapps");
  else
    error("%s: '%s' does not begin with '%s'", funcName, octave_octfiledir, octave_prefix);
  endif

  ## octapps FHS install locations
  octapps_bindir = fullfile(octapps_prefix, "bin");
  octapps_etcdir = fullfile(octapps_prefix, "etc");

  ## make directories
  system(cstrcat("mkdir -p ", octapps_mfiledir));
  system(cstrcat("mkdir -p ", octapps_octfiledir));
  system(cstrcat("mkdir -p ", octapps_bindir));
  system(cstrcat("mkdir -p ", octapps_etcdir));
  
  ## get the directory containing this file, which
  ## is assumed to be the OCTAPPS root directory
  my_path = fileparts(file_in_loadpath(mfilename("fullpathext")));

  ## copy *.m files in all subdirectories to m-file install directory
  dirs = strsplit(genpath(fullfile(my_path, "src")), pathsep, true);
  for i = 1:length(dirs)
    [dir_base, dir_name] = fileparts(dirs{i});
    if strcmp(dir_name, "deprecated")
      continue
    endif
    for patt = {"*.m"}
      octfiles = glob(fullfile(dirs{i}, patt{1}));
      for j = 1:length(octfiles)
        [status, msg] = copyfile(octfiles{j}, octapps_mfiledir, "f");
        if status == 0
          error("%s: failed to copy '%s' to '%s': %s", funcName, octfiles{j}, octapps_mfiledir, msg);
        endif
      endfor
    endfor
  endfor
  printf("Installed m-files to %s\n", octapps_mfiledir);

  ## copy *.oct files in oct-directory to oct-file install directory
  octfiledir = fullfile(my_path, "oct", OCTAVE_VERSION);
  if exist(octfiledir, "dir")
    for patt = {"*.oct"}
      octfiles = glob(fullfile(octfiledir, patt{1}));
      for j = 1:length(octfiles)
        [status, msg] = copyfile(octfiles{j}, octapps_octfiledir, "f");
        if status == 0
          error("%s: failed to copy '%s' to '%s': %s", funcName, octfiles{j}, octapps_octfiledir, msg);
        endif
      endfor
    endfor
  endif
  printf("Installed oct-files to %s\n", octapps_octfiledir);

  ## copy all files in bin/ directory to bin/ install directory
  bindir = fullfile(my_path, "bin");
  if exist(bindir, "dir")
    binfiles = glob(fullfile(bindir, "*"));
    for j = 1:length(binfiles)
      [status, msg] = copyfile(binfiles{j}, octapps_bindir, "f");
      if status == 0
        error("%s: failed to copy '%s' to '%s': %s", funcName, binfiles{j}, octapps_bindir, msg);
      endif
    endfor
  endif
  printf("Installed files to %s\n", octapps_bindir);

  ## write user environment setup scripts
  userenvpath = strcat(octapps_mfiledir, ":", octapps_octfiledir);
  exts = {"csh", "sh"};
  for i = 1:length(exts)
    userenvfile = fullfile(octapps_etcdir, strcat("octapps-user-env.", exts{i}));
    fid = fopen(userenvfile, "w");
    if fid < 0
      error("%s: failed to open %s", funcName, userenvfile);
    endif
    fprintf(fid, "# source this file to access OCTAPPS\n");
    if strcmp(exts{i}, "csh")
      fprintf(fid, "if ( ! ${?OCTAVE_PATH} ) setenv OCTAVE_PATH\n")
      fprintf(fid, "setenv OCTAVE_PATH \"%s:${OCTAVE_PATH}\"\n", userenvpath);
    else
      fprintf(fid, "OCTAVE_PATH=\"%s:${OCTAVE_PATH}\"\n", userenvpath);
      fprintf(fid, "export OCTAVE_PATH\n")
    endif      
    fclose(fid);
    printf("Wrote %s\n", userenvfile);
  endfor

endfunction
