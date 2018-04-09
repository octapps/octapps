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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{prog} =} printProgress ( @dots{} )
##
## Prints a progress message at decreasing intervals, displaying
## the number of tasks completed, CPU usage, time elasped/remaining
##
## @heading Example
## @verbatim
## prog = [];
## for i = 1:5000
##   for j = 1:5
##     doSomeTask(i, j, ...);
##     prog = printProgress(prog, "inner loop", [i, j], [5000, 5]);
##   endfor
##   prog = printProgress(prog, [i, j], [5000, 5]);
## endfor
## @end verbatim
##
## @end deftypefn

function prog = printProgress(prog, varargin)

  ## always print output
  page_screen_output(0, "local");

  ## check input
  narginchk(3, 4);
  if ischar(varargin{1})
    assert(nargin == 4);
    taskstr = varargin{1};
    varargin(1) = [];
  else
    assert(nargin == 3);
    taskstr = "task";
  endif
  [ii, NN] = deal(varargin{:});
  assert(isvector(ii) && all(ii > 0));
  assert(isvector(NN) && all(NN > 0));
  assert(length(ii) == length(NN));

  ## store initial CPU and wall times, last time progress was printed, and fraction of tasks completed
  if !isstruct(prog)
    prog = struct();
    prog.cpu0 = cputime();
    prog.wall0 = tic();
    prog.last0 = prog.wall0;
    prog.f_tasks = 0;
  endif

  ## do not print again once 'f_tasks' reaches 100%
  if prog.f_tasks == 1
    return
  endif

  ## compute elapsed CPU and wall times, and time since progress was printed
  cpu = cputime() - prog.cpu0;
  wall = double(tic() - prog.wall0)*1e-6;
  last = double(tic() - prog.last0)*1e-6;

  ## compute progress-printing interval from current elapsed wall time:
  ## - smallest interval of 10s
  ## - increases to ~5m after 1h has elapsed
  ## - converges to 1h after >1d has elapsed
  interval = 10*ceil(360*(1 - exp(-wall/42000)));

  ## convert 'ii' and 'NN' to floating-point type, and ensure 1 <= ii <= NN
  NN = double(NN);
  ii = max(1, min(double(ii), NN));

  ## work out fraction of tasks completed
  if all(ii == NN)
    prog.f_tasks = 1;
  else
    prog.f_tasks = sum((ii - 1) ./ cumprod(NN)) + (1 ./ prod(NN));
  endif

  if last > interval || prog.f_tasks == 1

    ## uses dbstack() to get the name of the calling function - see funcName()
    stack = dbstack();
    if numel(stack) > 1
      name = stack(2).name;
    else
      ## caller must be Octave workspace; use script name instead
      name = program_name();
    endif

    ## work out CPU usage
    cpu_use = cpu / (wall + eps);

    ## work out remaining wall time, assuming all tasks take the same amount of time
    wall_rem = wall * ( (1 / (prog.f_tasks + eps)) - 1 );

    ## print progress
    printf("%s: %s %0.1f%%, CPU %0.1f%%, %0.0fs elapsed", name, taskstr, 100*prog.f_tasks, 100*cpu_use, wall);
    if prog.f_tasks < 1
      printf(", %0.0fs remain", wall_rem);
    endif
    printf("\n");

    ## update time since progress was printed
    prog.last0 = tic();

  endif

endfunction

%!test
%!  prog = [];
%!  for i = 1:50
%!    for j = 1:5
%!      prog = printProgress(prog, "inner loop", [i, j], [50, 5]);
%!    endfor
%!    prog = printProgress(prog, [i, j], [50, 5]);
%!  endfor
