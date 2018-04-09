## Copyright (C) 2012 Karl Wette
## Copyright (C) 2010 Reinhard Prix
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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} runCode ( @var{params}, @var{code}, [ @var{verbose} = false ] )
## @deftypefnx{Function File} {@var{output} =} runCode ( @dots{} )
##
## Generic code-running driver: run @var{code}, passing any command-line
## options in the struct @var{params}, which are passed to @var{code}
## in ---name=val format. Use @var{params}.LAL_DEBUG_LEVEL to set the LAL
## debug level. If @var{verbose} is true, print command before running it.
## @end deftypefn

function output = runCode(params, code, verbose=false)

  ## check input
  if ( !exist("params" ) )
    error("%s: missing function argument 'params'", funcName);
  endif
  if ( !exist("code") )
    error("%s: missing function argument 'code'", funcName);
  endif

  ## set LAL debug level to 1 by default
  if ( !isfield(params, "LAL_DEBUG_LEVEL") )
    params.LAL_DEBUG_LEVEL = 1;
  endif

  ## build command line and environment
  env = "";
  cmdline = code;
  option_names = fieldnames ( params );
  for i = 1:length(option_names)
    option = option_names{i};

    val = getfield ( params, option );

    if ( ischar ( val ) )
      valstr = sprintf ("'%s'", val );
    elseif ( isreal (val) && isvector(val) )
      tmp = sprintf ("%.16g,", val );
      valstr = tmp(1:end-1);    ## remove trailing ','
    elseif ( islogical ( val ) )
      valstr = sprintf ("%d", val );
    else
      error ("%s: Field '%s' is neither a string, bool or real vector!\n", funcName, option );
    endif

    if strcmp( option, "LAL_DEBUG_LEVEL" )
      env = sprintf( "export LAL_DEBUG_LEVEL='%s'; ", valstr );
    elseif length(option) == 1
      cmdline = cstrcat ( cmdline, " -", option, " ", valstr ); ## need cstrcat() here because in recent octave versions (>3.6?), strcat trims whitespaces
    else
      cmdline = strcat ( cmdline, " --", option, "=", valstr );
    endif

  endfor
  cmdline = cstrcat(env, cmdline);

  ## run command
  unmanglePATH;
  if ( verbose )
    fprintf ( stdout, "%s: executing >>> %s <<<\n", funcName, cmdline );
    fflush ( stdout );
  endif
  if nargout > 0
    [status, output] = system(cmdline);
  else
    status = system(cmdline);
  endif
  if ( status != 0 )
    error ("%s: %s failed with exit status %i. Commandline was:\n%s", funcName, code, status, cmdline);
  elseif ( verbose )
    fprintf ( stdout, "%s: %s completed successfully!\n", funcName, code );
    fflush ( stdout );
  endif

endfunction

%!test
%!  runCode(struct("c", 'echo "This is a test of runCode()"'), "/bin/sh");
