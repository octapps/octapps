## Copyright (C) 2013 Karl Wette
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

## Copy a file, or directory (and contents), to another directory.
## Syntax:
##   copyFile(src_path, dest_dir)
## where:
##   src_path = source file, or directory
##   dest_dir = destination directory

function copyFile(src_path, dest_dir)

  ## check input
  assert(ischar(src_path));
  assert(ischar(dest_dir));

  ## check if src_path and dest_dir are files and/or directories
  src_path_is_file = (exist(src_path, "file") == 2);
  src_path_is_dir = (exist(src_path, "dir") == 7);
  dest_dir_is_dir = (exist(dest_dir, "dir") == 7);
  if !(src_path_is_file || src_path_is_dir)
    error("%s: source path '%s' must be a file or directory", funcName, src_path);
  endif
  if !dest_dir_is_dir
    error("%s: destination path '%s' must be a directory", funcName, dest_dir);
  endif

  ## canonicalise source path
  src_path = canonicalize_file_name(src_path);

  ## get directory and name parts of src_path
  [src_dir, src_name, src_ext] = fileparts(src_path);
  src_name = strcat(src_name, src_ext);
  clear src_ext;

  ## create destination path
  dest_path = fullfile(dest_dir, src_name);

  ## check that dest_path does not already exist
  dest_path_is_file = (exist(dest_path, "file") == 2);
  dest_path_is_dir = (exist(dest_path, "dir") == 7);
  if dest_path_is_file || dest_path_is_dir
    error("%s: destination path '%s' already exists", funcName, dest_path);
  endif

  ## if src_path is a file, copy it to dest_dir
  if src_path_is_file
    [status, errmsg] = copyfile(src_path, dest_path);
    if status == 0
      error("%s: could not copy file '%s' to '%s': %s", funcName, src_path, dest_path, errmsg);
    endif
  else

    ## make directory dest_path
    [status, errmsg] = mkdir(dest_path);
    if status == 0
      error("%s: could not make directory '%s': %s", funcName, dest_path, errmsg);
    endif

    ## iterate over contents of directory src_path, copying each to dest_path
    [src_paths, status, errmsg] = readdir(src_path);
    if status != 0
      error("%s: could not read directory '%s': %s", funcName, src_path, errmsg);
    endif
    for n = 1:length(src_paths)
      if !any(strcmp(src_paths{n}, {".", ".."}))
        src_path_n = fullfile(src_path, src_paths{n});
        copyFile(src_path_n, dest_path);
      endif
    endfor

  endif    

endfunction
