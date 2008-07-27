%% ret = octapps_gitID()
%%
%% Return the current HEAD git-tag (commitID, dateID, commit-string)
%% of OCTAPPS.
%%
%% If the optional argument 'run_local' == true, then
%% determine the git-tag of the *local* directory in which the
%% current calling script is running. (default == false)
%%
%% returns struct with fields {commitID, commitDate, commitAuthor, commitTitle}
%%
%%

%%
%% Copyright (C) 2008 Reinhard Prix
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

    logcmd = strcat ( "cd ", origdir, " && " );
  else
    logcmd = "";
  endif	## !run_local

  fmt = "format:CommitID: %H %nCommitDate: %aD %nCommitAuthor: %ae %nCommitTitle: %s";
  logcmd = sprintf ( "%s git-log -1 --pretty='%s'", logcmd, fmt );

  [err, gitid ] = system29 ( logcmd );
  if ( err )
    error ("Failed to get git-ID, error was %d\n", err );
  endif

  ind0 = index ( gitid, "CommitID: ");
  ind1 = index ( gitid, "CommitDate: ");
  ind2 = index ( gitid, "CommitAuthor: ");
  ind3 = index ( gitid, "CommitTitle: ");

  if ( !ind0 || !ind1 || !ind2 || !ind3 )
    error ("Failed to parse git-id string '%s'\n", gitid );
  endif

  ret.commitID     = deblank(gitid ( ind0+length("CommitID: "):ind1-1 ));
  ret.commitDate   = deblank(gitid ( ind1+length("CommitDate: "):ind2-1 ));
  ret.commitAuthor = deblank(gitid ( ind2+length("CommitAuthor: "):ind3-1 ));
  ret.commitTitle  = deblank(gitid ( ind3+length("CommitTitle: "):end ));


endfunction
