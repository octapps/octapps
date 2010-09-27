%% plot2pdf ( handle, bname )
%% output a figure with given handle to a pdf plot named '<bname>.pdf'

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

function plot2pdf ( handle, bname )

  %% check input
  if ( ! isfigure ( handle ) )
    error ("Input handle must be a figure! Use gcf() to obtain figure handles.\n");
  endif

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
  print (handle, texname, "-depslatexstandalone" );

  %% turn this tex+eps figure into a pdf endproduct
  dviname = sprintf ("%s.dvi", bname);
  pdfname = sprintf ("%s/%s.pdf", curdir, bname);
  cmdline = sprintf ("latex %s && dvipdf %s %s\n", texname, dviname, pdfname );
  [status, out] = system ( cmdline );
  if ( status != 0 )
    fprintf (stderr, "Something failed converting the final figure using: '%s'\n", cmdline );
    error ("Error output was '%s'\n", out );
  endif

  %% cleanup:
  chdir(curdir);
  cmdline = sprintf ("rm -rf %s", tmpdir );
  [status, out] = system ( cmdline );
  if ( status != 0 )
    fprintf (stderr, "Something failed trying to remove temporary directory '%s'\n", tmpdir );
    error ("Error message was '%s'\n", out );
  endif

  return;

endfunction %% plot2pdf()

