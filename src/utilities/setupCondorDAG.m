## Copyright (C) 2012 Karl Wette
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


function setupCondorDAG(varargin)

  ## parse options
  parseOptions(varargin,
               {"condor_job", "struct"},
               {"condor_DAG", "struct"},
               {"jobs_dir", "char"},
               {"DAG_log_dir", "char", getenv("LOCALHOME")},
               {"local_dir", "char"},
               []);

  ## check input
  if exist(jobs_dir, "dir")
    error("%s: directory '%s' already exists", funcName, jobs_dir);
  endif
  if !exist(DAG_log_dir, "dir")
    error("%s: directory '%s' does not exist", funcName, DAG_log_dir);
  endif
  if !exist(local_dir, "dir")
    error("%s: directory '%s' does not exist", funcName, local_dir);
  endif

  ## make absolute directory names
  jobs_dir = make_absolute_filename(jobs_dir);
  DAG_log_dir = make_absolute_filename(DAG_log_dir);
  local_dir = make_absolute_filename(local_dir);

  ## make jobs directory
  mkdir(jobs_dir);
  
  ## make jobs subdirectories
  jobs_output_dir = fullfile(jobs_dir, "condor.out");
  jobs_error_dir = fullfile(jobs_dir, "condor.err");
  mkdir(jobs_output_dir);
  mkdir(jobs_error_dir);
  
  ## get script name
  [_, job_name, _, _] = fileparts(job.executable);

  ## write boot script
  bootscript_name = job_name + ".sh";
  bootscript_path = fullfile(jobs_dir, bootscript_name);
  fid = fopen(bootscript_path, "w");
  if fid < 0
    error("%s: failed to open %s", funcName, bootscript_path);
  endif
  fprintf(fid, "#!/bin/bash\n");
  local_etc_dir = fullfile(local_dir, "etc");
  if exist(local_etc_dir, "dir")
    user_env_files = dir(fullfile(local_etc_dir, "*-user-env.sh"));
    for i = 1:length(user_env_files)
      if !user_env_files(i).isdir
        fprintf(fid, "source %s\n", fullfile(local_etc_dir, user_env_files(i).name));
      endif
    endfor
  endif
  fprintf(fid, "exec octapps_run %s \"$@\"\n", bootscript_name);
  fclose(fid);
  status = system(cstrcat("chmod +x ", bootscript_path));
  if status != 0
    error("%s: failed to make %s executable", funcName, bootscript_path);
  endif

  ## modify Condor job
  job.executable = bootscript_path;
  job.output = "condor.out/$(cluster)";
  job.error = "condor.err/$(cluster)";

  ## create job submission file
  jobfile = fullfile(jobs_dir, "condor.job");
  makeCondorJob(jobfile, job);

  ## modify Condor DAG
  for i = 1:length(DAG);
    DAG(i).jobfile = jobfile;
  endfor

  ## create DAG file
  dagfile = fullfile(jobs_dir, "condor.dag");
  makeCondorDAG(dagfile, DAG);

endfunction
