%% ret = octapps_gitID()
%%
%% Return the current HEAD git-tag (commitID, date, etc)
%% of OCTAPPS.
%%
%% If the optional argument 'run_local' == true, then
%% determine the git-tag of the *local* directory in which the
%% current calling script is running. (default == false)
%%
%% returns struct with fields {fullID, commitID, commitDate, commitAuthor, commitTitle, gitStatus}
%% where 'fullID' is a nicely-formatted concatenation of the individual fields
%%

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

function ret = octapps_gitID ( run_local )

  if ( !exist("run_local") )	%% default is to run in OCTAPPS repo
    run_local = 0;
  endif

  if ( ! run_local )
    orig = which("octapps_gitID");

    if ( isempty ( orig ) )
      error ("Sorry, could not localize your octapps-installation ...\n");
    endif

    ind = rindex ( orig, "/" );
    if ( ind == 0 )
      error ("Could not find path from '%s'\n", orig );
    endif
    origdir = orig ( 1:(ind -1) );

    cdcmd = strcat ( "cd ", origdir, " && " );
  else
    cdcmd = "";
  endif	## !run_local

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

  [ err, git_id ] = system29 ( logcmd_id );
  if ( err )
    ## we seem to be unable to run git; presumably we were not checked
    ## out of a repo
    git_id = "unknown.";
    git_author = "unknown.";
    git_title = "unknown.";
## If date unknown, use GPS 0 so it can still be parsed
    git_date_utc = "1980-01-06 00:00:00 UTC";
  else
    [ err, git_id ] = system29 ( logcmd_id );
    if ( err )
      error ("Unexpectedly failed to get git-ID, error was %d\n", err );
    endif
    [ err, git_udate ] = system29 ( logcmd_udate );
    if ( err )
      error ("Unexpectedly failed to get git-date, error was %d\n", err );
    endif
    mytime = gmtime(str2num(git_udate));
    git_date_utc = sprintf("%04d-%02d-%02d %02d:%02d:%02d UTC",
			   1900 + mytime.year, 1 + mytime.mon, mytime.mday,
			   mytime.hour, mytime.min, mytime.sec);
    [ err, git_author ] = system29 ( logcmd_author );
    if ( err )
      error ("Unexpectedly failed to get git-author, error was %d\n", err );
    endif
    [ err, git_title ] = system29 ( logcmd_title );
    if ( err )
      error ("Unexpectedly failed to get git-title, error was %d\n", err );
    endif
  endif

  statuscmd = sprintf( "%sgit status -a", cdcmd );
  [ err, msg ] = system29 ( statuscmd );

  ## Three possibilities:
  if ( err )
    if ( msg )
      ## non-zero error code, with output: no changes to be committed
      git_status = "CLEAN. All modifications commited."
    else
      ## non-zero error code, empty output: call to git status failed
      git_status = "unknown."
    endif
  else
    ## zero error code: changes to be committed
    git_status = "UNCLEAN: some modifications were not commited!";
 endif

  ret.commitID = sprintf("$CommitID: %s$", git_id);
  ret.commitDate = sprintf("$CommitDate: %s$", git_date_utc);
  ret.commitAuthor = sprintf("$CommitAuthor: %s$", git_author);
  ## Should clean up the title in case it has a $ or something
  ret.commitTitle = sprintf("$CommitTitle: %s$", git_title);
  ret.gitStatus = sprintf("$GitStatus: %s$", git_status);
  ret.fullID = sprintf("     %s\n     %s\n     %s\n     %s\n     %s\n",
		       ret.commitID, ret.commitDate, ret.commitAuthor,
		       ret.commitTitle, ret.gitStatus);
endfunction
