## Copyright (C) 2012 David Keitel
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
## @deftypefn {Function File} {} writeCommandLineToFile ( @var{filename}, @var{params}, @var{scriptname} )
##
## write an octapps_run commandline as an output file header
## 'params' should be prepared by @command{parseOptions()} before
##
## @heading Note
##
## use @code{save("-append",...)} later on to not overwrite this header
## @end deftypefn

function writeCommandLineToFile ( filename, params, scriptname )

  fid = fopen ( filename, "w" );

  fprintf ( fid, "%s\n", strftime(save_header_format_string, localtime(time())));

  fprintf ( fid, "# octapps version: %s\n", octapps_gitID().vcsId );

  fprintf ( fid, "# commandline:\n" );
  fprintf ( fid, "# octapps_run %s\n", scriptname );

  param_fieldnames = fieldnames(params);
  param_values     = struct2cell(params);

  for n=1:1:length(param_values)
    if ( length(param_values{n}) > 0 ) ## variables not set by the user which have the empty string as default will break the reconstructed commandline, ignore them here
      if ( isnumeric(param_values{n}) || islogical(param_values{n}) ) ## values converted to numeric formats by parseOptions have to be converted back
        param_values{n} = num2str(param_values{n});
      endif
      fprintf ( fid, "# --%s=%s\n", param_fieldnames{n}, param_values{n} );
    endif
  endfor

  fclose ( filename );

endfunction ## writeCommandLineToFile()

%!test
%!  args = struct;
%!  args.real_strictpos_scalar = 1.23;
%!  args.integer_vector = [-5, 3];
%!  args.string = "Hi";
%!  writeCommandLineToFile(tempname(tempdir), args, "__test_parseOptions__")
