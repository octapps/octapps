## Copyright (C) 2015, 2017 Karl Wette
## Copyright (C) 2017 Reinhard Prix
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
## @deftypefn {Function File} { [ @var{coh_Nt}, @var{semi_Nt}, @var{dfreq} ] =} WeaveTemplateCount ( @var{opt}, @var{val}, @dots{} )
##
## Estimate the number of templates computed by @command{lalapps_Weave}
##
## @heading Arguments
##
## @table @var
## @item coh_Nt
## number of coherent templates
##
## @item semi_Nt
## number of semicoherent templates
##
## @item dfreq
## frequency spacing
##
## @end table
##
## @heading Options
##
## @table @code
## @item @strong{EITHER}
## @table @code
##
## @item setup_file
## Weave setup file
##
## @end table
##
## @item @strong{OR}
## @table @code
##
## @item Nsegments
## Number of segments
##
## @item detectors
## Comma-separated list of detectors
##
## @item ref_time
## GPS reference time
##
## @item coh_Tspan
## Time span of coherent segments
##
## @item semi_Tspan
## Total time span of semicoherent search
##
## @end table
##
## @item @strong{EITHER}
## @table @code
##
## @item result_file
## Weave result file
##
## @end table
##
## @item @strong{OR}
## @table @code
##
## @item sky_area
## Area of sky to cover (4*pi = entire sky)
##
## @item freq_min/max
## Minimum/maximum frequency range
##
## @item f1dot_min/max
## Minimum/maximum 1st spindown
##
## @item f2dot_min/max
## Minimum/maximum 2nd spindown (optional)
##
## @item coh_max_mismatch
## @itemx semi_max_mismatch
## Maximum coherent and semicoherent mismatches; for a single-
## segment or non-interpolating search, set @var{coh_max_mismatch}=0
##
## @end table
##
## @item lattice
## Type of @var{lattice} to use (default: Ans)
##
## @end table
##
## @end deftypefn

## octapps_run_link

