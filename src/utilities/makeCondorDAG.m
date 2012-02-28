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

## Generate a Condor DAG submission file
## Syntax:
##   makeCondorDAG(dagfile, dagopts)
## where:
##   dagfile  = Condor DAG file
##   dagnodes = structure array of Condor DAG nodes

function makeCondorDAG(dagfile, dagnodes)

  ## check input
  assert(ischar(dagfile));
  assert(isstruct(dagnodes));
  jobnames = {dagnodes.jobname};
  for n = 1:length(dagnodes)
    dagnode = dagnodes(n);

    ## check node
    if !isfield(dagnode, "jobname")
      error("%s: missing DAG field 'jobname'", funcName);
    endif
    if length(find(strcmp(dagnode.jobname, jobnames))) > 1
      error("%s: job name 'jobname' is not unique", funcName);
    endif
    if !isfield(dagnode, "jobfile")
      error("%s: missing DAG field 'jobfile'", funcName);
    endif
    if isfield(dagnode, "vars")
      if !isstruct(dagnode.vars)
        error("%s: DAG field 'vars' must be a struct", funcName);
      endif
      vars = fieldnames(dagnode.vars);
      for i = 1:length(vars)
        value = dagnode.vars.(vars{i});
        if !ischar(value)
          error("%s: value of DAG variable '%s' must be a string", funcName, vars{i});
        endif
      endfor
    endif

    ## check node children
    if isfield(dagnode, "child")
      if !iscell(dagnode.child)
        error("%s: 'child' must be a cell array", funcName);
      endif
      for i = 1:length(dagnode.child)
        if !any(strcmp(dagnode.child{i}, jobnames))
          error("%s: undefined node child '%s'", funcName, dagnode.child{i});
        endif
      endfor
    endif

  endfor

  ## print DAG description to file
  fdag = fopen(dagfile, "w");
  if (fdag < 0)
    error("%s: could not open '%s'", funcName, dagfile);
  endif
  for n = 1:length(dagnodes)
    dagnode = dagnodes(n);

    ## print node
    fprintf(fdag, "JOB %s %s\n", dagnode.jobname, dagnode.jobfile);

    ## print node variables
    if isfield(dagnode, "vars")
      fprintf(fdag, "VARS %s", dagnode.jobname);
      vars = fieldnames(dagnode.vars);
      for i = 1:length(vars)
        value = dagnode.vars.(vars{i});
        value = strrep(strrep(value, "\\", "\\\\"), "\"", "\\\"");
        fprintf(fdag, " %s=\"%s\"", vars{i}, value);
      endfor
      fprintf(fdag, "\n");
    endif

    ## print node retries
    if isfield(dagnode, "retry")
      fprintf(fdag, "RETRY %s %d\n", dagnode.jobname, dagnode.retry);
    endif

    ## print node children
    if isfield(dagnode, "child")
      fprintf(fdag, "PARENT %s CHILD", dagnode.jobname);
      fprintf(fdag, " %s", dagnode.child{:});
      fprintf(fdag, "\n");
    endif
      
    fprintf(fdag, "\n");
  endfor
  fclose(fdag);

endfunction
