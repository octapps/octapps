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

## -*- texinfo -*-
## @deftypefn {Function File} {} parseOptions ( @var{opts}, @var{optspec}, @var{optspec}, @dots{} )
## @deftypefnx{Function File} {@var{paropts} =} parseOptions ( @dots{} )
## @deftypefnx{Function File} { [ @bullet{}, @var{paropts} ] =} parseOptions ( @dots{} )
##
## Kitchen-sink options parser.
##
## @heading Arguments
##
## @table @var
## @item opts
## function options
##
## @item optspec
## option specification, one of:
##
## @table @asis
## @item required option
## @{@var{name}, @var{types}@}
## @item optional option
## @{@var{name}, @var{types}, @var{defvalue}@}
## @end table
##
## where:
##
## @table @var
## @item name
## name of option variable
## @item types
## datatype specification of option:
## 'type,type,@dots{}'
## @item defvalue
## default value given to <name>
## @end table
##
## @item paropts
## struct of parsed function options (optional)
##
## @end table
##
## @heading Notes
##
## @itemize
## @item
## using the 1st or 3rd syntax, @var{name} will be assigned in the context of
## the calling function; using the 2nd or 3rd syntax, @var{name} will be
## assigned in the return struct.
##
## @item
## each @code{type} in @var{types} must correspond to a function
## @command{istype()}: each function will be called to check that a value is
## valid. For example, if @var{types} = 'numeric,scalar' then a value @var{x}
## must satisfy @code{isnumeric(x) && isscalar(x)}
##
## @item
## @var{opts} should contain options of the form
## @verbatim
##   reg, reg, ..., "key", val, "key", val, ...
## @end verbatim
## where @var{reg} are regular options, and @var{key} and @var{val} are
## keyword-value option pairs. Regular options are assigned in the order they
## were given as @var{optspec}s; regular options may also be given as
## keyword-values.
##
## @end itemize
##
## @end deftypefn

