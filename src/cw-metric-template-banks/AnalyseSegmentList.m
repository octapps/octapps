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
## @deftypefn {Function File} {} AnalyseSegmentList ( @var{segment_list_2col} )
## @deftypefnx{Function File} {} AnalyseSegmentList ( @var{segment_list_4col}, @var{Ndet}, @var{Tsft}=1800 )
## @deftypefnx{Function File} {@var{props} =} AnalyseSegmentList ( @dots{} )
##
## Analyse a segment list and print/return various properties.
##
## @heading Arguments
##
## @table @var
## @item segment_list_2col
## 2-column segment list: [@code{start_times}, @code{end_times}]
##
## @item segment_list_4col
## 4-column segment list: [@code{start_times}, @code{end_times}, @strong{unused}, @code{num_SFTs}]
##
## @item Ndet
## number of detectors
##
## @item Tspan
## SFT time-span in seconds
##
## @end table
##
## @end deftypefn

function props = AnalyseSegmentList(segment_list, Ndet, Tsft=1800)

  ## load constants
  UnitsConstants;

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

  ## compute properties of segment list, and build string to print
  str = "";
  props = struct;
  props.num_segments = length(ts);
  str = strcat(str, sprintf("Number of segments: %i\n", props.num_segments));
  props.start_times = ts;
  str = strcat(str, sprintf("Start times: %0.9f to %0.9f\n", min(props.start_times), max(props.start_times)));
  props.end_times = te;
  str = strcat(str, sprintf("End times: %0.9f to %0.9f\n", min(props.end_times), max(props.end_times)));
  props.mid_times = 0.5*(ts + te);
  str = strcat(str, sprintf("Mid times: %0.9f to %0.9f\n", min(props.mid_times), max(props.mid_times)));
  props.mean_time = mean([ts, te]);
  str = strcat(str, sprintf("Mean time: %0.9f\n", props.mean_time));
  if size(segment_list, 2) == 4
    props.coh_Tobs = nSFTs * Tsft / Ndet;
    props.coh_mean_Tobs = mean(props.coh_Tobs);
    str = strcat(str, sprintf("Coherent observation times: %0.3f to %0.3f days\n", min(props.coh_Tobs)/DAYS, max(props.coh_Tobs)/DAYS));
  endif
  props.coh_Tspan = te - ts;
  props.coh_mean_Tspan = mean(props.coh_Tspan);
  str = strcat(str, sprintf("Coherent time spans: %0.3f to %0.3f days\n", min(props.coh_Tspan)/DAYS, max(props.coh_Tspan)/DAYS));
  if size(segment_list, 2) == 4
    props.coh_duty = props.coh_Tobs ./ props.coh_Tspan;
    props.coh_mean_duty = mean(props.coh_duty);
    str = strcat(str, sprintf("Coherent duty cycles: %0.3f to %0.3f\n", min(props.coh_duty), max(props.coh_duty)));
  endif
  props.inc_Tobs = sum(te - ts);
  str = strcat(str, sprintf("Incoherent observation time: %0.3f days\n", props.inc_Tobs/DAYS));
  props.inc_Tspan = max(te) - min(ts);
  str = strcat(str, sprintf("Incoherent time span: %0.3f days\n", props.inc_Tspan/DAYS));
  props.inc_duty = props.inc_Tobs ./ props.inc_Tspan;
  str = strcat(str, sprintf("Incoherent duty cycle: %0.3f\n", props.inc_duty));

  ## print string if not output arguments
  if nargout == 0
    clear props;
    printf("%s", str);
  endif

endfunction

%!shared props
%!  props = AnalyseSegmentList([0:2:10; 1:2:11]' * 86400);
%!assert(props.num_segments, 6)
%!assert(props.coh_mean_Tspan, 86400)
%!assert(props.inc_Tobs, 6 * 86400)
%!assert(props.inc_Tspan, 11 * 86400)
%!assert(props.inc_duty, 6 / 11, 1e-3)
