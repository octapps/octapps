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
##   "merge_function": function used to merge results from two Condor
##                     jobs with the same parameters, as determined by
##                     the DAG job name 'vars' field. Syntax is:
##                       merged_res = merge_function(merged_res, res)
##                     where 'res' are to be merged into 'merged_res'
##   "norm_function":  if given, function used to normalise merged results
##                     after all Condor jobs have been processed. Syntax is:
##                       merged_res = norm_function(merged_res, n)
##                     where 'n' is the number of merged Condor jobs

function mergeCondorResults(varargin)

  ## parse options
  parseOptions(varargin,
               {"dag_name", "char"},
               {"merge_function", "function,scalar"},
               {"norm_function", "function,scalar", []},
               []);

  ## load job node data
  dag_nodes_file = strcat(dag_name, "_nodes.bin.gz");
  printf("%s: loading '%s' ...", funcName, dag_nodes_file);
  load(dag_nodes_file);
  assert(isstruct(job_nodes));
  printf(" done\n");

  ## load merged job results file if it already exists
  dag_merged_file = strcat(dag_name, "_merged.bin.gz");
  if exist(dag_merged_file, "file")
    printf("%s: loading '%s' ...", funcName, dag_merged_file);
    load(dag_merged_file);
    assert(isstruct(merged));
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
    merged.cpu_time = 0;
    merged.wall_time = 0;

    ## get list of variable names and their unique values
    merged.var_names = sort(fieldnames(job_nodes(1).vars));
    merged.var_values = cell(size(merged.var_names));
    for i = 1:length(merged.var_names)
      var_values_i = arrayfun(@(n) n.vars.(merged.var_names{i}), job_nodes, "UniformOutput", false);
      if ischar(var_values_i{1})
        merged.var_values{i} = unique(var_values_i);
      else
        merged.var_values{i} = unique([var_values_i{:}]);
      endif
    endfor
    merged.results = cell(cellfun(@(v) length(v), merged.var_values));
    merged.jobs_per_result = zeros(size(merged.results));

    ## need to merge all jobs
    merged.jobs_to_merge = 1:length(job_nodes);

  endif

  ## iterate over jobs which need to be merged
  prog = [];
  jobs_to_merge = merged.jobs_to_merge;  
  for n = jobs_to_merge

    ## determine index into merged results cell array
    subs = cell(size(merged.var_names));
    for i = 1:length(merged.var_names)
      subs{i} = find(merged.var_values{i} == job_nodes(n).vars.(merged.var_names{i}));
      assert(length(subs{i}) == 1);
    endfor
    idx = sub2ind(size(merged.results), subs{:});
    ++merged.jobs_per_result(idx);

    ## load job node results, skipping missing files
    node_result_file = glob(fullfile(job_nodes(n).dir, "stdres.*"));
    if size(node_result_file, 1) < 1
      printf("%s: skipping job node '%s'; no result file\n", funcName, job_nodes(n).name);
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

    ## add up total CPU and wall time
    merged.cpu_time += node_results.cpu_time;
    merged.wall_time += node_results.wall_time;

    ## if merged results are empty, simply copy job node results
    if isempty(merged.results{idx})
      merged.results{idx} = node_results.results;
    else

      ## merge job node results using merge function
      for i = 1:numel(merged.results{idx})
        merged.results{idx}{i} = feval(merge_function, merged.results{idx}{i}, node_results.results{i});
      endfor

    endif

    ## mark job as having been merged
    merged.jobs_to_merge(merged.jobs_to_merge == n) = [];

    ## save merged jobs results at periodic intervals
    if mod(n, 100) == 0
      printf("%s: saving '%s' ...", funcName, dag_merged_file);
      save("-binary", "-zip", dag_merged_file, "merged");
      printf(" done\n");
    endif

    ## print progress
    prog = printProgress(prog, length(find(jobs_to_merge <= n)), length(jobs_to_merge));

  endfor

  ## if given, call normalisation function for each merged results
  if !isempty(norm_function)
    for idx = 1:numel(merged.results)
      for i = 1:numel(merged.results{idx})
        merged.results{idx}{i} = feval(norm_function, merged.results{idx}{i}, merged.jobs_per_result(idx));
      endfor
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