function varargout = parseOptions(opts, varargin)

  ## check number of output arguments
  nargoutchk(0, 2);

  ## check for option specifications
  if length(varargin) == 0
    error("%s: expected option specifications in varargin", funcName);
  endif

  ## store information about options
  optchars = struct;
  allowed = struct;
  required = struct;
  reqnames = {};
  typefunc = struct;
  convfunc = struct;
  noargvalue = struct;
  atleastone = {};
  exactlyone = {};
  atmostone = {};
  noneorall = {};

  ## parse option specifications
  for n = 1:length(varargin)
    optspec = varargin{n};

    ## allow [] as part of option specifications, e.g. as a spacer
    if !iscell(optspec) && !ischar(optspec) && isempty(optspec)
      continue;
    endif

    ## basic syntax checking
    if !iscell(optspec) || !ismember(length(optspec), 2:3) || !all(cellfun("ischar", optspec(1:2)))
      error("%s: expected option specification {'name','type'[,defvalue]} at varargin{%i}", funcName, n);
    endif
    optname = optspec{1};

    ## handle short option characters
    ii = find(optname == "|");
    if length(ii) > 0
      if length(ii) > 1 || ii != length(optname) - 1
        error("%s: invalid short option character specification in option name '%s'", funcName, optname);
      endif
      c = optname(ii+1);
      optname = optname(1:ii-1);
      if isfield(allowed, c)
        error("%s: short option character '%s' is also a long option", funcName, c);
      endif
      optchars.(c) = optname;
    endif

    ## store option name as an allowed option
    allowed.(optname) = 1;

    ## store option specifications
    typefuncstr = "( ";
    convfuncptr = [];
    noargval = [];
    opttypes = strtrim(strsplit(optspec{2}, ",", true));
    for i = 1:length(opttypes)

      ## prescription of which options are mutually exclusive/required
      if opttypes{i}(1) == "+"
        j = index(opttypes{i}, ":");
        mutualtype = opttypes{i}(2:j-1);
        mutualoptname = opttypes{i}(j+1:end);
        switch mutualtype
          case "atleastone"
            atleastone{end+1} = {optname, mutualoptname};
          case "exactlyone"
            exactlyone{end+1} = {optname, mutualoptname};
          case "atmostone"
            atmostone{end+1} = {optname, mutualoptname};
          case "noneorall"
            noneorall{end+1} = {optname, mutualoptname};
          otherwise
            error("%s: unknown mutual prescription type '%s'", funcName, mutualtype);
        endswitch
        continue
      endif

      ## type specification/conversion functions with an argument
      if !strcmp(typefuncstr, "( ")
        typefuncstr = cstrcat(typefuncstr, " ) && ( ");
      endif
      j = index(opttypes{i}, ":");
      typefunccmd = opttypes{i}(1:j-1);
      typefuncarg = opttypes{i}(j+1:end);
      if !isempty(typefunccmd)
        switch typefunccmd
          case "a"
            typefuncstr = cstrcat(typefuncstr, "isa(x,\"", typefuncarg, "\")");
          case "acell"
            typefuncstr = cstrcat(typefuncstr, "isa(x,\"", typefuncarg, "\") || (iscell(x) && cellfun(@isa,x,{\"", typefuncarg, "\"}))");
          case "size"
            x = str2double(typefuncarg);
            if !isvector(x) || any(mod(x,1) != 0) || any(x < 0)
              error("%s: argument to type specification command '%s' is not an integer vector", funcName, typefunccmd);
            endif
            typefuncstr = cstrcat(typefuncstr, "all(size(x)==[", typefuncarg, "])");
          case "numel"
            x = str2double(typefuncarg);
            if !isscalar(x) || mod(x,1) != 0 || x < 0
              error("%s: argument to type specification command '%s' is not an integer scalar", funcName, typefunccmd);
            endif
            typefuncstr = cstrcat(typefuncstr, "numel(x)==[", typefuncarg, "]");
          case "rows"
            x = str2double(typefuncarg);
            if !isscalar(x) || mod(x,1) != 0 || x < 0
              error("%s: argument to type specification command '%s' is not an integer scalar", funcName, typefunccmd);
            endif
            typefuncstr = cstrcat(typefuncstr, "rows(x)==[", typefuncarg, "]");
          case "cols"
            x = str2double(typefuncarg);
            if !isscalar(x) || mod(x,1) != 0 || x < 0
              error("%s: argument to type specification command '%s' is not an integer scalar", funcName, typefunccmd);
            endif
            typefuncstr = cstrcat(typefuncstr, "columns(x)==[", typefuncarg, "]");
          otherwise
            error("%s: unknown type specification command '%s'", funcName, typefunccmd);
        endswitch
        continue
      endif

      ## type specification/conversion functions without an argument
      switch typefuncarg
        case { "bool", "logical" }   ## also accept numeric values 0, 1 as logical values
          typefuncstr = cstrcat(typefuncstr, "islogical(x) || ( isnumeric(x) && all((x==0)|(x==1)) )");
          convfuncptr = @logical;
          noargval = true;
        case "cell"   ## override here because 'cell' is not a type conversion function
          typefuncstr = cstrcat(typefuncstr, "iscell(x)");
        case "function"
          typefuncstr = cstrcat(typefuncstr, "is_function_handle(x)");
        case "complex"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x)");
          convfuncptr = @complex;
        case "real"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && isreal(x)");
          convfuncptr = @double;
        case "integer"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(mod(x,1)==0)");
          convfuncptr = @round;
        case "evenint"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(mod(x,2)==0)");
          convfuncptr = @round;
        case "oddint"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(mod(x,2)==1)");
          convfuncptr = @round;
        case "nonzero"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(x!=0)");
        case "positive"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(x>=0)");
        case "negative"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(x<=0)");
        case "strictpos"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(x>0)");
        case "strictneg"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(x<0)");
        case "unit"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(0<=x) && all(x<=1)");
        case "strictunit"
          typefuncstr = cstrcat(typefuncstr, "isnumeric(x) && all(0<x) && all(x<1)");
        otherwise
          typefuncfunc = cstrcat("is", typefuncarg);
          try
            str2func(typefuncfunc);
            typefuncstr = cstrcat(typefuncstr, typefuncfunc, "(x)");
          catch
            error("%s: unknown type specification function '%s'", funcName, typefuncfunc);
          end_try_catch
          if isempty(convfuncptr)
            try
              convfuncptr = str2func(typefuncarg);
              feval(convfunc.(optname), []);
            catch
              convfuncptr = [];
            end_try_catch
          endif
      endswitch

    endfor

    ## check type conversion string is valid
    typefuncstr = cstrcat(typefuncstr, " )");
    typefunc.(optname) = inline(typefuncstr, "x");
    convfunc.(optname) = convfuncptr;
    noargvalue.(optname) = noargval;
    try
      feval(typefunc.(optname), []);
    catch
      error("%s: invalid type specification %s for option '%s'", funcName, optspec{2}, optname);
    end_try_catch

    ## if this is an optional option
    if length(optspec) == 3

      ## assign default value, if it's the right type
      optvalue = optspec{3};
      if !(isempty(optvalue) || feval(typefunc.(optname), optvalue))
        error("%s: default value of '%s' must be empty or satisfy %s", funcName, optname, formula(typefunc.(optname)));
      endif
      paropts.(optname) = optvalue;

    else

      ## mark this option as being required, and store its name
      required.(optname) = 1;
      reqnames{end+1} = optname;

    endif

  endfor

  ## list of allowed options
  allowed_names = fieldnames(allowed);

  ## split function arguments into regular options and keyword-value pairs
  [regopts, kvopts] = parseparams(opts);

  ## check if there's more regular options than required options
  if length(regopts) > length(reqnames)
    error("%s: too many regular arguments, maximum is %i", funcName, length(reqnames))
  endif

  ## assign regular options in order given by 'reqnames'
  for n = 1:length(regopts)

    ## assign option value, if it's the right type
    if !feval(typefunc.(reqnames{n}), regopts{n})
      error("%s: value of '%s' must satisfy %s", funcName, reqnames{n}, formula(typefunc.(reqnames{n})));
    endif
    paropts.(reqnames{n}) = regopts{n};

    ## mark that this option has been used
    --allowed.(reqnames{n});
    --required.(reqnames{n});

  endfor

  ## check that there's an even number of items in the keyword-value list
  if mod(length(kvopts), 2) != 0
    error("%s: expected 'key',value pairs following regular options in args", funcName);
  endif

  ## assign keyword-value options
  for n = 1:2:length(kvopts)
    optkey = kvopts{n};
    optval = kvopts{n+1};

    ## check that this option is an allowed option
    if length(optkey) == 1 && isfield(optchars, optkey)
      optkey = optchars.(optkey);
    else
      ii = find(cellfun(@(a_n) strcmp(optkey, a_n), allowed_names));
      if length(ii) != 1
        ii = find(cellfun(@(a_n) strncmp(optkey, a_n, min(length(a_n), max(length(optkey), 2))), allowed_names));
        if length(ii) < 1
          error("%s: unknown option '%s'", funcName, optkey);
        endif
        if length(ii) > 1
          error("%s: ambiguous option '%s' (matches '%s')", funcName, optkey, strjoin(allowed_names(ii), "' or '"));
        endif
      endif
      optkey = allowed_names{ii};
    endif

    ## if option does not accept a 'char' value, but option value is a 'char',
    ## try evaluating it (this is used when parsing arguments from the command line)
    if !feval(typefunc.(optkey), "string") && ischar(optval) && !isobject(optval)
      try
        ## convert string expression to number, but evaluate it inside a
        ## temporary function so that it cannot access local variables
        eval(sprintf("function x = __tmp__; x = [%s]; endfunction; optval = __tmp__(); clear __tmp__;", optval));
      catch
        error("%s: could not create a value from '--%s=%s'", funcName, optkey, optval);
      end_try_catch
    endif

    ## special value to indicate argument with no value
    if isequal(optval, {{}})
      if isempty(noargvalue.(optkey))
        error("%s: option '%s' requires an argument", funcName, optkey);
      endif
      paropts.(optkey) = noargvalue.(optkey);
    else

      ## assign option value, if it's the right type
      if !feval(typefunc.(optkey), optval)

        ## if option value is empty, use default (i.e. do nothing), otherwise raise error
        if iscell(optval) || ischar(optval) || !isempty(optval)
          error("%s: value of '%s' must satisfy %s", funcName, optkey, formula(typefunc.(optkey)));
        endif

      else
        paropts.(optkey) = optval;
      endif

    endif

    ## mark that this option has been used
    --allowed.(optkey);
    if isfield(required, optkey)
      --required.(optkey);
    endif

  endfor

  ## check that options have been used correctly
  allnames = fieldnames(allowed);
  for n = 1:length(allnames)

    ## if allowed < 0, option have been used more than once
    if allowed.(allnames{n}) < 0
      error("%s: option '%s' used multiple times", funcName, allnames{n});
    endif

    if isfield(required, allnames{n})

      ## if required > 0, required option have been used at all
      if required.(allnames{n}) > 0
        error("%s: missing required option '%s'", funcName, allnames{n});
      endif

      ## if required < 0, option have been used more than once
      if required.(allnames{n}) < 0
        error("%s: option '%s' used multiple times", funcName, allnames{n});
      endif

    endif

  endfor

  ## check for mutually exclusive/required options
  for n = 1:length(atleastone)
    optsset = cellfun(@(name) allowed.(name) == 0, atleastone{n});
    if sum(optsset) < 1
      error("%s: at least one of options '%s' are required", funcName, strjoin(atleastone{n}, "', '"));
    endif
  endfor
  for n = 1:length(exactlyone)
    optsset = cellfun(@(name) allowed.(name) == 0, exactlyone{n});
    if sum(optsset) != 1
      error("%s: exactly one of options '%s' are required", funcName, strjoin(exactlyone{n}, "', '"));
    endif
  endfor
  for n = 1:length(atmostone)
    optsset = cellfun(@(name) allowed.(name) == 0, atmostone{n});
    if sum(optsset) > 1
      error("%s: at most one of options '%s' are required", funcName, strjoin(atmostone{n}, "', '"));
    endif
  endfor
  for n = 1:length(noneorall)
    optsset = cellfun(@(name) allowed.(name) == 0, noneorall{n});
    if any(optsset) && !all(optsset)
      error("%s: either none or all of options '%s' are required", funcName, strjoin(noneorall{n}, "', '"));
    endif
  endfor

  ## convert all option variables to the required type
  paroptnames = fieldnames(paropts);
  for n = 1:length(paroptnames)
    convfuncptr = convfunc.(paroptnames{n});
    if !isempty(convfuncptr)
      try
        paropts.(paroptnames{n}) = feval(convfuncptr, paropts.(paroptnames{n}));
      catch
        error("%s: could not convert evaluate %s(value of option '%s')", funcName, func2str(convfuncptr), paroptnames{n});
      end_try_catch
    endif
  endfor

  ## return options struct, and/or assign to option variables in caller namespace
  if nargout == 1
    varargout = {paropts};
  elseif nargout == 2
    varargout = {[], paropts};
  endif
  if nargout != 1
    for n = 1:length(paroptnames)
      assignin("caller", paroptnames{n}, paropts.(paroptnames{n}));
    endfor
  endif

