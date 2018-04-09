## Copyright (C) 2018 Reinhard Prix
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
## @deftypefn {Function File} {@var{setup} =} WeaveReadSetup ( @var{setup_file} )
##
## Returns pre-parsed setup file as a struct with additional fields:
##
## @table @samp
## @item segment_list
## Nx2 array of segment GPS [ start-times ; end-times ]
## @item segment_props
## pre-parsed segment properties returned by @command{AnalyseSegmentList()}
## @item Nsegments
## number of segments
## @item Ndetectors
## number of detectors
## @item detectors
## cell-array of detector-names
## @item ref_time
## reference GPS time
## @item start_time
## first segment start time
## @item coh_Tspan
## average segment length (=coherent length)
## @item semi_Tspan
## total time-span of segment list
##
## @end table
##
## @end deftypefn

function setup = WeaveReadSetup ( setup_file )

  setup = fitsread(setup_file);
  assert(isfield(setup, "segments"));
  segs = setup.segments.data;
  if ( !iscell(setup.primary.header.detect) )
    detect{1} = setup.primary.header.detect;
  else
    detect = setup.primary.header.detect;
  endif

  setup.segment_list  = [ [segs.start_s] + 1e-9*[segs.start_ns]; [segs.end_s] + 1e-9*[segs.end_ns] ]';
  setup.segment_props = AnalyseSegmentList(setup.segment_list);
  setup.Nsegments     = setup.segment_props.num_segments;
  setup.Ndetectors    = numel ( detect );
  setup.detectors     = detect;
  setup.ref_time      = str2double(setup.primary.header.date_obs_gps);
  setup.start_time    = min(setup.segment_props.start_times);
  setup.coh_Tspan     = setup.segment_props.coh_mean_Tspan;
  setup.semi_Tspan    = setup.segment_props.inc_Tspan;

  return;
endfunction

%!test
%!  setup_file = fullfile(fileparts(file_in_loadpath("WeaveReadSetup.m")), "test_setup_file.fits");
%!  setup = WeaveReadSetup(setup_file);
%!  assert(isstruct(setup));
