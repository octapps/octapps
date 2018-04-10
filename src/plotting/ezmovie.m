## Copyright (C) 2015 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} ezmovie ( @code{start}, @var{opt}, @var{val}, @dots{} ) ;
## @deftypefnx{Function File} {} ezmovie ( @code{add} ) ;
## @deftypefnx{Function File} {} ezmovie ( @code{stop} ) ;
##
## Generate a H.264/MPEG-4 AVC movie from a sequence of figures.
## Requires the command @code{ffmpeg} or @code{avconv} to be available.
##
## @heading Options to ezmovie(@code{start})
##
## @table @var
## @item filebasename
## basename of movie file; extension will be ".mp4"
##
## @item delay
## @var{delay} between each figure, in seconds
##
## @item width
## @var{width} of movie, in pixels
##
## @item height
## @var{height} of movie, in pixels
##
## @item fontsize
## font size of printed figure, in points (default: 10)
##
## @item linescale
## factor to scale line @var{width} of figure objects (default: 1)
##
## @item verbose
## if true, print @var{verbose} output from @code{ffmpeg} or @code{avconv}
##
## @end table
##
## @heading Example
## @verbatim
## ezmovie("start", "opt", val, ...);
## plot(...);
## ezmovie add;
## plot(...);
## ezmovie add;
## @end verbatim
##
## @end deftypefn

function ezmovie(action, varargin)

  ## persistent movie generation state
  persistent state;

  switch action

    case "start"   ## start movie generation

      ## close any open 'ffmpeg'/'avconv' pipe
      if isfield(state, "ffmpeg_pid")
        kill(state.ffmpeg_pid, SIG.INT);
        fclose(state.ffmpeg_fin);
        state = [];
      endif

      ## check if command 'ffmpeg'/'avconv' is installed
      ffmpeg = file_in_path(getenv("PATH"), "ffmpeg");
      if isempty(ffmpeg)
        ffmpeg = file_in_path(getenv("PATH"), "avconv");
        if isempty(ffmpeg)
          error("%s: requires either 'ffmpeg' or 'avconv' to be installed", funcName);
        endif
      endif

      ## parse options
      state = parseOptions(varargin,
                           {"filebasename", "char"},
                           {"delay", "real,strictpos,scalar"},
                           {"width", "evenint,strictpos,scalar"},
                           {"height", "evenint,strictpos,scalar"},
                           {"fontsize", "integer,strictpos,scalar", 10},
                           {"linescale", "real,strictpos,scalar", 1.0},
                           {"verbose", "logical,scalar", false},
                           []);

      ## build 'ffmpeg'/'avconv' command
      if state.verbose
        ffmpeg_loglevel = "verbose";
      else
        ffmpeg_loglevel = "error";
      endif
      ffmpeg_args = { ...
                      "-y", "-v", ffmpeg_loglevel, ...
                      "-f", "image2pipe", ...
                      "-codec:v", "mjpeg", "-framerate", num2str(1.0 / state.delay), "-i", "pipe:", ...
                      "-codec:v", "libx264", "-qscale", "1", "-profile:v", "baseline", ...
                      strcat(state.filebasename, ".mp4") ...
                    };
      state.ffmpeg_cmd = strcat(ffmpeg, sprintf(" %s", ffmpeg_args{:}));

      ## create input pipe to 'ffmpeg'/'avconv', which will be fed JPEG images to create movie
      [state.ffmpeg_fin, ffmpeg_fout, state.ffmpeg_pid] = popen2(ffmpeg, ffmpeg_args);
      fclose(ffmpeg_fout);

    case "add"

      ## this action takes no options
      assert(nargin == 1, "%s: action '%s' takes no options", funcName, action);

      ## check that movie generation has been correctly started
      assert(isfield(state, "ffmpeg_pid"), "%s: movie generation has not been started", funcName);

      ## get temporary file name to print JPEG image to
      jpgfile = strcat(tempname(tempdir), ".jpg");

      ## ensure temporary JPEG files get deleted on error
      fjpg = -1;
      unwind_protect

        ## print current figure to temporary JPEG file
        ezprint(jpgfile, ...
                "width", state.width, "height", state.height, "dpi", 72, ...
                "fontsize", state.fontsize, "linescale", state.linescale);

        ## read JPEG image from file into memory
        [fjpg, err_msg] = fopen(jpgfile, "r");
        assert(fjpg >= 0, "%s: could not open temporary JPEG file: %s", err_msg);
        jpg = fread(fjpg);

        ## write JPEG image to 'ffmpeg'/'avconv' pipe
        fwrite(state.ffmpeg_fin, jpg);
        fflush(state.ffmpeg_fin);

      unwind_protect_cleanup

        ## close and remove temporary JPEG file
        if fjpg >= 0
          fclose(fjpg);
        endif
        unlink(jpgfile);

      end_unwind_protect

      ## check that 'ffmpeg'/'avconv' has not encountered errors
      assert(waitpid(state.ffmpeg_pid, WNOHANG) == 0, "%s: '%s' has failed!", funcName, state.ffmpeg_cmd);

    case "stop"   ## stop movie generation

      ## this action takes no options
      assert(nargin == 1, "%s: action '%s' takes no options", funcName, action);

      ## close any open 'ffmpeg'/'avconv' pipe
      if isfield(state, "ffmpeg_pid")
        fclose(state.ffmpeg_fin);
        waitpid(state.ffmpeg_pid);
        state = [];
      endif

    otherwise
      error("%s: unknown action '%s'", funcName, action);

  endswitch

endfunction

%!test
%!  if isempty(file_in_path(getenv("PATH"), "ffmpeg")) && isempty(file_in_path(getenv("PATH"), "avconv"))
%!    disp("skipping test: neither 'ffmpeg' or 'avconv' proograms are available"); return;
%!  endif
%!  graphics_toolkit gnuplot;
%!  movbname = tempname(tempdir);
%!  ezmovie("start", "filebasename", movbname, "delay", 0.01, "width", 100, "height", 100);
%!  fig = figure("visible", "off");
%!  for i = 1:10
%!    plot(0:100, mod(i + (0:100), 10));
%!    ezmovie add;
%!  endfor
%!  ezmovie stop;
%!  close(fig);
%!  assert(exist(strcat(movbname, ".mp4"), "file"));
