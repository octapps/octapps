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

## Run script from command line. This function is used by ./octapps_run
## to parse the command line and call the script. Command-line options
## are given as either
##   --name <value>   or   --name=<value>
## and are designed to be parsed further by parseOptions().

function octapps_run(octapps_run_script, function_name)

  ## check that function_name exists in Octave path
  try
    function_handle = str2func(function_name);
  catch
    error("%s: no function '%s', or function produces a parse error.", octapps_run_script, function_name);
  end_try_catch

  ## get command line arguments passed to script, which start
  ## after the command-line argument '/dev/null'
  args = argv();
  args = args((strmatch("/dev/null", args)(1)+1):end);

  ## stupid Octave; if no command-line arguments are given to script, argv()
  ## will contain the entire Octave command-line, instead of simply the
  ## arguments after the script name! so we have to check for this
  if length(args) > 0 && strcmp(args{end}, program_invocation_name)
    args = {};
  endif

  ## print caller's usage if --help is given
  if length(strmatch("--help", args)) > 0
    feval("help", function_name);
    exit(1);
  endif

  ## parse command-line arguments
  opts = parseCommandLine(args);

  ## run script
  feval(function_handle, opts{:});

endfunction
