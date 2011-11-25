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

## Generate a Condor job submission file
## Syntax:
##   makeCondorJob(jobfile, jobopts)
## where:
##   jobfile = Condor job file
##   jobopts = structure of Condor job options

function makeCondorJob(jobfile, jobopts)

  ## check input
  assert(ischar(jobfile));
  assert(isstruct(jobopts));

  ## print job description to string
  job = "";
  joboptnames = fieldnames(jobopts);
  for n = 1:length(joboptnames)
    joboptname = joboptnames{n};
    joboptval = jobopts.(joboptname);

    ## some job options are special cases
    switch joboptname

      case "queue"
        ## skip 'queue' until end of job file

      case "environment"
        
        ## print environment variables and their current values
        if !iscell(joboptval)
          error("%s: 'environment' must be a cell array", funcName);
        endif
        job = cstrcat(job, "environment = \"");
        for i = 1:length(joboptval)
          job = cstrcat(job, sprintf("%s=%s ", joboptval{i}, getenv(joboptval{i})));
        endfor
        job = cstrcat(job, "\"\n");

      case "arguments"

        ## print command arguments
        if !isstruct(joboptval)
          error("%s: 'arguments' must be a struct", funcName);
        endif
        argnames = fieldnames(joboptval);
        job = cstrcat(job, sprintf("arguments = \"%s", joboptval.__preamble));
        for i = 1:length(argnames)
          argname = argnames{i};
          if strncmp(argname, "__", 2)
            continue;
          endif
          argval = joboptval.(argname);

          ## handle short options
          if length(argname) == 1
            job = cstrcat(job, sprintf(" '-%s' '", argname));
          else
            job = cstrcat(job, sprintf(" '--%s=", argname));
          endif

          ## argument value formats
          if ischar(argval)
            argval = strrep(argval, "'", "''");
            argval = strrep(argval, "\"", "\"\"");
            job = cstrcat(job, sprintf("%s", argval));
          elseif isscalar(argval) && isreal(argval)
            job = cstrcat(job, sprintf("%.16g", argval));
          elseif islogical(argval)
            job = cstrcat(job, sprintf("%d", argval));
          else
            error("%s: argument '%s' is an unsupported format", funcName, argname);
          endif
          job = cstrcat(job, "'");

        endfor
        job = cstrcat(job, "\"\n");         

      otherwise
        
        ## print option name
        job = cstrcat(job, sprintf("%s = ", joboptname));

        ## print option value
        ## * cells are treated as comma-separated lists
        if iscell(joboptval)
          job = cstrcat(job, sprintf("%s", joboptval{1}));
          job = cstrcat(job, sprintf(",%s", joboptval{2:end}));
        else
          job = cstrcat(job, sprintf("%s", joboptval));
        endif
        job = cstrcat(job, "\n");

    endswitch

  endfor

  ## queue jobs
  if isfield(jobopts, "queue")
    jobopts.queue = 1;
  endif
  job = cstrcat(job, sprintf("queue %d\n", jobopts.queue));

  ## create job submission file
  fjob = fopen(jobfile, "w");
  if (fjob < 0)
    error("%s: could not open '%s'", funcName, jobfile);
  endif
  fprintf(fjob, "%s", job);
  fclose(fjob);

endfunction
