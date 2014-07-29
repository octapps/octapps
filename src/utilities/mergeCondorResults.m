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

  ## return if merged job results already exist
  dag_merged_file = strcat(dag_name, "_merged.bin.gz");
  if exist(dag_merged_file, "file")
    return
  endif

  ## load job node data
  load(strcat(dag_name, "_nodes.bin.gz"));
  assert(isstruct(job_nodes));

  ## create merged struct
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
  merged_job_count = zeros(size(merged.results));

  ## iterate over jobs
  prog = [];
  for n = 1:length(job_nodes)

    ## determine index into merged results cell array
    subs = cell(size(merged.var_names));
    for i = 1:length(merged.var_names)
      subs{i} = find(merged.var_values{i} == job_nodes(n).vars.(merged.var_names{i}));
      assert(length(subs{i}) == 1);
    endfor
    idx = sub2ind(size(merged.results), subs{:});
    ++merged_job_count(idx);

    ## load job node results
    node_result_file = ls(fullfile(job_nodes(n).dir, "stdres.*"));
    if size(node_result_file, 1) > 1
      error("%s: job node directory '%s' contains multiple result files", funcName, job_nodes(n).dir);
    endif
    node_results = load(node_result_file);

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

    ## print progress
    prog = printProgress(prog, n, length(job_nodes));

  endfor

  ## if given, call normalisation function for each merged results
  if !isempty(norm_function)
    for idx = 1:numel(merged.results)
      for i = 1:numel(merged.results{idx})
        merged.results{idx}{i} = feval(norm_function, merged.results{idx}{i}, merged_job_count(idx));
      endfor
    endfor
  endif

  ## save merged job results for later use
  save("-binary", "-zip", dag_merged_file, "merged");

endfunction
