%% ret = octapps_gitID( directory, prefix )
%%
%% Return the git-tag (commitID, date, etc) information for the
%% specified git repository containing directory.  If the directory is
%% omitted, it defaults to octapps itself
%%
%% For backwards compatiblility, if prefix is omitted,
%%
%% ret = octapps_gitID( run_local )
%%
%% is equivalent to
%%
%% octapps_gitID( ".", "" )
%%
%% if run_local == true and
%%
%% octapps_gitID( false, "octapps" )
%%
%% if run_local == false
%%
%% returns struct with fields {fullID, commitID, commitDate, commitAuthor, commitTitle, gitStatus}
%% where 'fullID' is a nicely-formatted concatenation of the individual fields
%%

%% Copyright (C) 2008 Reinhard Prix, John Whelan
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

function ret = octapps_gitID ( directory, prefix )

  if ( !exist("directory") || !directory ) # run on octapps
    orig = which("octapps_gitID");

    if ( isempty ( orig ) )
      error ("Sorry, could not locate your octapps-installation ...\n");
    endif

    ind = rindex ( orig, "/" );
    if ( ind == 0 )
      error ("Could not find path from '%s'\n", orig );
    endif
    directory = orig ( 1:(ind -1) );
    if ( !exist("prefix") )
      prefix = "octapps";
    endif

  endif

  if ( !exist("prefix") ) %% backward compatibility option
    directory = ".";
    prefix = "";
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
  fmt_title="format:%s";
  logcmd_title = sprintf( "%sgit log -1 --pretty='%s'", cdcmd, fmt_title );

  [ err, git_id ] = system ( logcmd_id );
  if ( err )
    ## we seem to be unable to run git; presumably we were not checked
    ## out of a repo
    git_id = "unknown.";
    git_author = "unknown.";
    git_title = "unknown.";
## If date unknown, use GPS 0 so it can still be parsed
    git_date_utc = "1980-01-06 00:00:00 UTC";
  else
    [ err, git_id ] = system ( logcmd_id );
    if ( err )
      error ("Unexpectedly failed to get git-ID, error was %d\n", err );
    endif
    [ err, git_udate ] = system ( logcmd_udate );
    if ( err )
      error ("Unexpectedly failed to get git-date, error was %d\n", err );
    endif
    mytime = gmtime(str2num(git_udate));
    git_date_utc = sprintf("%04d-%02d-%02d %02d:%02d:%02d UTC",
			   1900 + mytime.year, 1 + mytime.mon, mytime.mday,
			   mytime.hour, mytime.min, mytime.sec);
    [ err, git_author ] = system ( logcmd_author );
    if ( err )
      error ("Unexpectedly failed to get git-author, error was %d\n", err );
    endif
    [ err, git_title ] = system ( logcmd_title );
    if ( err )
      error ("Unexpectedly failed to get git-title, error was %d\n", err );
    endif
  endif

  statuscmd = sprintf( "%sgit diff-files --quiet", cdcmd );
  [ err, msg ] = system ( statuscmd );
  ## Three possibilities:
  switch ( err )
    case 0
      git_status = "CLEAN. All modifications commited.";
    case 1
      git_status = "UNCLEAN: some modifications were not commited!";
    otherwise
      ## non-zero non-1 error code: call probably failed failed
      git_status = "unknown.";
  endswitch

  ret.commitID = sprintf("$%sCommitID: %s$", prefix, git_id);
  ret.commitDate = sprintf("$%sCommitDate: %s$", prefix, git_date_utc);
  ret.commitAuthor = sprintf("$%sCommitAuthor: %s$", prefix, git_author);
  ## Should clean up the title in case it has a $ or something
  ret.commitTitle = sprintf("$%sCommitTitle: %s$", prefix, git_title);
  ret.gitStatus = sprintf("$%sGitStatus: %s$", prefix, git_status);
  ret.fullID = sprintf("     %s\n     %s\n     %s\n     %s\n     %s\n",
		       ret.commitID, ret.commitDate, ret.commitAuthor,
		       ret.commitTitle, ret.gitStatus);
endfunction
