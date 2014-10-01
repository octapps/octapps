## Copyright (C) 2014 Karl Wette
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

## Merge results from a Condor DAG.
## Usage:
##   mergeCondorResults("opt", val, ...)
## Options:
##   "dag_name":       name of Condor DAG, used to name DAG submit file.
##                     Merged results are saved as 'dag_name' + _merged.bin.gz
##   "merge_function": function(s) used to merge results from two Condor
##                     jobs with the same parameters, as determined by
##                     the DAG job name 'vars' field. Syntax is:
##                       merged_res = merge_function(merged_res, res)
##                     where 'res' are to be merged into 'merged_res'.
##                     One function per element of job 'results' must be given.
##   "norm_function":  if given, function(s) used to normalise merged results
##                     after all Condor jobs have been processed. Syntax is:
##                       merged_res = norm_function(merged_res, n)
##                     where 'n' is the number of merged Condor jobs
##                     One function per element of job 'results' must be given.

function mergeCondorResults(varargin)

  ## parse options
  parseOptions(varargin,
               {"dag_name", "char"},
               {"merge_function", "function,vector"},
               {"norm_function", "function,vector", []},
               []);

  ## load job node data
  dag_nodes_file = strcat(dag_name, "_nodes.bin.gz");
  printf("%s: loading '%s' ...", funcName, dag_nodes_file);
  load(dag_nodes_file);
  assert(isstruct(job_nodes), "%s: 'job_nodes' is not a struct", funcName);
  printf(" done\n");

  ## load merged job results file if it already exists
  dag_merged_file = strcat(dag_name, "_merged.bin.gz");
  if exist(dag_merged_file, "file")
    printf("%s: loading '%s' ...", funcName, dag_merged_file);
    load(dag_merged_file);
    assert(isstruct(merged), "%s: 'merged' is not a struct", funcName);
    printf(" done\n");

    ## return if all jobs have been merged
    if !isfield(merged, "jobs_to_merge")
      printf("%s: skipping DAG '%s'; no more jobs to merge\n", funcName, dag_name);
      return;
    endif

  else

    ## otherwise create merged struct
    merged = struct;
    merged.dag_name = dag_name;
    merged.cpu_time = [];
    merged.wall_time = [];

    ## get list of variable names and their unique values
    merged.vars = struct;
    var_names = sort(fieldnames(job_nodes(1).vars));
    for i = 1:length(var_names)
      var_values_i = arrayfun(@(n) n.vars.(var_names{i}), job_nodes, "UniformOutput", false);
      if ischar(var_values_i{1})
        merged.vars.(var_names{i}) = unique(var_values_i);
      else
        merged.vars.(var_names{i}) = unique([var_values_i{:}]);
      endif
    endfor
    merged.arguments = merged.results = cell(cellfun(@(n) length(merged.vars.(n)), var_names));
    merged.jobs_per_result = zeros(size(merged.results));

    ## need to merge all jobs
    merged.jobs_to_merge = 1:length(job_nodes);

  endif

  ## iterate over jobs which need to be merged
  prog = [];
  jobs_to_merge = merged.jobs_to_merge;
  job_merged_count = 0;
  job_merged_total = length(jobs_to_merge);
  job_save_period = round(max(10, min(0.1*length(jobs_to_merge), 100)));
  var_names = sort(fieldnames(merged.vars));
  for n = jobs_to_merge

    ## determine index into merged results cell array
    subs = cell(size(var_names));
    for i = 1:length(var_names)
      if ischar(job_nodes(n).vars.(var_names{i}))
        subs{i} = find(strcmp(merged.vars.(var_names{i}), job_nodes(n).vars.(var_names{i})));
      else
        subs{i} = find(merged.vars.(var_names{i}) == job_nodes(n).vars.(var_names{i}));
      endif
      assert(length(subs{i}) == 1, "%s: no index into merged results array found", funcName);
    endfor
    ++merged.jobs_per_result(subs{:});

    ## load job node results, skipping missing files
    node_result_file = glob(fullfile(job_nodes(n).dir, "stdres.*"));
    if size(node_result_file, 1) < 1
      printf("%s: skipping job node '%s'; no result file\n", funcName, job_nodes(n).name);
      --job_merged_total;
      continue
    elseif size(node_result_file, 1) > 1
      error("%s: job node directory '%s' contains multiple result files", funcName, job_nodes(n).dir);
    endif
    try
      node_results = load(node_result_file{1});
    catch
      printf("%s: skipping job node '%s'; could not open result file\n", funcName, job_nodes(n).name);
      continue
    end_try_catch
    assert(length(merge_function) == length(node_results.results),
           "%s: length of 'merge_function' does not match number of job node '%s' results", funcName, job_nodes(n).name);
    assert(length(norm_function) == length(node_results.results),
           "%s: length of 'norm_function' does not match number of job node '%s' results", funcName, job_nodes(n).name);

    ## save job node arguments, and check for consistency between jobs
    if isempty(merged.arguments{subs{:}})
      merged.arguments{subs{:}} = node_results.arguments;
    else
      args1 = stringify(merged.arguments{subs{:}});
      args2 = stringify(node_results.arguments);
      if !strcmp(args1, args2)
        error("%s: inconsistent job node arguments: '%s' vs '%s'", args1, args2);
      endif
    endif

    ## add to list of CPU and wall times
    merged.cpu_time(end+1) = node_results.cpu_time;
    merged.wall_time(end+1) = node_results.wall_time;

    ## merge job node results using merge function
    for i = 1:numel(node_results.results)
      try
        prev_results = merged.results{subs{:},i};
      catch
        prev_results = merged.results{subs{:},i} = [];
      end_try_catch
      merged.results{subs{:},i} = feval(merge_function(i), prev_results, node_results.results{i});
    endfor

    ## mark job as having been merged
    merged.jobs_to_merge(merged.jobs_to_merge == n) = [];

    ## save merged jobs results at periodic intervals
    ++job_merged_count;
    if mod(job_merged_count, job_save_period) == 0
      printf("%s: saving '%s' ...", funcName, dag_merged_file);
      save("-binary", "-zip", dag_merged_file, "merged");
      printf(" done\n");
    endif

    ## print progress
    prog = printProgress(prog, job_merged_count, job_merged_total);

  endfor

  ## flatten merged argments into struct array, if possible
  arguments = zeros(size(merged.arguments));
  for idx = 1:numel(merged.arguments)
    try
      arguments(idx) = struct(merged.arguments{:});
    catch
      arguments = merged.arguments;
      break;
    end_try_catch
  endfor
  merged.arguments = arguments;

  ## if given, call normalisation function for each merged results
  if !isempty(norm_function)
    siz = [cellfun(@(n) length(merged.vars.(n)), var_names), length(norm_function)];
    for idx = 1:prod(siz)
      [subs{1:length(siz)}] = ind2sub(siz, idx);
      merged.results{subs{:}} = feval(norm_function(subs{end}), merged.results{subs{:}}, merged.jobs_per_result(subs{1:end-1}));
    endfor
  endif

  ## save merged job results for later use
  if isempty(merged.jobs_to_merge)
    merged = rmfield(merged, "jobs_to_merge");
  endif
  printf("%s: saving '%s' ...", funcName, dag_merged_file);
  save("-binary", "-zip", dag_merged_file, "merged");
  printf(" done\n");

endfunction
