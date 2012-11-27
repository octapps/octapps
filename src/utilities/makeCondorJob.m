## Copyright (C) 2011,2012 Karl Wette
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

## Set up a Condor job for running Octave scripts.
## Usage:
##   job_file = makeCondorJob(...)
## where
##   job_file = name of Condor job submit file
## Options:
##   "job_name":	name of Condor job, used to name submit file
##			and input/output directories
##   "parent_dir":	where to write submit file and input/output
##			directories (default: current directory)
##   "log_dir":		where to write Condor log files (default: $TMPDIR")
##   "func_name":	name of Octave function to run
##   "arguments":	cell array of arguments to pass to function.
##			use condorVar() to insert reference to a Condor variable.
##   "func_nargout":	how many outputs returned by the function to save
##   "exec_files":	cell array of executable files required by the function
##   "data_files":	cell array of data files required by the function;
##                      elements of cell array may be either:
##			* "file_path", or
##			* {"ENVPATH", "file_name_in_ENVPATH", ...}
##			where ENVPATH is the name of an environment path
##   "extra_condor":	extra commands to write to Condor submit file, in form:
##			{"command", "value", ...}

function job_file = makeCondorJob(varargin)

  ## parse options
  parseOptions(varargin,
               {"job_name", "char"},
               {"parent_dir", "char", "."},
               {"log_dir", "char", getenv("TMPDIR")},
               {"func_name", "char"},
               {"arguments", "cell,vector", {}},
               {"func_nargout", "integer"},
               {"exec_files", "cell", {}},
               {"data_files", "cell", {}},
               {"extra_condor", "cell", {}},
               []);

  ## check input
  if !isempty(strchr(job_name, "."))
    error("%s: job name '%s' should not contain an extension", funcName, job_name);
  endif
  try
    str2func(func_name);
  catch
    error("%s: '%s' is not a recognised function", funcName, func_name);
  end_try_catch
  for i = 1:length(data_files)
    if iscell(data_files{i}) && length(data_files{i}) < 2
      error("%s: element %i of 'data_files' must be a cell array of at least 2 elements", funcName, i);
    endif
  endfor

  ## check that parent and log directories exist
  if exist(parent_dir, "dir")
    parent_dir = canonicalize_file_name(parent_dir);
  else
    error("%s: parent directory '%s' does not exist", funcName, parent_dir);
  endif
  if exist(log_dir, "dir")
    log_dir = canonicalize_file_name(log_dir);
  else
    error("%s: log directory '%s' does not exist", funcName, log_dir);
  endif

  ## check that job submit file and input/output directories do not exist
  job_file = fullfile(parent_dir, strcat(job_name, ".job"));
  if exist(job_file, "file")
    error("%s: job file '%s' already exists", funcName, job_file);
  endif
  job_indir = fullfile(parent_dir, strcat(job_name, ".in"));
  if exist(job_indir, "dir")
    error("%s: input directory '%s' already exists", funcName, job_indir);
  endif
  job_outdir = fullfile(parent_dir, strcat(job_name, ".out"));
  if exist(job_outdir, "dir")
    error("%s: output directory '%s' already exists", funcName, job_outdir);
  endif

  ## resolve locations of executable files
  unmanglePATH;
  path_value = getenv("PATH");
  for i = 1:length(exec_files)
    resolved_file = file_in_path(path_value, exec_files{i});
    if isempty(resolved_file)
      error("%s: could not find required file '%s'", funcName, exec_files{i});
    endif
    exec_files{i} = resolved_file;
  endfor

  ## resolve locations of data files
  resolved_files = {};
  for i = 1:length(data_files)
    switch class(data_files{i})
      case "char"
        resolved_file = fullfile(parent_dir, data_files{i});
        if !exist(data_files{i}, "file")
          error("%s: could not find required file '%s'", funcName, data_files{i});
        endif
        resolved_files{end+1} = data_files{i};
      case "cell"
        envpath_name = data_files{i}{1};
        envpath_value = getenv(envpath_name);
        if length(envpath_value) == 0
          error("%s: environment path '%s' is not set", funcName, envpath_name);
        endif
        for j = 2:length(data_files{i})
          resolved_file = file_in_path(envpath_value, data_files{i}{j});
          if isempty(resolved_file)
            error("%s: could not find required file '%s'", funcName, data_files{i}{j});
          endif
          resolved_files{end+1} = resolved_file;
        endfor
    endswitch
  endfor
  data_files = resolved_files;

  ## prefixes of local Octave functions and shared libraries,
  ## which do not need to be distributed
  octprefixes = cellfun("octave_config_info", {"fcnfiledir", "octfiledir"}, "UniformOutput", false);
  libprefixes = {"/lib", "/usr/lib"};

  ## get dependencies of job function
  func_files = struct2cell(depends(octprefixes, func_name));

  ## find if any job function dependencies are .oct modules
  ## if so, load them, then add all loaded .octs as dependencies
  for i = 1:length(func_files)
    [func_file_path, func_file_name, func_file_ext] = fileparts(func_files{i});
    if strcmp(func_file_ext, ".oct")
      try
        eval(strcat(func_file_name, ";"));
      catch
        error("%s: could not load required module '%s'", funcName, func_file_name);
      end_try_catch
    endif
  endfor
  oct_files = unique({autoload.file});
  for i = 1:length(oct_files)
    if any(cellfun(@(x) strncmp(oct_files{i}, x, length(x)), octprefixes))
      continue;
    endif
    func_files = {func_files{:}, oct_files{i}};
    exec_files = {exec_files{:}, oct_files{i}};
  endfor
  func_files = unique(func_files);
  exec_files = unique(exec_files);

  ## get dependencies of executables and .oct modules
  if length(exec_files) > 0
    exec_files = setdiff(sharedlibdeps(libprefixes, exec_files{:}), func_files);
  endif

  ## check that all dependencies exist, resolving symbolic links
  for i = 1:length(func_files)
    if !exist(func_files{i}, "file")
      error("%s: could not find required file '%s'", funcName, func_files{i});
    endif
  endfor
  for i = 1:length(exec_files)
    if !exist(exec_files{i}, "file")
      error("%s: could not find required file '%s'", funcName, exec_files{i});
    endif
  endfor

  ## directories where dependent executables/shared libraries and function/.oct files are copied
  execdir = ".exec";
  funcdir = ".func";
  envpaths = struct("PATH", execdir, "LD_LIBRARY_PATH", execdir, "OCTAVE_PATH", funcdir);

  ## build Octave evaluation string, which sets up environment, calls function, and saves output
  envpaths = {"PATH", "LD_LIBRARY_PATH"};
  evalstr = "";
  for i = 1:length(envpaths)
    evalstr = sprintf("%sputenv(\"%s\",strcat(fullfile(pwd,\"%s\"),\":\",getenv(\"%s\")));", evalstr, envpaths{i}, execdir, envpaths{i});
  endfor
  evalstr = sprintf("%saddpath(fullfile(pwd,\"%s\"),\"-begin\");", evalstr, funcdir);
  evalstr = strcat(evalstr, sprintf("arguments=%s;", stringify(arguments)));
  if length(arguments) > 0
    callfuncstr = sprintf("%s(arguments{:})", func_name);
  else
    callfuncstr = sprintf("%s", func_name);
  endif
  if func_nargout > 0
    evalstr = sprintf("%stic;[results{1:%i}]=%s;elapsed=toc;", evalstr, func_nargout, callfuncstr);
    evalstr = sprintf("%ssave(\"-hdf5\",\"stdres.h5\",\"arguments\",\"results\",\"elapsed\");", evalstr);
  else
    evalstr = sprintf("%s%s;", evalstr, callfuncstr);
  endif
  evalstr = strrep(evalstr, "'", "''");
  evalstr = strrep(evalstr, "\"", "\"\"");

  ## build Condor job submit file spec
  job_spec = struct;
  job_spec.universe = "vanilla";
  job_spec.executable = fullfile(octave_config_info("bindir"), "octave");
  job_spec.arguments = sprintf("\"'-qfH' '--eval' '%s'\"", evalstr);
  job_spec.initialdir = "";
  job_spec.output = "stdout";
  job_spec.error = "stderr";
  job_spec.log = fullfile(log_dir, strcat(job_name, ".log"));
  job_spec.environment = "OCTAVE_HISTFILE=/dev/null";
  job_spec.getenv = "false";
  job_spec.should_transfer_files = "yes";
  job_spec.transfer_input_files = strcat(job_indir, filesep);
  job_spec.when_to_transfer_output = "on_exit";
  job_spec.notification = "never";
  extra_condor = struct(extra_condor{:});
  extra_condor_names = fieldnames(extra_condor);
  for i = 1:length(extra_condor_names)
    extra_condor_name =  extra_condor_names{i};
    if isfield(job_spec, extra_condor_name)
      error("%s: cannot override value of Condor command '%s'", funcName, extra_condor_name);
    endif
    extra_condor_val = extra_condor.(extra_condor_name);
    if !ischar(extra_condor_val)
      error("%s: value of Condor command '%s' must be a string", funcName, extra_condor_name);
    endif
    job_spec.(extra_condor_name) = extra_condor_val;
  endfor

  ## create input directories
  if !mkdir(job_indir)
    error("%s: failed to make directory '%s'", funcName, job_indir);
  endif
  job_inexecdir = fullfile(job_indir, execdir);
  if !mkdir(job_inexecdir)
    error("%s: failed to make directory '%s'", funcName, job_inexecdir);
  endif
  job_infuncdir = fullfile(job_indir, funcdir);
  if !mkdir(job_infuncdir)
    error("%s: failed to make directory '%s'", funcName, job_infuncdir);
  endif

  ## copy input files to input directories
  for i = 1:length(data_files)
    if !copyRealFile(data_files{i}, job_indir)
      error("%s: failed to copy '%s' to '%s'", funcName, data_files{i}, job_indir);
    endif
  endfor
  for i = 1:length(exec_files)
    if !copyRealFile(exec_files{i}, job_inexecdir)
      error("%s: failed to copy '%s' to '%s'", funcName, exec_files{i}, job_inexecdir);
    endif
  endfor
  for i = 1:length(func_files)
    if !copyRealFile(func_files{i}, job_infuncdir)
      error("%s: failed to copy '%s' to '%s'", funcName, func_files{i}, job_infuncdir);
    endif
  endfor

  ## overwrite octapps_gitID.m with static copy of current repository's git ID
  octapps_gitID_file = fullfile(job_infuncdir, "octapps_gitID.m");
  if exist(octapps_gitID_file, "file")
    gitID = octapps_gitID();
    fid = fopen(octapps_gitID_file, "w");
    if fid < 0
      error("%s: could not open file '%s' for writing", funcName, octapps_gitID_file);
    endif
    fprintf(fid, "## generated by %s\n", funcName);
    fprintf(fid, "function ID = octapps_gitID()\n");
    fprintf(fid, "  ID = %s;\n", stringify(gitID));
    fprintf(fid, "endfunction\n");
    fclose(fid);
  endif

  ## write Condor job submit file
  fid = fopen(job_file, "w");
  if fid < 0
    error("%s: could not open file '%s' for writing", funcName, job_file);
  endif
  job_spec_names = sort(fieldnames(job_spec));
  for i = 1:length(job_spec_names)
    fprintf(fid, "%s = %s\n", job_spec_names{i}, job_spec.(job_spec_names{i}));
  endfor
  fprintf(fid, "queue 1\n");
  fclose(fid);

endfunction


## copy the real file pointed to by srcdir to the
## directory destdir, but preserve the name of srcfile
function status = copyRealFile(srcfile, destdir)
  [_, srcname, srcext] = fileparts(srcfile);
  destfile = fullfile(destdir, strcat(srcname, srcext));
  srcfile = canonicalize_file_name(srcfile);
  status = copyfile(srcfile, destfile);
endfunction
