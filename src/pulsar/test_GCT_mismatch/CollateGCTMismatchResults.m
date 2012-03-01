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

## Collate GCT mismatch results from MakeGCTMismatchTestDAG

function CollateGCTMismatchResults(run_ID)

  ## injection results
  injection_results = {};

  ## loop over injection result files
  injection = 0;
  while true
    ++injection;

    ## injection result directory and file
    result_file = fullfile(run_ID, sprintf("results.%i", injection));
    if !exist(result_file, "file")
      --injection;
      break;
    endif

    ## load results and add to injection results
    result = load(result_file);
    injection_results{injection} = result;

  endwhile

  ## print number of results collated
  printf("Number of injection results collated: %i\n", injection);

  ## save injection results file
  save("-zip", strcat(run_ID, "_results.dat.gz"), "injection_results");

endfunction
