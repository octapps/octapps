## Copyright (C) 2012, 2014 Karl Wette
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
##   opts = parseCommandLine(delim, args)
## where
##   delim = remove all command-line arguments that appear before this
##           argument, if it is given on the command line (optional)
##   args  = command-line arguments to parse; if not supplied,
##           get arguments from command-line passed to Octave

function opts = parseCommandLine(delim=[], args={})

  ## check input
  assert(isempty(delim) || ischar(delim));
  assert(iscell(args));

  ## is args is empty, get arguments from command-line passed to Octave
  if isempty(args)
   args = evalin("base", "argv()(1:nargin)");
  endif

  ## remove all command-line arguments that appear before 'delim'
  ## (if non-empty), if it is given on the command line
  if !isempty(delim)
    i = strmatch(delim, args);
    if !isempty(i)
      args = args(min(i)+1:end);
    endif
  endif

  ## parse command-line arguments
  opts = struct;
  optname = [];
  optval = [];
  for n = 1:length(args)
    arg = args{n++};

    ## if argument begins with '--'
    if strncmp(arg, "--", 2)

      ## check there is no previous option name
      if !isempty(optname)
        error("%s: option '%s' has no value", funcName, optname);
      endif

      ## if argument contains an '=', split into name=value,
      i = min(strfind(arg, "="));
      if !isempty(i)
        optname = arg(3:i-1);
        optval = arg(i+1:end);
      else
        ## otherwise just store the name
        optname = arg(3:end);
      endif

      ## replace '-' with '_' to make a valid Octave variable name
      optname = strrep(optname, "-", "_");

    else

      ## check there is no previous option value
      if !isempty(optval)
        error("%s: value '%s' has no option name", funcName, optval);
      endif

      ## store value
      optval = arg;

    endif

    ## if we have both option name and value, store then
    if !isempty(optname) && !isempty(optval)
      opts.(optname) = optval;
      optname = [];
      optval = [];
    endif

  endfor

  ## check for no remaining arguments
  if !isempty(optname)
    error("%s: option '%s' has no value", funcName, optname);
  endif
  if !isempty(optval)
    error("%s: value '%s' has no option name", funcName, optval);
  endif

  ## convert to flat cell array of {"name", "value", ...} pairs
  opts = {{fieldnames(opts){:}; struct2cell(opts){:}}{:}};

endfunction