function [coh_Nt, semi_Nt, dfreq] = WeaveTemplateCount(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"Nsegments", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"detectors", "char,+exactlyone:setup_file", []},
               {"ref_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"coh_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"semi_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"result_file", "char", []},
               {"sky_area", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_min", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f1dot_min", "real,scalar,+exactlyone:result_file", []},
               {"f1dot_max", "real,scalar,+exactlyone:result_file", []},
               {"f2dot_min", "real,scalar,+atmostone:result_file", 0},
               {"f2dot_max", "real,scalar,+atmostone:result_file", 0},
               {"coh_max_mismatch", "real,positive,scalar,+atmostone:result_file", []},
               {"semi_max_mismatch", "real,positive,scalar,+atmostone:result_file", []},
               {"lattice", "char", "Ans"},
               []);

  ## load ephemerides
  ephemerides = loadEphemerides();

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = WeaveReadSetup(setup_file);
    Nsegments  = setup.Nsegments;
    detectors  = setup.detectors;
    ref_time   = setup.ref_time;
    coh_Tspan  = setup.coh_Tspan;
    semi_Tspan = setup.semi_Tspan;
  endif

  ## if given, load result file and extract various parameters
  if !isempty(result_file)
    result = fitsread(result_file);
    result_hdr = result.primary.header;
    sky_area = result_hdr.semiparam_skyarea;
    freq_min = result_hdr.semiparam_minfreq;
    freq_max = result_hdr.semiparam_maxfreq;
    f1dot_min = result_hdr.semiparam_minf1dot;
    f1dot_max = result_hdr.semiparam_maxf1dot;
    f2dot_min = getoptfield(0, result_hdr, "semiparam_minf2dot");
    f2dot_max = getoptfield(0, result_hdr, "semiparam_maxf2dot");
    coh_max_mismatch = str2double(result_hdr.progarg_coh_max_mismatch);
    semi_max_mismatch = str2double(result_hdr.progarg_semi_max_mismatch);
  endif

  ## create frequency/spindown parameter space
  fkdot_bands = [freq_max - freq_min; f1dot_max - f1dot_min];
  if f2dot_min < f2dot_max
    fkdot_bands = [fkdot_bands; f2dot_max - f2dot_min];
  endif
  fkdot_bands = [fkdot_bands(2:end, :); fkdot_bands(1, :)];

  ## interpolation grid on number of segments
  Nsegments_interp = unique(max(1, round(Nsegments) + (-1:1)));

  ## interpolation grid on coherent timespan
  coh_Tspan_min = 81000;
  coh_Tspan_step = 21600;
  coh_Tspan_interp = max(coh_Tspan_min, unique(max(1, round(coh_Tspan / coh_Tspan_step) + (-1:1))) * coh_Tspan_step);

  ## empirical factors used to scale number of templates to match output of Weave
  coh_Nt_scale = 1.436;
  semi_Nt_scale = 1.000;

  ## compute interpolation grid for number of templates
  coh_Nt_interp = semi_Nt_interp = dfreq_interp = zeros(length(Nsegments_interp), length(coh_Tspan_interp));
  for i = 1:length(Nsegments_interp)
    for j = 1:length(coh_Tspan_interp)

      ## create segment list
      segment_list = CreateSegmentList(ref_time, Nsegments_interp(i), coh_Tspan_interp(j), semi_Tspan, []);

      ## compute supersky metrics
      metrics = ComputeSuperskyMetrics("spindowns", size(fkdot_bands, 1) - 1, "segment_list", segment_list, "ref_time", ref_time, "fiducial_freq", freq_max, "detectors", strjoin(detectors, ","));

      ## equalise frequency spacing between coherent and semicoherent metrics
      XLALEqualizeReducedSuperskyMetricsFreqSpacing(metrics, coh_max_mismatch, semi_max_mismatch);

      ## compute number of coherent templates
      for k = 1:metrics.num_segments
        coh_Nt_interp(i, j) += coh_Nt_scale * number_of_lattice_templates(lattice, metrics.coh_rssky_metric{k}.data, coh_max_mismatch, sky_area, fkdot_bands);
      endfor

      ## compute number of semicoherent templates
      semi_Nt_interp(i, j) = semi_Nt_scale * number_of_lattice_templates(lattice, metrics.semi_rssky_metric.data, semi_max_mismatch, sky_area, fkdot_bands);

      ## compute frequency spacing
      dfreq_interp(i, j) = 2 * sqrt(semi_max_mismatch / metrics.semi_rssky_metric.data(end, end));

    endfor
  endfor

  ## compute interpolated number of templates at requested Nsegments and coh_Tspan
  coh_Nt = ceil(interp2(coh_Tspan_interp, Nsegments_interp, coh_Nt_interp, coh_Tspan, max(1, Nsegments), "spline"));
  assert(!isnan(coh_Nt), "%s: could not evaluate coh_Nt(Nsegments=%g, coh_Tspan=%g)", funcName, Nsegments, coh_Tspan);
  semi_Nt = ceil(interp2(coh_Tspan_interp, Nsegments_interp, semi_Nt_interp, coh_Tspan, max(1, Nsegments), "spline"));
  assert(!isnan(semi_Nt), "%s: could not evaluate semi_Nt(Nsegments=%g, coh_Tspan=%g)", funcName, Nsegments, coh_Tspan);
  dfreq = interp2(coh_Tspan_interp, Nsegments_interp, dfreq_interp, coh_Tspan, max(1, Nsegments), "spline");
  assert(!isnan(dfreq), "%s: could not evaluate dfreq(Nsegments=%g, coh_Tspan=%g)", funcName, Nsegments, coh_Tspan);

endfunction

function Nt = number_of_lattice_templates(lattice, metric, max_mismatch, sky_area, fkdot_bands)

  ## calculate bounding box of metric
  bbox_metric = metricBoundingBox(metric, max_mismatch);

  ## calculate parameter-space volume and note non-singular dimensions
  param_vol = 1;
  nsii = false(size(metric, 1), 1);

  ## calculate sky parameter space
  if sky_area > 0
    param_vol *= max(bbox_metric(1)*bbox_metric(2), 2 * (pi + 4*bbox_metric(2) + bbox_metric(1)*bbox_metric(2)) * sky_area / (4 * pi));
    nsii(1:2) = true;
  endif
  ## - frequency/spindown
  for n = 1:length(fkdot_bands)
    if abs(fkdot_bands(n)) > 0
      param_vol *= abs(fkdot_bands(n)) + bbox_metric(2+n);
      nsii(2+n) = true;
    endif
  endfor

  ## compute number of templates
  Nt = NumberOfLatticeBankTemplates("lattice", lattice, "metric", metric(nsii, nsii), "max_mismatch", max_mismatch, "param_vol", param_vol);

endfunction

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  results = fitsread(fullfile(fileparts(file_in_loadpath("WeaveReadSetup.m")), "test_result_file.fits"));
%!  args = struct;
%!  args.setup_file = fullfile(fileparts(file_in_loadpath("WeaveReadSetup.m")), "test_setup_file.fits");
%!  args.result_file = fullfile(fileparts(file_in_loadpath("WeaveReadSetup.m")), "test_result_file.fits");
%!  [coh_Nt, semi_Nt] = fevalstruct(@WeaveTemplateCount, args);
%!  assert(coh_Nt, results.primary.header.ncohtpl, -0.2);
%!  assert(semi_Nt, results.primary.header.nsemitpl, -0.2);
