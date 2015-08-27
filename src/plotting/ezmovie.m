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

function ezmovie(action, varargin)

  ## persistent movie generation state
  persistent state;

  switch action

    case "start"   ## start movie generation

      ## close any open 'avconv' pipe
      if isfield(state, "favconv")
        fclose(state.favconv);
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
                           {"width", "integer,strictpos,scalar"},
                           {"height", "integer,strictpos,scalar"},
                           {"fontsize", "integer,strictpos,scalar", 10},
                           {"linescale", "real,strictpos,scalar", 1.0},
                           {"verbose", "logical,scalar", false},
                           []);

      ## build 'avconv' command
      if state.verbose
        avconv_loglevel = "verbose";
      else
        avconv_loglevel = "quiet";
      endif
      avconv_cmd = sprintf(["%s -y -v %s -f image2pipe ", ...
                            "-codec:v mjpeg -framerate %g -i pipe: ", ...
                            "-codec:v libx264 -qscale 1 -profile:v baseline %s.mp4"], ...
                           avconv, avconv_loglevel, 1.0 / state.delay, state.filebasename);

      ## create input pipe to 'avconv', which will be fed JPEG images to create movie
      state.favconv = popen(avconv_cmd, "w");

    case "add"

      ## this action takes no options
      assert(nargin == 1, "%s: action '%s' takes no options", funcName, action);

      ## check that movie generation has been correctly started
      assert(isfield(state, "favconv"), "%s: movie generation has not been started", funcName);

      ## get temporary file name to print JPEG image to
      jpgfile = strcat(tempname, ".jpg");

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
        fwrite(state.favconv, jpg);

      unwind_protect_cleanup

        ## close and remove temporary JPEG file
        if fjpg >= 0
          fclose(fjpg);
        endif
        unlink(jpgfile);

      end_unwind_protect

    case "stop"   ## stop movie generation

      ## this action takes no options
      assert(nargin == 1, "%s: action '%s' takes no options", funcName, action);

      ## close any open 'avconv' pipe
      if isfield(state, "favconv")
        fclose(state.favconv);
        state = [];
      endif

    otherwise
      error("%s: unknown action '%s'", funcName, action);

  endswitch

endfunction
