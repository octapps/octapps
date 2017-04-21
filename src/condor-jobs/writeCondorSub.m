## Copyright (C) 2011,2012,2017 Karl Wette
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

## Write a Condor job submit file
## Usage:
##   writeCondorSub(job_file, sub_key, sub_value, ...)
## where:
##   job_file:  name of Condor job submit file
##   sub_key:   Condor job submit file key
##   sub_value: value of Condor job submit file key

function writeCondorSub(varargin)

  ## check input
  job_file = varargin{1};
  assert(ischar(job_file), "%s: 'job_file' is not a string", funcName);
  job_spec = varargin(2:end);
  assert(mod(length(job_spec), 2) == 0, "%s: unmatched 'sub_key'/'sub_value' arguments");

  ## write Condor job submit file
  fid = fopen(job_file, "w");
  if fid < 0
    error("%s: could not open file '%s' for writing", funcName, job_file);
  endif
  fprintf(fid, "%s = %s\n", job_spec{:});
  fprintf(fid, "queue 1\n");
  fclose(fid);

endfunction
