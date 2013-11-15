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

## Return command-line options in form expected by parseOptions().
## Command-line options of the form:
##   --name <value>   or   --name=<value>
## are converted into option-value pairs; other options are unchanged.
## Syntax:
##   opts = parseCommandLine(delim, cmdline)
## where
##   delim   = remove all command-line arguments that appear before this
##             argument, if it is given on the command line (optional)
##   cmdline = optional command-line like string,
##             if not passed: get directly from actual commandline

function opts = parseCommandLine(delim=[], cmdline=[])

  ## get command-line arguments passed to Octave
  if ( length(cmdline) == 0 ) # no fake commandline-in-a-string passed, get arguments from actual commandline
   args = evalin("base", "argv()(1:nargin)");
  else # use fake  commandline-in-a-string
   args = cmdline;
  endif

  ## remove all command-line arguments that appear before delim,
  ## if it is given on the command line.
  if !isempty(delim)
    i = strmatch(delim, args);
    if !isempty(i)
      args = args(min(i)+1:end);
    endif
  endif

  ## parse command-line arguments
  opts = {};
  n = 1;
  while n <= length(args)
    arg = args{n++};
    argvalstr = [];

    ## check that argument begins with '--'
    if strncmp(arg, "--", 2)
      
      ## if argument contains an '=', split into name=value,
      i = min(strfind(arg, "="));
      if !isempty(i)
        argcmdname = arg(3:i-1);
        argvalstr = arg(i+1:end);
      else
        ## otherwise just store the name
        argcmdname = arg(3:end);
      endif

      ## check for non-empty name/values
      if isempty(argcmdname) || isempty(argvalstr)
        error("%s: Empty name/value in argument '%s'", funcName, arg);
      endif
      
    else

      ## pass option along unchanged
      opts{end+1} = arg;
      continue

    endif
    
    ## replace '-' with '_' to make a valid Octave variable name
    argname = strrep(argcmdname, "-", "_");
    
    ## if no argument value string has been found yet, check next argument
    if isempty(argvalstr) && n <= length(args)
      nextarg = args{n++};
      ## if next argument isn't itself an argument, use as a value string
      if !strncmp(nextarg, "--", 2)
        argvalstr = nextarg;
      endif
    endif
    if isempty(argvalstr)
      error("%s: Could not determine the value of argument '%s'", funcName, argcmdname);
    endif

    ## add argument and value to options
    opts = {opts{:}, argname, argvalstr};

  endwhile

endfunction
