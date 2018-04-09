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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{segment_lists} =} CreateSegmentList ( @var{mean_time}, @var{Nseg}, @var{Tseg}, @var{Tspan}, @var{duty}, [ @var{always_cell}=false ] )
##
## Create segment list(s) with the given mean timestamp @var{mean_time}, and exactly 3 of the following
## 4 input parameters:
## @itemize
## @item number of segments @var{Nseg}
## @item segment time-span @var{Tseg}
## @item total time span @var{Tspan}
## @item incoherent @var{duty} cycle @var{duty}
## @end itemize
##
## Aside from @var{mean_time}, each parameter may be vectorised to return
## multiple segment lists with all possible parameter combinations.
##
## @end deftypefn

function varargout = CreateSegmentList(mean_time, Nseg, Tseg, Tspan, duty, always_cell=false)

  ## check input
  assert(isscalar(mean_time));
  nparams = 0;
  if !isempty(Nseg)
    assert(isvector(Nseg) && all(Nseg > 0) && all(mod(Nseg, 1) == 0));
    ++nparams;
  endif
  if !isempty(Tseg)
    assert(isvector(Tseg) && all(Tseg > 0));
    ++nparams;
  endif
  if !isempty(Tspan)
    assert(isvector(Tspan) && all(Tspan > 0));
    ++nparams;
  endif
  if !isempty(duty)
    assert(isvector(duty) && all(duty > 0) && all(duty <= 1));
    ++nparams;
  endif
  assert(nparams == 3, "Exactly 3 out of the 4 input parameters {'Nseg','Tseg','Tspan','duty'} must be used");

  ## create grid out of the 3 input parameters, and compute the missing 4th
  if isempty(Nseg)
    [Tseg, Tspan, duty] = ndgrid(Tseg, Tspan, duty);
    Nseg = Tspan .* duty ./ Tseg;
  elseif isempty(Tseg)
    [Nseg, Tspan, duty] = ndgrid(Nseg, Tspan, duty);
    Tseg = Tspan .* duty ./ Nseg;
  elseif isempty(Tspan)
    [Nseg, Tseg, duty] = ndgrid(Nseg, Tseg, duty);
    Tspan = Nseg .* Tseg ./ duty;
  elseif isempty(duty)
    [Nseg, Tseg, Tspan] = ndgrid(Nseg, Tseg, Tspan);
    duty = Nseg .* Tseg ./ Tspan;
  endif
  assert(!cellfun(@isempty, {Nseg, Tseg, Tspan, duty}));

  ## generate segment lists
  segment_lists = cell(size(Nseg));
  for i = 1:numel(segment_lists)
    ts = reshape(linspace(0, Tspan(i) - Tseg(i), Nseg(i)), [], 1);
    S = [ts, ts + Tseg(i)];
    S = S - mean(S(:)) + mean_time;
    segment_lists{i} = round(S);
  endfor

  ## return segment lists
  if always_cell || numel(segment_lists) > 1
    varargout = {segment_lists};
  else
    varargout = segment_lists;
  endif

endfunction

%!assert( iscell(CreateSegmentList(123, 10, [3, 4], [], 1.0)) )
%!assert( numel(CreateSegmentList(123, 10, [3, 4], [], 1.0)) == 2 )
%!assert( !iscell(CreateSegmentList(123, 10, 3, [], 1.0)) )
%!assert( iscell(CreateSegmentList(123, 10, 3, [], 1.0, true)) )

%!assert( AnalyseSegmentList(CreateSegmentList(456, [], 7.3, 140.9, 0.87)).mean_time, 456, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(456, [], 7.3, 140.9, 0.87)).num_segments, 16, 1e-5 )
%!assert( mean(AnalyseSegmentList(CreateSegmentList(456, [], 7.3, 140.9, 0.87)).coh_Tspan), 7.375, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(456, [], 7.3, 140.9, 0.87)).inc_Tspan, 140, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(456, [], 7.3, 140.9, 0.87)).inc_duty, 0.84286, 1e-5 )

%!assert( AnalyseSegmentList(CreateSegmentList(345, 50, [], 256.7, 0.77)).mean_time, 345, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(345, 50, [], 256.7, 0.77)).num_segments, 50, 1e-5 )
%!assert( mean(AnalyseSegmentList(CreateSegmentList(345, 50, [], 256.7, 0.77)).coh_Tspan), 4, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(345, 50, [], 256.7, 0.77)).inc_Tspan, 256, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(345, 50, [], 256.7, 0.77)).inc_duty, 0.78125, 1e-5 )

%!assert( AnalyseSegmentList(CreateSegmentList(234, 200, 3.7, [], 0.77)).mean_time, 234, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(234, 200, 3.7, [], 0.77)).num_segments, 200, 1e-5 )
%!assert( mean(AnalyseSegmentList(CreateSegmentList(234, 200, 3.7, [], 0.77)).coh_Tspan), 3.7, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(234, 200, 3.7, [], 0.77)).inc_Tspan, 962, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(234, 200, 3.7, [], 0.77)).inc_duty, 0.76923, 1e-5 )

%!assert( AnalyseSegmentList(CreateSegmentList(123, 100, 2.3, 365.25, [])).mean_time, 123, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(123, 100, 2.3, 365.25, [])).num_segments, 100, 1e-5 )
%!assert( mean(AnalyseSegmentList(CreateSegmentList(123, 100, 2.3, 365.25, [])).coh_Tspan), 2.34, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(123, 100, 2.3, 365.25, [])).inc_Tspan, 366, 1e-5 )
%!assert( AnalyseSegmentList(CreateSegmentList(123, 100, 2.3, 365.25, [])).inc_duty, 0.63934, 1e-5 )

%!assert( AnalyseSegmentList(CreateSegmentList(123, 1, 2.3, 365.25, [])).inc_duty, 1.0, 1e-5 )
