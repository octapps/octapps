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

## Analyse a segment list and return various properties.
## Usage:
##   props = AnalyseSegmentList(segment_list_2col)
##   props = AnalyseSegmentList(segment_list_4col, Ndet, Tsft=1800)
## where:
##   segment_list_2col = 2-column segment list: [start_times, end_times]
##   segment_list_4col = 4-column segment list: [start_times, end_times, (unused), num_SFTs]
##   Ndet              = number of detectors
##   Tspan             = SFT time-span in seconds

function props = AnalyseSegmentList(segment_list, Ndet, Tsft=1800)

  ## check input
  assert(!isempty(segment_list) && ismatrix(segment_list));
  assert(size(segment_list, 2) == 2 || size(segment_list, 2) == 4, "Segment list must have either 2 or 4 columns");
  if size(segment_list, 2) == 4
    assert(isscalar(Ndet) && Ndet > 0);
    assert(isscalar(Tsft) && Tsft > 0);
  endif

  ## extract columns; start/end times, and number of SFTs
  ts = segment_list(:, 1)';
  te = segment_list(:, 2)';
  if size(segment_list, 2) == 4
    nSFTs = segment_list(:, 4)';
  endif

  ## compute properties of segment list
  props.num_segments = length(ts);
  props.start_times = ts;
  props.end_times = te;
  props.mid_times = 0.5*(ts + te);
  props.mean_time = mean([ts, te]);
  if size(segment_list, 2) == 4
    props.coh_Tobs = nSFTs * Tsft / Ndet;
  endif
  props.coh_Tspan = te - ts;
  if size(segment_list, 2) == 4
    props.coh_duty = props.coh_Tobs ./ props.coh_Tspan;
  endif
  props.inc_Tobs = sum(te - ts);
  props.inc_Tspan = max(te) - min(ts);
  props.inc_duty = props.inc_Tobs ./ props.inc_Tspan;

endfunction
