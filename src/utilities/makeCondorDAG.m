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
##   dag_file = makeCondorDAG(...)
## where
##   dag_file = name of Condor DAG submit file
## Options:
##   "dag_name":	name of Condor DAG, used to name DAG submit file
##   "parent_dir":	where to write DAG submit file (default: current directory)
##   "job_nodes":	struct array of job nodes, which has the following fields:
##			* "file": Condor job submit file for this job
##			* "vars": struct of variable substitutions to make
##			* "child": array indexing child job nodes for this node
##   "retries":		how man times to retry Condor jobs (default: 0)

function dag_file = makeCondorDAG(varargin)

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

  ## check that DAG submit file does not exist, and that job submit files do exist
  dag_file = fullfile(parent_dir, strcat(dag_name, ".dag"));
  if exist(dag_file, "file")
    error("%s: DAG file '%s' already exists", funcName, dag_file);
  endif
  for n = 1:length(job_nodes)
    job_nodes(n).file = canonicalize_file_name(job_nodes(n).file);
    if !exist(job_nodes(n).file, "file")
      error("%s: job file '%s' does not exist", funcName, job_nodes(n).file);
    endif
  endfor

  ## create job node names, and check that their output directories do not exist
  job_node_name_fmt = sprintf("%%s.%%0%ii", length(sprintf("%i", length(job_nodes)-1)));
  for n = 1:length(job_nodes)
    job_nodes(n).name = sprintf(job_node_name_fmt, dag_name, n-1);
    job_nodes(n).dir = fullfile(parent_dir, sprintf(job_node_name_fmt, strcat(dag_name, ".out"), n-1));
    if exist(job_nodes(n).dir, "dir")
      error("%s: job node output directory '%s' already exists", funcName, job_nodes(n).dir);
    endif
  endfor

  ## write Condor DAG submit file
  fid = fopen(dag_file, "w");
  if fid < 0
    error("%s: could not open file '%s' for writing", funcName, dag_file);
  endif
  for n = 1:length(job_nodes)
    job_node = job_nodes(n);

    ## print node
    fprintf(fid, "\n");
    fprintf(fid, "JOB %s %s DIR %s\n", job_nodes(n).name, job_node.file, job_nodes(n).dir);
    fprintf(fid, "RETRY %s %d\n", job_nodes(n).name, retries);

    ## print node variables
    if isfield(job_node, "vars") && !isempty(job_node.vars)
      fprintf(fid, "VARS %s", job_nodes(n).name);
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
      fprintf(fid, "PARENT %s CHILD", job_nodes(n).name);
      for i = 1:length(job_node.child)
        fprintf(fid, " %s", job_nodes(job_node.child(i)).name);
      endfor
      fprintf(fid, "\n");
    endif
      
  endfor
  fclose(fid);

  ## create job node output directory names, and check that they do not exist
  for n = 1:length(job_nodes)
    if !mkdir(job_nodes(n).dir)
      error("%s: failed to make directory '%s'", funcName, job_nodes(n).dir);
    endif
  endfor

endfunction
