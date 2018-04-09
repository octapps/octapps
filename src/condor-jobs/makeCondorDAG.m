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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{dag_file} =} makeCondorDAG ( @var{opt}, @var{val}, @dots{} )
##
## Set up a Condor DAG for running Condor jobs.
##
## @heading Arguments
##
## @table @var
## @item dag_file
## name of Condor DAG submit file
##
## @end table
##
## @heading Options
##
## @table @code
## @item dag_name
## name of Condor DAG, used to name DAG submit file
##
## @item job_nodes
## struct array of job nodes, which has the following fields:
##
## @table @code
## @item file
## name of Condor submit file for this job
##
## @item vars
## struct of variable substitutions to make
##
## @item child
## array indexing child job nodes for this node
##
## @end table
##
## @item retries
## how man times to retry Condor jobs (default: 0)
##
## @item sub_dags
## split DAG into this many subfiles (default: 1)
##
## @end table
##
## @end deftypefn

function dag_file = makeCondorDAG(varargin)

  ## parse options
  parseOptions(varargin,
               {"dag_name", "char"},
               {"job_nodes", "struct"},
               {"retries", "integer,positive", 0},
               {"sub_dags", "integer,strictpos", 1},
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

    ## check for extra fields
    job_fields = fieldnames(job_node);
    job_fields(strcmp("file", job_fields)) = [];
    job_fields(strcmp("vars", job_fields)) = [];
    job_fields(strcmp("child", job_fields)) = [];
    if length(job_fields) > 0
      error("%s: unknown job fields:%s", funcName, sprintf(" '%s'", job_fields{:}));
    endif

  endfor

  ## check that job submit files exist
  for n = 1:length(job_nodes)
    if !exist(job_nodes(n).file, "file")
      error("%s: job file '%s' does not exist", funcName, job_nodes(n).file);
    endif
  endfor

  ## check that DAG submit file(s) and output base directory do not exist
  for s = 1:sub_dags
    if sub_dags > 1
      dag_file{s} = sprintf("%s_%02i.dag", dag_name, s);
    else
      dag_file{s} = sprintf("%s.dag", dag_name);
    endif
    if exist(dag_file{s}, "file")
      error("%s: DAG file '%s' already exists", funcName, dag_file{s});
    endif
  endfor
  job_out_base_dir = strcat(dag_name, ".out");
  if exist(job_out_base_dir, "dir")
    error("%s: job output base directory '%s' already exists", funcName, job_out_base_dir);
  endif

  ## create job node name and output directory names
  job_out_dirs = {job_out_base_dir};
  job_num_fmt_len = 2*(1 + floor(log10(max(1, length(job_nodes) - 1)) / 2));
  job_num_fmt = sprintf("%%0%ii", job_num_fmt_len);
  for n = 1:length(job_nodes)
    job_num = sprintf(job_num_fmt, n-1);
    job_nodes(n).name = strcat(dag_name, ".", job_num);
    job_num_split = mat2cell(job_num, 1, 2*ones(1, job_num_fmt_len/2));
    job_nodes(n).dir = job_out_base_dir;
    for i = 1:length(job_num_split)
      job_nodes(n).dir = fullfile(job_nodes(n).dir, job_num_split{i});
      job_out_dirs{end+1} = job_nodes(n).dir;
    endfor
  endfor
  job_out_dirs = unique(job_out_dirs);

  ## write Condor DAG submit file, with nodes in reverse order
  for s = 1:sub_dags
    fid(s) = fopen(dag_file{s}, "w");
    if fid(s) < 0
      error("%s: could not open file '%s' for writing", funcName, dag_file{s});
    endif
  endfor
  s = 0;
  for n = length(job_nodes):-1:1

    ## increment sub-dag index
    s = mod(s, sub_dags) + 1;

    ## print node
    job_node_file = fullfile(pwd, job_nodes(n).file);
    job_node_dir = fullfile(pwd, job_nodes(n).dir);
    fprintf(fid(s), "\n");
    fprintf(fid(s), "JOB %s %s DIR %s\n", job_nodes(n).name, job_node_file, job_node_dir);
    fprintf(fid(s), "RETRY %s %d\n", job_nodes(n).name, retries);

    ## print node variables
    if isfield(job_nodes(n), "vars") && !isempty(job_nodes(n).vars)
      fprintf(fid(s), "VARS %s", job_nodes(n).name);
      vars = fieldnames(job_nodes(n).vars);
      for i = 1:length(vars)
        value = stringify(job_nodes(n).vars.(vars{i}));
        value = strrep(value, "'", "''");
        value = strrep(value, "\"", "\"\"");
        value = strrep(value, "\\", "\\\\");
        value = strrep(value, "\"", "\\\"");
        fprintf(fid(s), " %s=\"%s\"", vars{i}, value);
      endfor
      fprintf(fid(s), "\n");
    endif

    ## print node children
    if isfield(job_nodes(n), "child") && !isempty(job_nodes(n).child)
      fprintf(fid(s), "PARENT %s CHILD", job_nodes(n).name);
      for i = 1:length(job_nodes(n).child)
        fprintf(fid(s), " %s", job_nodes(job_nodes(n).child(i)).name);
      endfor
      fprintf(fid(s), "\n");
    endif

  endfor
  for s = 1:sub_dags
    fclose(fid(s));
  endfor

  ## create job node output directory names, and check that they do not exist
  for i = 1:length(job_out_dirs)
    if !mkdir(job_out_dirs{i})
      error("%s: failed to make directory '%s'", funcName, job_out_dirs{i});
    endif
  endfor

  ## save job node data for later use
  dag_nodes_file = strcat(dag_name, "_nodes.bin.gz");
  save("-binary", "-zip", dag_nodes_file, "job_nodes");

  ## flatten 'dag_file' if only one DAG file
  if sub_dags > 1
    dag_file = dag_file{1};
  endif

endfunction

%!test
%!
%!  oldpwd = pwd;
%!  jobdir = mkpath(tempname(tempdir));
%!  unwind_protect
%!    cd(jobdir);
%!
%!    jobname = "test_makeCondorDAG";
%!    job = makeCondorJob("job_name", jobname, ...
%!                        "log_dir", pwd,
%!                        "func_name", "__test_parseOptions__", ...
%!                        "func_nargout", 1, ...
%!                        "arguments", { ...
%!                                       "--real-strictpos-scalar", "$(x)", ...
%!                                       "--integer-vector", [3,9,5], ...
%!                                       "--string", "Hi there", ...
%!                                       "--cell", {1,{2,3}}, ...
%!                                     }, ...
%!                        "data_files", { ...
%!                                        fullfile(fileparts(file_in_loadpath("readSFT.m")), "SFT-good") ...
%!                                      }, ...
%!                        "extra_condor", { ...
%!                                          "requirements", "TARGET.has_avx == true", ...
%!                                        } ...
%!                       );
%!    assert(exist("./test_makeCondorDAG.job") == 2);
%!    assert(exist("./test_makeCondorDAG.sh") == 2);
%!    assert(exist("./test_makeCondorDAG.in") == 7);
%!    assert(exist("./test_makeCondorDAG.in/.exec") == 7);
%!    assert(exist("./test_makeCondorDAG.in/.func") == 7);
%!    assert(exist("./test_makeCondorDAG.in/SFT-good") == 2);
%!
%!    nodes = struct;
%!    node = struct;
%!    node.file = job;
%!    node.vars.x = 1.23;
%!    nodes(1) = node;
%!    node.vars.x = 4.56;
%!    nodes(2) = node;
%!    makeCondorDAG("dag_name", jobname, "job_nodes", nodes);
%!    assert(exist("./test_makeCondorDAG.dag") == 2);
%!    assert(exist("./test_makeCondorDAG_nodes.bin.gz") == 2);
%!    assert(exist("./test_makeCondorDAG.out") == 7);
%!    assert(exist("./test_makeCondorDAG.out/00") == 7);
%!    assert(exist("./test_makeCondorDAG.out/01") == 7);
%!
%!  unwind_protect_cleanup
%!    cd(oldpwd);
%!  end_unwind_protect
