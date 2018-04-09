## Copyright (C) 2012 Karl Wette
## Copyright (C) 2008 Reinhard Prix, John T. Whelan
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
## @deftypefn {Function File} {@var{ID} =} octapps_gitID ( [ @var{directory}, [ @var{name} ] ] )
##
## Returns the git-tag (commitID, date, etc) information for the
## specified git repository containing @var{directory}. If @var{directory}
## is missing, the location of the OctApps git repository is assumed.
## @var{ID} is a struct with fields: name, vcsId, vcsDate, vcsAuthor, vcsStatus.
## @end deftypefn

function ID = octapps_gitID ( directory, name )

  ## check input
  if nargin < 2
    name = "";
  endif
  if nargin < 1
    directory = fileparts(mfilename("fullpath"));
    name = "OctApps";
  endif
  assert(ischar(directory));
  assert(ischar(name));
  if ( !exist(directory, "dir") )
    error ("%s: directory '%s' does not exist", funcName, directory );
  endif

  cdcmd = cstrcat ( "cd ", directory, " && " );

  ## ---------- read out git-log of last commit --------------------
  ## This method matches what's used in lal/lalapps, but could fall
  ## victim to a race condition.
  fmt_id = "format:%H";
  logcmd_id = sprintf( "%sgit log -1 --pretty='%s'", cdcmd, fmt_id );
  fmt_udate="format:%at";
  logcmd_udate = sprintf( "%sgit log -1 --pretty='%s'", cdcmd, fmt_udate );
  fmt_author="format:%ae";
  logcmd_author = sprintf( "%sgit log -1 --pretty='%s'", cdcmd, fmt_author );

  [ err, git_id ] = system ( logcmd_id );
  if ( err )
    error ("%s: unexpectedly failed to get git-ID, error was %d", funcName, err );
  endif
  [ err, git_udate ] = system ( logcmd_udate );
  if ( err )
    error ("%s: unexpectedly failed to get git-date, error was %d", funcName, err );
  endif
  mytime = gmtime(str2num(git_udate));
  git_date_utc = sprintf("%04d-%02d-%02d %02d:%02d:%02d UTC",
                         1900 + mytime.year, 1 + mytime.mon, mytime.mday,
                         mytime.hour, mytime.min, mytime.sec);
  [ err, git_author ] = system ( logcmd_author );
  if ( err )
    error ("%s: unexpectedly failed to get git-author, error was %d", funcName, err );
  endif

  statuscmd = sprintf( "%sgit status --porcelain --untracked-files=no", cdcmd );
  [ err, msg ] = system ( statuscmd );
  if ( err )
    error ("%s: unexpectedly failed to get git-status, error was %d", funcName, err );
  endif
  if length(strtrim(msg)) == 0
    git_status = "CLEAN";
  else
    git_status = "UNCLEAN";
  endif

  ID.name = name;
  ID.vcsId = git_id;
  ID.vcsDate = git_date_utc;
  ID.vcsAuthor = git_author;
  ID.vcsStatus = git_status;

endfunction

%!test
%!  octapps_gitID();
