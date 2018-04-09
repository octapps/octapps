## Copyright (C) 2012, 2014, 2017 Karl Wette
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
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {@var{cache_dir} =} @command{SuperskyMetricsCache ( ) }
## @deftypefnx{Function File} {} SuperskyMetricsCache @samp{action}
##
## Manage cache of computed supersky metrics
##
## @heading Arguments
##
## @table @asis
## @item @var{cache_dir}
## location of cache directory
##
## @item @samp{action}
## one of
## @table @code
##
## @item install
## Install the precomputed cache from the OctApps repository
##
## @item clear
## Clear the cache
##
## @item copytorepo
## Copy the current cache to the OctApps repository
##
## @end table
##
## @end table
##
## @end deftypefn

function varargout = SuperskyMetricsCache(action)

  ## build cache directory, and return if requested
  cache_dir = mkpath(getenv("HOME"), ".cache", "octapps", "ComputeSuperskyMetrics");
  if nargin == 0
    varargout = {cache_dir};
    return
  endif
  cache_parent_dir = fileparts(cache_dir);

  ## determine parent directory, where precomputed cache is located
  script_dir = fileparts(mfilename("fullpath"));

  ## check input
  assert(ischar(action));

  ## perform action
  switch action

    case "install"
      [status, msg] = system(sprintf("cd '%s' && tar xf '%s'", cache_parent_dir, fullfile(script_dir, "SuperskyMetricsCache.tar.bz2")));
      if status != 0
        error("%s: could not run tar: %s", funcName, msg);
      endif

    case "clear"
      rmdir(cache_dir, "s");

    case "copytorepo"
      [status, msg] = system(sprintf("cd '%s' && tar cf SuperskyMetricsCache.tar ComputeSuperskyMetrics/", cache_parent_dir));
      if status != 0
        error("%s: could not run tar: %s", funcName, msg);
      endif
      [status, msg] = system(sprintf("cd '%s' && bzip2 -v9 SuperskyMetricsCache.tar", cache_parent_dir));
      if status != 0
        error("%s: could not run bzip2: %s", funcName, msg);
      endif
      [status, msg] = movefile(fullfile(cache_parent_dir, "SuperskyMetricsCache.tar.bz2"), fullfile(script_dir, "SuperskyMetricsCache.tar.bz2"));
      if status != 1
        error("%s: could not move files: %s", funcName, msg);
      endif

    otherwise
      error("%s: invalid action '%s'", funcName, action);
  endswitch

endfunction

%!test
%!  cache_dir = SuperskyMetricsCache();
