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

## Tests the status of a Condor DAG
## Syntax:
##   dagstatus = statusOfCondorDAG(dagfile)
## where:
##   dagstatus = 'x' : DAG does not exist
##               'u' : DAG has not been submitted
##               'r' : DAG is still running
##               'y' : DAG completed successfully
##               'n' : DAG did not complete successfully
##   dagfile   = Condor DAG file

function dagstatus = statusOfCondorDAG(dagfile)

  ## check for existence of DAG
  if !exist(dagfile, "file")
    dagstatus = "x";
    return;
  endif

  ## check for existence of DAG output file
  dagoutfile = strcat(dagfile, ".dagman.out");
  if !exist(dagoutfile, "file")
    dagstatus = "u";
    return;
  endif

  ## get last line of DAG output file
  [status, out] = system(sprintf("tail -1 %s 2>/dev/null", dagoutfile));
  if status != 0
    error("%s: 'tail' failed", funcName);
  endif
  
  ## split last line into tokens
  tokens = strsplit(out, " ");
  
  ## determine if Condor DAGMan has exited
  done = (length(tokens) == 11) \
      && strcmp(tokens{5}, "(condor_DAGMAN)") \
      && strcmp(tokens{8}, "EXITING") \
      && strcmp(tokens{9}, "WITH") \
      && strcmp(tokens{10}, "STATUS");
  if !done
    dagstatus = "r";
    return;
  endif

  ## get status
  status = str2num(tokens{11});
  if status == 0
    dagstatus = "y";
  else
    dagstatus = "n";
  endif

endfunction
