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

## Command line argument pre-parser: use with parseOptions to
## call Octave functions from the command line.
## Usage:
##
##   function MyScript(varargin)
##     parseOptions(varargin, ...);
##     ...
##   endfunction
##
##   if runningAsScript
##     MyScript(parseCommandLine(){:});
##   endif
##
## Command-line options may be given either as
##   '--name' 'value'
## or as
##   '--name=value'
## is <name> does not accept a 'char' value (as determined by
## parseOptions), <value> will be treated as an Octave expression
## and eval()uated, surrounded by []s.

function opts = parseCommandLine(varargin)

  ## get command-line arguments
  if length(varargin) > 0
    args = varargin;   # for debugging purposes
  else
    args = argv();
  endif

  ## stupid Octave; if no command-line arguments are given to script, argv()
  ## will contain the entire Octave command-line, instead of simply the
  ## arguments after the script name! so we have to check for this
  if length(args) > 0 && strcmp(args{end}, program_invocation_name)
    args = {};
  endif

  ## print caller's usage if --help is given
  if any(cellfun(@(x) strcmp(x, "--help"), args))
    
    ## get name of calling function
    stack = dbstack();
    if numel(stack) > 1
      callername = stack(2).name;
    else
      error("No help information for %s\n", program_invocation_name);
    endif
    
    ## get plain help text of calling function
    [helptext, helpfmt] = get_help_text(callername);
    if !strcmp(helpfmt, "plain text")
      [helptext, helpstat] = __makeinfo__(helptext, "plain text");
      if !helpstat
        error("No plain-text help information for %s\n", program_invocation_name);
      endif
    endif
    
    ## remove shebang from help text
    if strncmp(helptext, "!", 1)
      i = min(strfind(helptext, "\n"));
      if isempty(i)
        error("No help information for %s\n", program_invocation_name);
      else
        helptext = helptext(i+1:end);
      endif
    endif
    
    ## print help text and exit
    printf("\n%s\n", helptext);
    error("Exiting %s after displaying help\n", program_invocation_name);
    
  endif
  
  ## parse command-line arguments
  opts = {};
  n = 1;
  while n <= length(args)
    arg = args{n++};
    argvalstr = [];

    ## if argument is '--', just parse it along, since
    ## it might be being used as an option separator
    if strcmp(arg, "--")
      opts{end+1} = arg;
      continue
    endif
    
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
      
    else
      error("%s: Could not parse argument '%s'", funcName, arg);
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
      error("%s: Could to determine the value of argument '%s'", funcName, argcmdname);
    endif

    ## add argument and value to options
    opts = {opts{:}, argname, argvalstr};

  endwhile

endfunction
