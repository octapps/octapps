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

## Create segment list(s) with the given reference time 'reftime', total time span 'Tspan', number
## of segments 'Nseg', and (optionally) duty cycle 'duty' (= Nseg * Tseg / Tspan). Aside from
## 'reftime', each parameter may be vectorised to return multiple segment lists with all possible
## parameter combinations. Note that 'duty' has an effect only for 'Nseg' > 1.
## Usage:
##   segment_lists = CreateSegmentList(reftime, Tspan, Nseg, duty=1)

function varargout = CreateSegmentList(reftime, Tspan, Nseg, duty=1)

  ## check input
  assert(isscalar(reftime));
  assert(isvector(Tspan) && all(Tspan > 0));
  assert(isvector(Nseg) && all(Nseg > 0) && all(mod(Nseg, 1) == 0));
  assert(isvector(duty) && all(duty > 0) && all(duty <= 1));

  ## create grid out of segment input parameters
  [Tspan, Nseg, duty] = ndgrid(Tspan, Nseg, duty);

  ## generate segment lists
  segment_lists = cell(size(Tspan));
  for i = 1:numel(segment_lists)

    ## compute segment length
    if Nseg(i) > 1
      Tseg = Tspan(i) * duty(i) / Nseg(i);
    else
      Tseg = Tspan(i);
    endif

    ## generate segment timestamps, with mean of timestamps equal to reference time
    ts = linspace(0, Tspan(i) - Tseg, Nseg(i));
    ts = ts(:) - mean(ts) + reftime;

    ## generate segment list
    segment_lists{i} = [ts, ts + Tseg];

  endfor

  ## return segment lists
  if nargout == numel(segment_lists)
     varargout = segment_lists;
  else
    varargout = {segment_lists};
  endif

endfunction


%!test
%!  reftime = 1234567890;
%!  Tspan = [10, 55, 365.25];
%!  Nseg = [1, 3, 7, 15];
%!  duty = [1.0, 0.75, 0.5];
%!  S = CreateSegmentList(reftime, Tspan, Nseg, duty);
%!  assert(size(S) == [3, 4, 3]);
%!  for i = 1:size(S, 1)   ## Tspan
%!    for j = 1:size(S, 2)   ## Nseg
%!      for k = 1:size(S, 3)   ## duty
%!        s = S{i, j, k};
%!        if Nseg(j) > 1
%!          Tseg = Tspan(i) * duty(k) / Nseg(j);
%!        else
%!          Tseg = Tspan(i);
%!        endif
%!        assert(size(s) == [Nseg(j), 2]);
%!        assert(s(end, 2) - s(1, 1), Tspan(i), 1e-5);
%!        assert(diff(s, [], 2), Tseg * ones(Nseg(j), 1), 1e-5);
%!        if Nseg(j) > 1
%!          assert(diff(s, [], 1), (Tspan(i) - Tseg) / (Nseg(j) - 1) * ones(Nseg(j) - 1, 2), 1e-5);
%!          assert(s(2:end, 1) - s(1:end-1, 2), (Tspan(i) - Nseg(j) * Tseg) / (Nseg(j) - 1) * ones(Nseg(j) - 1, 1), 1e-5);
%!        endif
%!      endfor
%!    endfor
%!  endfor
