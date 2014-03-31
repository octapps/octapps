## Copyright (C) 2014 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
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

## Prints a progress message at decreasing intervals, displaying
## the number of tasks completed, CPU usage, time elasped/remaining
## Usage:
##   prog = [];
##   for i = 1:5000
##     for j = 1:5
##       doSomeTask(i, j, ...);
##       prog = printProgress(prog, [i, j], [5000, 5]);
##     endfor
##   endfor

function prog = printProgress(prog, ii, NN)

  # check input
  assert(isvector(ii));
  assert(isvector(NN));
  assert(length(ii) == length(NN));
  assert(prod(NN) > 0);

  ## store initial CPU and wall times, and
  ## last time progress was printed
  if !isstruct(prog)
    prog = struct();
    prog.cpu0 = cputime();
    prog.wall0 = tic();
    prog.last0 = prog.wall0;
  endif

  ## compute elapsed CPU and wall times,
  ## and time since progress was printed
  cpu = cputime() - prog.cpu0;
  wall = double(tic() - prog.wall0)*1e-6;
  last = double(tic() - prog.last0)*1e-6;

  ## compute progress-printing interval from current
  ## elapsed wall time:
  ## - smallest interval of 10s
  ## - increases to ~5m after 1h has elapsed
  ## - converges to 1h after >1d has elapsed
  interval = 10*ceil(360*(1 - exp(-wall/42000)));

  if last > interval

    ## uses dbstack() to get the name of the
    ## calling function - see funcName()
    stack = dbstack();
    if numel(stack) > 1
      name = stack(2).name;
    else
      ## caller must be Octave workspace;
      ## use script name instead
      name = program_name();
    endif

    ## make sure 1 <= ii <= NN
    ii = max(1, min(ii, NN));

    ## work out current and total number of tasks
    n = sub2ind(NN(end:-1:1), num2cell(ii(end:-1:1)){:});
    N = prod(NN);
    npc = 100 * n / N;

    ## work out CPU usage
    cpupc = 100 * cpu / (wall + eps);

    ## work out remaining wall time, assuming all
    ## tasks take the same amount of time
    wall_rem = wall * (N - n) / n;

    # print progress
    pso = page_screen_output(0);
    printf("%s: task %i/%i (%0.1f%%), CPU %0.1f%%, %0.0fs elapsed, %0.0fs remain\n", name, n, N, npc, cpupc, wall, wall_rem);
    page_screen_output(pso);

    ## update time since progress was printed
    prog.last0 = tic();

  endif

endfunction