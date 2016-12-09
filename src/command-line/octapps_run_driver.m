## Copyright (C) 2016 Karl Wette
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

## Run an Octapps function from the command line.
##
## Usage:
##
##   octapps_run --help
##     Print this help message.
##
##   octapps_run <function-name> ... --help
##     Print help message for Octapps function <function-name>
##
##   octapps_run <function-name> [--argument <value>] [--argument=<value>]...
##     Run the Octapps function <function-name> with the given arguments.
##     (The function itself must use parseOptions() to parse its arguments.)
##
##   octapps_run <function-name> ... --printout
##     Print the values of the first <n> output values of <function-name>.
##
##   octapps_run <function-name> ... --printout=<n>
##     Print the values of the first <n> output values of <function-name>.
##
##   octapps_run <function-name> ... --printout=<print-functions>
##     Print output values of <function-name> using <print-functions>.
##     See the following examples, which assume the functions
##       a = f(), [a, b] = g()
##
##     Command                                  Outputs printed
##     -------                                  -------------------
##     octapps_run f --printout=I               a
##     octapps_run f --printout=mean            mean(a)
##     octapps_run f --printout=mean,stdv       mean(a), stdv(a)
##     octapps_run g --printout=I,sin:cos       a, mean(a), cos(b)
##     octapps_run g --printout=~:exp           exp(b)

function octapps_run_driver(func, varargin)

  ## check input
  assert(ischar(func));
  try
    hfunc = str2func(func);
  catch
    error("octapps_run: %s() is not a known function", func);
  end_try_catch

  ## print help on function if requested
  if any(strcmp(varargin, "-h")) || any(strcmp(varargin, "--help"))
    disp(help(func));
    return
  endif

  ## parse command-line arguments
  hprintfuncs = {};
  args = struct;
  argname = argval = [];
  for n = 1:length(varargin)

    ## if argument begins with '--'
    if strncmp(varargin{n}, "--", 2)

      ## check there is no previous argument name
      if !isempty(argname)
        error("octapps_run: argument '%s' has no value", argname);
      endif

      ## if argument contains an '=', split into name=value,
      i = min(strfind(varargin{n}, "="));
      if !isempty(i)
        argname = varargin{n}(3:i-1);
        argval = varargin{n}(i+1:end);
      else
        ## otherwise just store the name
        argname = varargin{n}(3:end);
      endif

      ## replace '-' with '_' to make a valid Octave variable name
      argname = strrep(argname, "-", "_");

    else

      ## check there is no previous argument value
      if !isempty(argval)
        error("octapps_run: value '%s' has no argument name", argval);
      endif

      ## store value
      argval = varargin{n};

    endif

    if !isempty(argname)

      ## handle special argument --printout
      if strcmp(argname, "printout")

        if !isempty(argval)

          ## try --printout=<number of output arguments>
          val = str2double(argval);
          if !isnan(val)
            assert(mod(val, 1) == 0, "octapps_run: value to --printout must be an integer");
            assert(val > 0, "octapps_run: value to --printout must be strictly positive");
            [hprintfuncs{1:val}] = deal(@print_identity);
          else

            ## try --printout=<list of print functions>
            printfuncs = strsplit(argval, ":");
            for i = 1:length(printfuncs)
              printfuncs{i} = strsplit(printfuncs{i}, ",");
              for j = 1:length(printfuncs{i})

                ## interpret print function
                switch printfuncs{i}{j}

                  case "I"   ## identity function
                    hprintfuncs{i}{j} = @print_identity;

                  case "~"   ## skip argument
                    hprintfuncs{i}{j} = @print_skip;

                  otherwise   ## regular function
                    try
                      hprintfuncs{i}{j} = str2func(printfuncs{i}{j});
                    catch
                      error("octapps_run: %s() is not a known function", printfuncs{i}{j});
                    end_try_catch

                endswitch

              endfor
            endfor
            
          endif

          ## reset parser for new argument
          argname = argval = [];

        elseif n == length(varargin) || strncmp(varargin{n+1}, "--", 2)

          ## if --printout has no argument, default to printing all outputs
          try
            nout = nargout(h);
          catch
            nout = 1;
          end_try_catch
          [printfuncs{1:nout}] = deal({"I"});

          ## reset parser for new argument
          argname = argval = [];

        endif

      elseif !isempty(argval)  ## handle ordinary arguments

        args.(argname) = argval;

        ## reset parser for new argument
        argname = argval = [];

      endif

    endif

  endfor

  ## check for no remaining arguments
  if !isempty(argname)
    error("octapps_run: argument '%s' has no value", argname);
  endif
  if !isempty(argval)
    error("octapps_run: value '%s' has no argument name", argval);
  endif

  ## convert arguments to flat cell array of {"name", "value", ...} pairs
  args = {{fieldnames(args){:}; struct2cell(args){:}}{:}};

  ## if not printing output, call function and return
  if isempty(hprintfuncs)
    feval(hfunc, args{:});
    return
  endif

  ## call function and print output
  [out{1:length(hprintfuncs)}] = feval(hfunc, args{:});

  ## print output
  for i = 1:length(hprintfuncs)
    for j = 1:length(hprintfuncs{i})
      ans = out{i};

      ## Get number of output arguments of print function
      try
        nout = nargout(hprintfuncs{i}{j});
      catch
        nout = 1;
      end_try_catch
        
      ## If print function returns no arguments, just run it
      if nout == 0
        feval(hprintfuncs{i}{j}, ans);
        continue
      endif

      ## Run print function and store its output
      ans = feval(hprintfuncs{i}{j}, ans);

      ## display 'ans'
      switch typeinfo(ans)
        case "class"
          display(ans);
        otherwise
          disp(ans);
      endswitch
      
    endfor
  endfor

endfunction


## identity function
function x = print_identity(x)
endfunction

## skip printing argument
function print_skip(x)
endfunction
