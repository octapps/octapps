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
##   octapps_run <function> ... --help
##     Print help message for Octapps function <function>
##
##   octapps_run <function> [--argument <value>] [--argument=<value>]...
##     Run the Octapps function <function> with the given arguments.
##     (The function itself must use parseOptions() to parse its arguments.)
##
##   octapps_run <function> ... --printnargs=<n>
##     Print the values of the first <n> output values of <function>.
##
##   octapps_run <function> ... --printarg<n>
##     Print the value of the <n>th output value of <function>.
##     <n> default to 1 if not given.
##
##   octapps_run <function> ... --printarg<n>=<print-function>
##   octapps_run <function> ... --printarg<n>=<print-function(<args>, ...)
##     Print the value of the function <print-function> applied to the <n>th output
##     value of <function>.
##
##   See the following examples, which assume the functions
##       a = f(), [a, b] = g()
##
##     Command                                                      Outputs printed
##     -------                                                      ---------------
##     octapps_run f --printnarg=1                                  a
##     octapps_run f --printarg                                     a
##     octapps_run f --printarg1                                    a
##     octapps_run f --printarg=mean                                mean(a)
##     octapps_run f --printarg=mean --printarg=stdv                mean(a), stdv(a)
##
##     octapps_run g --printnargs=2                                 a, b
##     octapps_run g --printarg --printarg1=sin --printarg2=cos     a, mean(a), cos(b)
##     octapps_run g --printarg2=mod(?,3)                           mod(b,3)

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

  ## pick out command-line arguments
  nn = [find(strncmp(varargin, "--", 2)), length(varargin) + 1];

  ## parse arguments and values
  hprintfuncs = {};
  args = struct;
  for n = 1:length(nn) - 1

    ## get argument name (possibly with value) and values
    argnameval = varargin{nn(n)}(3:end);
    argval = varargin((nn(n)+1):(nn(n+1)-1));

    ## if argument contains an '='
    i = min(strfind(argnameval, "="));
    if !isempty(i)

      ## extract name
      argname = argnameval(1:i-1);

      ## assert there are no other values
      assert(isempty(argval), "octapps_run: extra arguments given to argument --%s", argname);

      ## extract value
      argval = {argnameval(i+1:end)};

    else

      ## just store the name
      argname = argnameval;

    endif

    ## replace '-' with '_' to make a valid Octave variable name
    argname = strrep(argname, "-", "_");

    if strcmp(argname, "printnargs")   ## handle special argument --printnargs=<n>

      ## check number of values
      assert(length(argval) == 1, "octapps_run: multiple values passed to argument --%s", argname);

      ## parse number of arguments
      narg = str2double(argval);
      assert(!isnan(narg) && narg > 0 && mod(narg, 1) == 0, "octapps_run: number of arguments '%s' passed to --%s must be a positive integer", argval, argname);

      ## print this number of arguments
      [hprintfuncs{1:narg}] = deal({struct("func", @print_identity, "nout", 1)});

    elseif strncmp(argname, "printarg", length("printarg"))   ## handle special argument --printarg[<n>]=<print function>

      ## check number of values
      assert(length(argval) <= 1, "octapps_run: multiple values passed to argument --%s", argname);

      ## extract and parse argument number
      argnum = argname(length("printarg")+1:end);
      if isempty(argnum)
        narg = 1;
      else
        narg = str2double(argnum);
        assert(!isnan(narg) && narg > 0 && mod(narg, 1) == 0, "octapps_run: argument number '%s' in --%s must be a positive integer", argnum, argname);
      endif

      ## resize 'hprintfuncs' if needed
      if narg > length(hprintfuncs)
        hprintfuncs{narg} = {};
      endif

      if length(argval) == 1   ## handle --printarg[<n>]=<print function>
        argval = argval{1};

        ## handle function with argument list
        i = min(strfind(argval, "("));
        if !isempty(i)
          printfuncname = argval(1:i-1);
          printfuncargs = strrep(argval(i:end), "?", "__x__");
        else
          printfuncname = argval;
          printfuncargs = "(__x__)";
        endif

        ## test if function exists
        try
          str2func(printfuncname);
        catch
          error("octapps_run: %s() is not a known function", argval);
        end_try_catch

        ## get number of function output arguments
        try
          nout = nargout(printfuncname);
        catch
          nout = 1;
        end_try_catch

        ## create print function
        hprintfuncs{narg}{end+1} = struct("func", inline(strcat(printfuncname, printfuncargs), "__x__"), "nout", nout);

      else   ## handle --printarg[<n>]

        ## print the given argument
        hprintfuncs{narg} = {struct("func", @print_identity, "nout", 1)};

      endif

    else  ## handle ordinary arguments

      ## make value into scalar if it only has one element
      if length(argval) == 1
        argval = argval{1};
      endif

      ## store value
      args.(argname) = argval;

    endif

  endfor

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
      hp = hprintfuncs{i}{j};

      ## if print function returns no arguments, just run it
      if hp.nout == 0
        feval(hp.func, out{i});
        continue
      endif

      ## run print function and store its output
      ans = feval(hp.func, out{i});

      ## display 'ans'
      if strcmp(typeinfo(ans), "class")
        display(ans);
      else
        disp(ans);
      endif

    endfor
  endfor

endfunction


## identity function
function x = print_identity(x)
endfunction

## skip printing argument
function print_skip(x)
endfunction
