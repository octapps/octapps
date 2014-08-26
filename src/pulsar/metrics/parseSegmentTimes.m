## Copyright (C) 2014 Karl Wette
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

## Return vectors of start/end times from vectors of start/mid/end times and/or time spans
## Usage:
##   [ref_time, start_time, end_time] = parseSegmentTimes(ref_time, start_time, mid_time, end_time, time_span, [min_time], [max_time])
## where
##   ref_time   = reference time in GPS seconds [default: mean of segment start/end times]
##   start_time = start time(s) in GPS seconds of each segment [used with end_time or time_span]
##   mid_time   = mid time(s) in GPS seconds of each segment [used with time_span]
##   end_time   = end time(s) in GPS seconds of each segment [used with start_time or time_span]
##   time_span  = time span(s) in seconds of each segment [used with start_time, end_time, or mid_time]
##   min_time   = (optional) minimum allowed time in GPS seconds
##   max_time   = (optional) maximum allowed time in GPS seconds

function [ref_time, start_time, end_time] = parseSegmentTimes(ref_time, start_time, mid_time, end_time, time_span, min_time=[], max_time=[])

  ## check inputs
  if !isempty(start_time)
    start_time = start_time(:);
  endif
  if !isempty(mid_time)
    mid_time = mid_time(:);
  endif
  if !isempty(end_time)
    end_time = end_time(:);
  endif
  if !isempty(time_span)
    time_span = time_span(:);
  endif
  if !isempty(start_time) && !isempty(mid_time)
    error("%s: 'start_time' and 'mid_time' are mutually exclusive", funcName);
  endif
  if !isempty(end_time) && !isempty(mid_time)
    error("%s: 'end_time' and 'mid_time' are mutually exclusive", funcName);
  endif
  if !xor(!isempty(start_time) && !isempty(end_time), !isempty(time_span))
    error("%s: 'start_time' and 'end_time' are mutually exclusive with 'time_span'", funcName);
  endif
  if isempty(start_time) && isempty(mid_time) && isempty(end_time) && isempty(ref_time)
    error("%s: one of 'start_time', 'mid_time', 'end_time', or 'ref_time' must be given", funcName);
  endif
  if !isempty(start_time) && !isempty(end_time) && !all(start_time < end_time)
    error("%s: all values of 'start_time' must be strictly less than their corresponding 'end_time'", funcName);
  endif
  if !isempty(time_span) && !all(time_span > 0)
    error("%s: all values of 'time_span' must be strictly positive", funcName);
  endif

  ## create output
  if isempty(start_time)
    if !isempty(mid_time)
      start_time = mid_time - 0.5.*time_span;
    elseif !isempty(end_time)
      start_time = end_time - time_span;
    else
      start_time = ref_time - 0.5.*time_span;
    endif
  endif
  if isempty(end_time)
    if !isempty(mid_time)
      end_time = mid_time + 0.5.*time_span;
    elseif !isempty(start_time)
      end_time = start_time + time_span;
    else
      end_time = ref_time + 0.5.*time_span;
    endif
  endif
  if isempty(ref_time)
    ref_time = mean([start_time; end_time]);
  endif

  ## check times
  min_seg_time = min([start_time; end_time]);
  max_seg_time = max([start_time; end_time]);
  if min_seg_time < min_time || max_time < max_seg_time
    error("%s: segment time range [%f,%f] is outside allowed range [%f,%f]", funcName, min_seg_time, max_seg_time, min_time, max_time);
  endif

endfunction
