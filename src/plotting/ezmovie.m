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

## Generate a H.264/MPEG-4 AVC movie from a sequence of figures.
## Requires the command 'avconv' from Libav to be available.
## Usage:
##   ezmovie("start", "opt", val, ...);
##   plot(...);
##   ezmovie add;
##   plot(...);
##   ezmovie add;
##   ...
##   ezmovie stop;
## Options to 'ezmovie start':
##   "filebasename": basename of movie file; extension will be ".mp4"
##   "delay":        delay between each figure, in seconds
##   "width":        width of movie, in pixels
##   "height":       height of movie, in pixels
##   "fontsize":     font size of printed figure, in points (default: 10)
##   "linescale":    factor to scale line width of figure objects (default: 1)
##   "verbose":      if true, print verbose output from 'avconv'

function ezmovie(action, varargin)

  ## persistent movie generation state
  persistent state;

  switch action

    case "start"   ## start movie generation

      ## close any open 'avconv' pipe
      if isfield(state, "avconv_pid")
        kill(state.avconv_pid, SIG.INT);
        fclose(state.avconv_fin);
        state = [];
      endif

      ## check if command 'avconv' from Libav is installed
      avconv = file_in_path(EXEC_PATH, "avconv");
      if isempty(avconv)
        error("%s: requires 'avconv' to be installed", funcName);
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

      ## build 'avconv' command
      if state.verbose
        avconv_loglevel = "verbose";
      else
        avconv_loglevel = "error";
      endif
      avconv_args = { ...
                      "-y", "-v", avconv_loglevel, ...
                      "-f", "image2pipe", ...
                      "-codec:v", "mjpeg", "-framerate", num2str(1.0 / state.delay), "-i", "pipe:", ...
                      "-codec:v", "libx264", "-qscale", "1", "-profile:v", "baseline", ...
                      strcat(state.filebasename, ".mp4") ...
                    };
      state.avconv_cmd = strcat(avconv, sprintf(" %s", avconv_args{:}));

      ## create input pipe to 'avconv', which will be fed JPEG images to create movie
      [state.avconv_fin, avconv_fout, state.avconv_pid] = popen2(avconv, avconv_args);
      fclose(avconv_fout);

    case "add"

      ## this action takes no options
      assert(nargin == 1, "%s: action '%s' takes no options", funcName, action);

      ## check that movie generation has been correctly started
      assert(isfield(state, "avconv_pid"), "%s: movie generation has not been started", funcName);

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

        ## write JPEG image to 'avconv' pipe
        fwrite(state.avconv_fin, jpg);
        fflush(state.avconv_fin);

      unwind_protect_cleanup

        ## close and remove temporary JPEG file
        if fjpg >= 0
          fclose(fjpg);
        endif
        unlink(jpgfile);

      end_unwind_protect

      ## check that 'avconv' has not encountered errors
      assert(waitpid(state.avconv_pid, WNOHANG) == 0, "%s: '%s' has failed!", funcName, state.avconv_cmd);

    case "stop"   ## stop movie generation

      ## this action takes no options
      assert(nargin == 1, "%s: action '%s' takes no options", funcName, action);

      ## close any open 'avconv' pipe
      if isfield(state, "avconv_pid")
        fclose(state.avconv_fin);
        waitpid(state.avconv_pid);
        state = [];
      endif

    otherwise
      error("%s: unknown action '%s'", funcName, action);

  endswitch

endfunction

%!test
%!  if isempty(file_in_path(EXEC_PATH, "avconv"))
%!    disp("skipping test: 'avconv' program not available"); return;
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