endfunction

%!assert(__test_parseOptions__("real_strictpos_scalar", 2.34, "integer_vector", [9,-1], "string", "Over there", "cell", {1;3}), 'struct("cell",{{1;3}},"twobytwo",{[1 0;0 1]},"real_strictpos_scalar",{2.34},"integer_vector",{[9 -1]},"string",{"Over there"})')
%!assert(__test_parseOptions__("real_strictpos_scalar", 2.34, "integer_vector", [9,-1], "string", "Over there", "twobytwo", [1,2;3,4]), 'struct("cell",{{1;1;1}},"twobytwo",{[1 2;3 4]},"real_strictpos_scalar",{2.34},"integer_vector",{[9 -1]},"string",{"Over there"})')
%!fail('__test_parseOptions__("real_strictpos_scalar", 2.34, "integer_vector", [9,-1], "string", "Over there", "cell", {NA,NA}, "twobytwo", zeros(2))', "parseOptions: exactly one of options 'twobytwo', 'cell' are required")

%!test
%!  status = system("octapps_run __test_parseOptions__ --help");
%!  assert(status == 1);
%!test
%!  [status, output] = system("octapps_run __test_parseOptions__ --real-strictpos-scalar 1.23 --integer-vector='[3,9,5]' --string 'Hi there' --cell '{1,{2,3}}'");
%!  assert(status == 0);
%!  assert(strtrim(output), 'struct("cell",{{1,{2,3}}},"twobytwo",{[1 0;0 1]},"real_strictpos_scalar",{1.23},"integer_vector",{[3 9 5]},"string",{"Hi there"})')
