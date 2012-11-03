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

## Set up a Condor DAG for running Condor jobs.
## Usage:
##   makeCondorDAG(...)
## Options:
##   "dag_name":	name of Condor DAG, used to name DAG submit file
##   "parent_dir":	where to write DAG submit file (default: current directory)
##   "job_nodes":	struct array of job nodes, which has the following fields:
##			* "file": Condor job submit file for this job
##			* "vars": struct of variable substitutions to make
##			* "child": array indexing child job nodes for this node
##   "retries":		how man times to retry Condor jobs (default: 0)

function makeCondorDAG(varargin)

  ## parse options
  parseOptions(varargin,
               {"dag_name", "char"},
               {"parent_dir", "char", "."},
               {"job_nodes", "struct"},
               {"retries", "integer,positive", 0},
               []);

  ## check input
  if !isempty(strchr(dag_name, "."))
    error("%s: dag name '%s' should not contain an extension", funcName, dag_name);
  endif
  for n = 1:length(job_nodes)
    job_node = job_nodes(n);

    ## check node
    if !isfield(job_node, "file")
      error("%s: missing job node field 'file'", funcName);
    endif
    if isfield(job_node, "vars") && !isempty(job_node.vars)
      if !isstruct(job_node.vars)
        error("%s: job node field 'vars' must be a struct", funcName);
      endif
    endif

    ## check node children
    if isfield(job_node, "child") && !isempty(job_node.child)
      if !isvector(job_node.child)
        error("%s: job node field 'child' must be a vector", funcName);
      endif
      if any(mod(job_node.child, 1) != 0)
        error("%s: elements job node vector 'child' must be integers", funcName);
      endif
      if any(job_node.child > length(job_nodes))
        error("%s: elements job node vector 'child' must be <= number of nodes", funcName);
      endif
    endif

  endfor

  ## check that parent directory exists
  if exist(parent_dir, "dir")
    parent_dir = canonicalize_file_name(parent_dir);
  else
    error("%s: parent directory '%s' does not exist", funcName, parent_dir);
  endif

  ## check that DAG submission file does not exist, and that job submission files do exist
  dag_file = fullfile(parent_dir, strcat(dag_name, ".dag"));
  if exist(dag_file, "file")
    error("%s: DAG file '%s' already exists", funcName, dag_file);
  endif
  for n = 1:length(job_nodes)
    job_node = job_nodes(n);
    if !exist(job_node.file, "file")
      error("%s: job file '%s' does not exist", funcName, job_node.(file));
    endif
  endfor

  ## write Condor DAG submission file
  fid = fopen(dag_file, "w");
  if fid < 0
    error("%s: could not open file '%s' for writing", funcName, dag_file);
  endif
  for n = 1:length(job_nodes)
    job_node = job_nodes(n);

    ## print node
    fprintf(fid, "\n");
    fprintf(fid, "JOB %s_%i %s\n", dag_name, n, job_node.file);
    fprintf(fid, "RETRY %s_%i %d\n", dag_name, n, retries);

    ## print node variables
    if isfield(job_node, "vars") && !isempty(job_node.vars)
      fprintf(fid, "VARS %s_%i", dag_name, n);
      vars = fieldnames(job_node.vars);
      for i = 1:length(vars)
        value = stringify(job_node.vars.(vars{i}));
        value = strrep(value, "\\", "\\\\"); 
        value = strrep(value, "\"", "\\\"");
        fprintf(fid, " %s=\"%s\"", vars{i}, value);
      endfor
      fprintf(fid, "\n");
    endif

    ## print node children
    if isfield(job_node, "child") && !isempty(job_node.child)
      fprintf(fid, "PARENT %s_%i CHILD", dag_name, n);
      for i = 1:length(job_node.child)
        fprintf(fid, " %s_%i", dag_name, job_node.child(i));
      endfor
      fprintf(fid, "\n");
    endif
      
  endfor
  fclose(fid);

endfunction
