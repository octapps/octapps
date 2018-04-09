## Copyright (C) 2012 Karl Wette
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
## @deftypefn {Function File} {@var{IDstring} =} format_gitID ( @var{ID}, @dots{} )
##
## Formats a git version information string from the git ID structs @var{ID}.
## SWIG-wrapped LAL VCSInfo structs and octapps_gitID() structs are supported.
## @end deftypefn

function IDstring = format_gitID(varargin)

  IDstring = "";
  for i = 1:length(varargin)
    ID = varargin{i};

    ## use try instead of isfield(), since SWIG-wrapped types don't support it
    try
      IDstring = strcat(IDstring, sprintf("%sAuthor: %s\n", ID.name, ID.vcsAuthor));
    catch
    end_try_catch
    try
      IDstring = strcat(IDstring, sprintf("%sBranch: %s\n", ID.name, ID.vcsBranch));
    catch
    end_try_catch
    try
      IDstring = strcat(IDstring, sprintf("%sCommitter: %s\n", ID.name, ID.vcsCommitter));
    catch
    end_try_catch
    try
      IDstring = strcat(IDstring, sprintf("%sDate: %s\n", ID.name, ID.vcsDate));
    catch
    end_try_catch
    try
      IDstring = strcat(IDstring, sprintf("%sID: %s\n", ID.name, ID.vcsId));
    catch
    end_try_catch
    try
      IDstring = strcat(IDstring, sprintf("%sStatus: %s\n", ID.name, ID.vcsStatus));
    catch
    end_try_catch
    try
      IDstring = strcat(IDstring, sprintf("%sTag: %s\n", ID.name, ID.vcsTag));
    catch
    end_try_catch
    try
      IDstring = strcat(IDstring, sprintf("%sVersion: %s\n", ID.name, ID.version));
    catch
    end_try_catch

  endfor

endfunction

%!test
%!  format_gitID(octapps_gitID());
