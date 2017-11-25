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

## Manage cache of computed supersky metrics
## Usage:
##   cache_dir = SuperskyMetricsCache()
##   SuperskyMetricsCache <action>
## where
##   cache_dir:
##     location of cache directory
##   <action>: one of
##     install:
##       Install the precomputed cache from the Octapps repository
##     clear:
##       Clear the cache
##     copytorepo:
##       Copy the current cache to the Octapps repository

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
      chdir(cache_parent_dir);
      [status, msg] = system(sprintf("tar xf %s", fullfile(script_dir, "SuperskyMetricsCache.tar.bz2")));
      if status != 0
        error("%s: could not run tar: %s", funcName, msg);
      endif

    case "clear"
      rmdir(cache_dir, "s");

    case "copytorepo"
      chdir(cache_parent_dir);
      [status, msg] = system("tar cf SuperskyMetricsCache.tar ComputeSuperskyMetrics/");
      if status != 0
        error("%s: could not run tar: %s", funcName, msg);
      endif
      [status, msg] = system("bzip2 -v9 SuperskyMetricsCache.tar");
      if status != 0
        error("%s: could not run bzip2: %s", funcName, msg);
      endif
      [status, msg] = movefile("SuperskyMetricsCache.tar.bz2", fullfile(script_dir, "SuperskyMetricsCache.tar.bz2"));
      if status != 1
        error("%s: could not move files: %s", funcName, msg);
      endif

    otherwise
      error("%s: invalid action '%s'", funcName, action);
  endswitch

endfunction
