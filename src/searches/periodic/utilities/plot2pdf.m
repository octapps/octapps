%% plot2pdf ( bname )
%% output the current figure to a pdf file named '<bname>.pdf'
%%
%% nocleanup=true: don't delete by-products at the end (used for debugging)
%% print_options = a single-option string or cell-array of option-strings to pass to the 'print()' command
%% latex_preamble: allows specifying LaTeX commands to be added before \begin{document},
%%           this can typically be used to input a LaTeX-defines file for use in the figure


%%
%% Copyright (C) 2010 Reinhard Prix
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

function plot2pdf ( bname, print_options=[], latex_preamble=[], nocleanup=false )

  curdir = pwd ();

  %% create temporary sudirectory
  tmpdir = tmpnam (".");
  [status, msg, msgid] = mkdir (tmpdir);
  if ( status != 1 )
    error ("Failed to open temporary directory '%s': error msg '%s'\n", tmpdir, msg );
  endif
  %% ... and change into it
  chdir (tmpdir );

  texname = sprintf ("%s.tex", bname);
  cmd = sprintf ("print (texname, '-depslatexstandalone'" );
  if ( ischar ( print_options ) )
    cmd = strcat ( cmd, ", '", print_options, "'" );
  elseif ( iscell( print_options ) )
    for i = 1:length(print_options)
      cmd = strcat ( cmd, ", '", print_options{i}, "'" );
    endfor
  endif
  cmd = strcat ( cmd, " );" );
  eval ( cmd );

  %% prepare a gnuplot.cfg file containing latex_preamble, if any given
  if ( !isempty ( latex_preamble )  )
    fid = fopen ("gnuplot.cfg", "wb" );
    if ( fid == -1 ) error ("Failed to open 'gnuplot.cfg' for writing.\n"); endif
    fprintf ( fid, "%s\n", latex_preamble );
    fclose ( fid );
  endif

  %% turn this tex+eps figure into a pdf endproduct
  dviname = sprintf ("%s.dvi", bname);
  pdfname = sprintf ("%s/%s.pdf", curdir, bname);
  cmdline = sprintf ("latex %s && dvipdf %s %s\n", texname, dviname, pdfname );
  [status, out] = system ( cmdline );
  if ( status != 0 )
    fprintf (stderr, "Something failed converting the final figure using: '%s'\n", cmdline );
    error ("Error output was '%s'\n", out );
  endif

  chdir(curdir);
  %% cleanup:
  if ( !nocleanup )
    cmdline = sprintf ("rm -rf %s", tmpdir );
    [status, out] = system ( cmdline );
    if ( status != 0 )
      fprintf (stderr, "Something failed trying to remove temporary directory '%s'\n", tmpdir );
      error ("Error message was '%s'\n", out );
    endif
  endif

  return;

endfunction %% plot2pdf()

