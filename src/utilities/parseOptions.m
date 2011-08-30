%% Kitchen-sink options parser.
%% Syntax:
%%   paropts = parseOptions(opts, optspec, optspec)
%% where:
%%   opts    = command-line / function options
%%   optspec = option specification, one of:
%%      * required option:  {'name','types'}
%%      * optional option:  {'name','types',defvalue}
%%      where:
%%         name     = name of option variable
%%         types    = datatype specification of option:
%%                    'type,type,...'
%%         defvalue = default value given to <name>
%%   paropts = parsed command-line / function options (optional)
%% Notes:
%%   * <name> will be assigned values in the context of
%%     the calling function, unless paropts is given
%%   * each 'type' in <types> must correspond to a function
%%     'istype': each function will be called to check that
%%     a value is valid. For example, if
%%        <types> = 'numeric,scalar'
%%     then a value <x> must satisfy:
%%        isnumeric(x) && isscalar(x)
%%   * if runningAsScript == true, parseOptions assumes
%%     that opts contains command-line options from argv().
%%     Command-line options may be given either as
%%        '--name' 'value'
%%     or as
%%        '--name=value'
%%     If the <type> of <name> is 'char', and <value> does
%%     not begin with a [, it will be treated as a string;
%%     otherwise it will be treated as an Octave expression
%%     and evaluated with eval(), surrounded by []s.
%%   * otherwise, parseOptions assumes that opts contains
%%     function arguments from varargin, of the form:
%%        reg,reg,...,"key",val,"key",val,...
%%     where <reg> are regular options and <key>-<val> are
%%     keyword-value option pairs. Regular options are
%%     assigned in the order they were given as <optspec>s;
%%     regular options may also be given as keyword-values.

%%
%%  Copyright (C) 2011 Karl Wette
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%

function paropts = parseOptions(opts, varargin)

  %% check for option specifications
  if length(varargin) == 0
    error("%s: Expected option specifications in varargin", funcName);
  endif

  %% store information about options
  allowed = struct;
  required = struct;
  reqnames = {};
  typefunc = struct;
  varname = struct;

  %% parse option specifications
  for n = 1:length(varargin)
    optspec = varargin{n};

    %% basic syntax checking
    if !iscell(optspec) || !ismember(length(optspec), 2:3) || !all(cellfun("ischar", optspec(1:2)))
      error("%s: Expected option specification {'name','type'[,defvalue]} at varargin{%i}", funcName, n);
    endif

    %% store option name as an allowed option
    optname = optspec{1};
    allowed.(optname) = 1;

    %% store option type functions
    opttypes = optspec{2};
    typefuncstr = sprintf("&&is%s(x)", strtrim(strsplit(opttypes, ",", true)){:})(3:end);
    typefunc.(optname) = inline(typefuncstr, "x");
    try
      feval(typefunc.(optname), []);
    catch
      error("%s: Error parsing types specification '%s' for option", opttypes, optname);
    end_try_catch

    %% if this is an optional option
    if length(optspec) == 3

      %% assign default value, if it's the right type
      optvalue = optspec{3};
      if !(isempty(optvalue) || feval(typefunc.(optname), optvalue))
        error("%s: Default value of '%s' must be empty or satisfy: %s", funcName, optname, formula(typefunc.(optname)));
      endif
      paropts.(optname) = optvalue;

    else

      %% mark this option as being required, and store its name
      required.(optname) = 1;
      reqnames{end+1} = optname;

    endif

  endfor

  %% if running as a script
  if runningAsScript

    %% stupid Octave; if no command-line options are given to script, argv()
    %% will contain the entire Octave command-line, instead of simply the
    %% options after the script name! so we have to check for this
    if length(opts) > 0 && strcmp(opts{end}, program_invocation_name)
      opts = {};
    endif

    %% print caller's usage if --help is given
    if any(cellfun(@(x) strcmp(x, "--help"), opts))

      %% get name of calling function
      stack = dbstack();
      if numel(stack) > 1
        callername = stack(2).name;
      else
        error("No help information for %s\n", program_invocation_name);
      endif

      %% get plain help text of calling function
      [helptext, helpfmt] = get_help_text(callername);
      if !strcmp(helpfmt, "plain text")
        [helptext, helpstat] = __makeinfo__(helptext, "plain text");
        if !helpstat
          error("No plain-text help information for %s\n", program_invocation_name);
        endif
      endif

      %% remove shebang from help text
      if strncmp(helptext, "!", 1)
        i = min(strfind(helptext, "\n"));
        if isempty(i)
          error("No help information for %s\n", program_invocation_name);
        else
          helptext = helptext(i+1:end);
        endif
      endif

      %% print help text and exit
      fprintf("\n%s\n", helptext);
      error("Exiting %s after displaying help\n", program_invocation_name);

    endif

    %% parse command-line options
    n = 1;
    while n <= length(opts)
      opt = opts{n++};
      optvalstr = [];

      %% check that option begins with '--'
      if strncmp(opt, "--", 2)

        %% if option contains an '=', split into name=value,
        i = min(strfind(opt, "="));
        if !isempty(i)
          optcmdname = opt(3:i-1);
          optvalstr = opt(i+1:end);
        else
          %% otherwise just store the name
          optcmdname = opt;
        endif

      else
        error("%s: Could not parse option '%s'", funcName, opt);
      endif

      %% replace '-' with '_' to make a valid Octave variable name
      optname = strrep(optcmdname, "-", "_");

      %% check that this option is an allowed option
      if !isfield(allowed, optname)
        error("%s: Unknown option '%s'", funcName, optcmdname);
      endif

      %% if no option value string has been found yet, check next option
      if isempty(optvalstr) && n <= length(opts)
        nextopt = opts{n++};
        %% if next option isn't itself an option, use as a value string
        if !strncmp(nextopt, "--", 2)
          optvalstr = nextopt;
        endif
      endif
      if isempty(optvalstr)
        error("%s: Could to determine the value of option '%s'", funcName, optcmdname);
      endif

      %% if option accepts a 'char' and its value string doesn't begin with '['
      if feval(typefunc.(optname), "string") && !strncmp(optvalstr, "[", 1)
        %% assign directly to option value
        optvalue = optvalstr;
      else
        %% parse option value string as an Octave expression
        try
          eval(sprintf("optvalue=[%s];", optvalstr));
        catch
          error("%s: Could not create a value from '%s'", funcName, optvalstr);
        end_try_catch
      endif

      %% assign option value, if it's the right type
      if !feval(typefunc.(optname), optvalue)
        error("%s: Value of '%s' must satisfy: %s", funcName, optcmdname, formula(typefunc.(optname)));
      endif
      paropts.(optname) = optvalue;

      %% mark that this option has been used
      --allowed.(optname);
      if isfield(required, optname)
        --required.(optname);
      endif

    endwhile

  else

    %% split function arguments into regular options and keyword-value pairs
    [regopts, kvopts] = parseparams(opts);

    %% check if there's more regular options than required options
    if length(regopts) > length(reqnames)
      error("%s: Too many regular arguments; maximum is %i", funcName, length(reqnames))
    endif

    %% assign regular options in order given by 'reqnames'
    for n = 1:length(regopts)

      %% assign option value, if it's the right type
      if !feval(typefunc.(reqnames{n}), regopts{n})
        error("%s: Value of '%s' must satisfy: %s", funcName, reqnames{n}, formula(typefunc.(reqnames{n})));
      endif
      paropts.(reqnames{n}) = regopts{n};

      %% mark that this option has been used
      --allowed.(reqnames{n});
      --required.(reqnames{n});

    endfor

    %% check that there's an even number of items in the keyword-value list
    if mod(length(kvopts), 2) != 0
      error("%s: Expected 'key',value pairs following regular options in args", funcName);
    endif

    %% assign keyword-value options
    for n = 1:2:length(kvopts)

      %% check that this option is an allowed option
      if !isfield(allowed, kvopts{n})
        error("%s: Unknown option '%s'", funcName, kvopts{n});
      endif

      %% assign option value, if it's the right type
      if !feval(typefunc.(kvopts{n}), kvopts{n+1})
        error("%s: Value of '%s' must satisfy: %s", funcName, kvopts{n}, formula(typefunc.(kvopts{n})));
      endif
      paropts.(kvopts{n}) = kvopts{n+1};

      %% mark that this option has been used
      --allowed.(kvopts{n});
      if isfield(required, kvopts{n})
        --required.(kvopts{n});
      endif

    endfor

  endif

  %% check that options have been used correctly
  allnames = fieldnames(allowed);
  for n = 1:length(allnames)

    %% if allowed < 0, option have been used more than once
    if allowed.(allnames{n}) < 0
      error("%s: Option '%s' used multiple times", funcName, allnames{n});
    endif

    if isfield(required, allnames{n})

      %% if required > 0, required option have been used at all
      if required.(allnames{n}) > 0
        error("%s: Missing required option '%s'", funcName, allnames{n});
      endif

      %% if required < 0, option have been used more than once
      if required.(allnames{n}) < 0
        error("%s: Option '%s' used multiple times", funcName, allnames{n});
      endif

    endif

  endfor

  %% assign values to option variables in caller namespace
  if nargout == 0
    paroptnames = fieldnames(paropts);
    for n = 1:length(paroptnames)
      assignin("caller", paroptnames{n}, paropts.(paroptnames{n}));
    endfor
  endif

endfunction
