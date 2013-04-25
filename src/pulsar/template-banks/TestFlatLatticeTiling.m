## Copyright (C) 2012 Karl Wette
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

## Test the LALSuite FlatLatticeTiling algorithm with injection points.
## Usage:
##   results = TestFlatLatticeTiling(...)
## where:
##   results = struct containing:
##     num_templates = number of generated templates
##     num_injections = number of injections
##     mismatch_hgrm = mismatch histogram
## Options:
##   tiling: type of tiling to generate.
##     Options:
##       {square, ...}: Arbitrary metric and square parameter space.
##         Options:
##           metric: parameter space metric (default: identity matrix)
##           bounds: size of parameter space in each dimension.
##       {ellipse, ...}: Arbitrary metric and elliptical parameter space.
##         Options:
##           metric: parameter space metric (default: identity matrix)
##           semis: elliptical parameter space semi-diameters.
##           bounds: sizes of additional parameter-space dimensions.
##       {freq_square, ...}: CW frequency metric and square parameter space.
##         Options:
##           time_span: observation time in seconds
##           fndot: list of frequency and spindown values, in Hz, Hz/s, etc.
##           fndot_bands: list of frequency and spindown bands (may be negative)
##       {freq_agebrake, ...}: CW frequency metric and age-braking index parameter space.
##         Options:
##           time_span: observation time in seconds.
##           freq: starting frequency in Hz.
##           freq_band: frequency band in Hz.
##           age: spindown age in seconds.
##           f1dot_brake: first spindown braking index range.
##           f2dot_brake: second spindown braking index range.
##       {sky+freq_square, ...}: CW super-sky-frequency metric and square parameter space.
##         Options:
##           time_span: observation time in seconds.
##           skyxy: centre of sky X-Y ellipse to observe (default: 0,0)
##           skyxy_semis: semi-diameters of sky X-Y ellipse (default: 1,1)
##           skyz: sky Z component to compute:
##             lower (hemisphere), plane, upper, sphere
##           fndot: list of frequency and spindown values, in Hz, Hz/s, etc.
##           fndot_bands: list of frequency and spindown bands (may be negative)
##           ref_time: reference time, in GPS seconds
##           ephem_year: ephemeris year string (e.g. 00-19-DE405)
##           detectors: comma-separated list of detector names
##           sky_coords: super-sky coordinate system (default: equatorial)
##           align_sky: use sky-aligned super-sky metric (default: true)
##           offset_sky: use sky-offset frequency coordinates (default: true)
##           det_motion: which detector motion to use
##   lattice: type of lattice to use.
##     Options:
##       "Zn": n-dimensional hypercubic lattice
##       "Ans": n-dimensional An* lattice
##   max_mismatch: maximum prescribed mismatch
##   num_injections: number of injection points to test with
##      if < 0, use as a ratio of number of generated templates
##   workspace_size: size of workspace for computing mismatch histogram
##   return_points: return templates and injections (default: false)
##   return_hgrm: return injection mismatch histogram (default: true)
##   histogram_bins: number of mismatch histogram bins

function results = TestFlatLatticeTiling(varargin)

  ## Parse options
  parseOptions(varargin,
               {"tiling", "cell,vector"},
               {"lattice", "char"},
               {"max_mismatch", "real,strictpos,scalar"},
               {"num_injections", "real,scalar", 0},
               {"workspace_size", "real,scalar", 5000},
               {"return_points", "logical,scalar", false},
               {"return_hgrm", "logical,scalar", true},
               {"histogram_bins", "integer,strictpos,scalar", 100},
               []);

  ## Check input
  if !ischar(tiling{1})
    error("%s: first argument to 'tiling' must be a string", funcName);
  endif

  ## Load LAL libraries
  lal;
  lalpulsar;

  ## Create output struct
  results = struct;
  results.gitID = format_gitID(lalcvar.lalVCSInfo, lalpulsarcvar.lalPulsarVCSInfo, octapps_gitID);

  ## Create tiling, set up parameter space, and create metric
  switch tiling{1}

    case "square"

      ## Parse options
      parseOptions(tiling(2:end),
                   {"metric", "real,symmetric", []},
                   {"bounds", "real,vector"},
                   []);
      assert(isempty(metric) || size(metric, 1) == length(bounds));
      assert(det(metric) > 0);

      ## Create tiling
      dim = length(bounds);
      flt = CreateFlatLatticeTiling(dim);

      ## Add square bounds
      for i = 1:length(bounds)
        SetFlatLatticeConstantBound(flt, i-1, 0, bounds(i));
      endfor

      ## Create metric
      gslmetric = new_gsl_matrix(dim, dim);
      if isempty(metric)
        gslmetric.data = eye(dim);
      else
        gslmetric.data = metric;
      endif

    case "ellipse"

      ## Parse options
      parseOptions(tiling(2:end),
                   {"metric", "real,symmetric", []},
                   {"semis", "real,vector,numel:2"},
                   {"bounds", "real,vector", []},
                   []);
      assert(isempty(metric) || size(metric, 1) == length(semis) + length(bounds));
      assert(det(metric) > 0);

      ## Create tiling
      dim = 2 + length(bounds);
      flt = CreateFlatLatticeTiling(dim);

      ## Add elliptical bounds
      SetFlatLatticeEllipticalBounds(flt, 0, 0.0, 0.0, semis(1), semis(2));

      ## Add square bounds
      for i = 1:length(bounds)
        SetFlatLatticeConstantBound(flt, i+1, 0.0, bounds(i));
      endfor

      ## Create metric
      gslmetric = new_gsl_matrix(dim, dim);
      if isempty(metric)
        gslmetric.data = eye(dim);
      else
        gslmetric.data = metric;
      endif

    case "freq_square"

      ## Parse options
      parseOptions(tiling(2:end),
                   {"time_span", "real,strictpos,scalar"},
                   {"fndot", "real,vector"},
                   {"fndot_bands", "real,vector", []},
                   []);

      ## Create tiling
      dim = length(fndot);
      flt = CreateFlatLatticeTiling(dim);

      ## Add frequency and spindown bounds
      if isempty(fndot_bands)
        fndot_bands = zeros(size(fndot));
      endif
      for i = 1:length(fndot)
        SetFlatLatticeConstantBound(flt, i-1, fndot(i), fndot(i) + fndot_bands(i));
      endfor

      ## Create frequency metric
      gslmetric = new_gsl_matrix(dim, dim);
      SpindownMetric(gslmetric, time_span);

    case "freq_agebrake"

      ## Parse options
      parseOptions(tiling(2:end),
                   {"time_span", "real,strictpos,scalar"},
                   {"freq", "real,scalar"},
                   {"freq_band", "real,scalar"},
                   {"age", "real,strictpos,scalar"},
                   {"f1dot_brake", "real,strictpos,vector"},
                   {"f2dot_brake", "real,strictpos,vector"},
                   []);

      ## Create 3D tiling
      dim = 3;
      flt = CreateFlatLatticeTiling(dim);

      ## Create frequency metric
      gslmetric = new_gsl_matrix(dim, dim);
      SpindownMetric(gslmetric, time_span);

      ## Add frequency bound
      SetFlatLatticeConstantBound(flt, 0, freq, freq + freq_band);

      ## Add first spindown age-braking index bound
      SetFlatLatticeF1DotAgeBrakingBound(flt, 0, 1, age, min(f1dot_brake), max(f1dot_brake));

      ## Add second spindown braking index bound
      SetFlatLatticeF2DotBrakingBound(flt, 0, 1, 2, min(f2dot_brake), max(f2dot_brake));

    case "sky+freq_square"

      ## Parse options
      parseOptions(tiling(2:end),
                   {"time_span", "real,strictpos,scalar"},
                   {"skyxy", "real,vector,numel:2", [0.0, 0.0]},
                   {"skyxy_semis", "real,positive,vector", 1.0},
                   {"skyz", "char", "sphere"},
                   {"fndot", "real,vector"},
                   {"fndot_bands", "real,vector", []},
                   {"ref_time", "real,strictpos,scalar"},
                   {"ephem_year", "char"},
                   {"detectors", "char"},
                   {"sky_coords", "char", "equatorial"},
                   {"align_sky", "logical", true},
                   {"offset_sky", "logical", true},
                   {"det_motion", "char", []},
                   []);
      assert(length(skyxy_semis) <= 2);

      ## Calculate number of spindowns
      spindowns = length(fndot) - 1;

      ## Create spin-orbit component metric
      [sometric, coordIDs] = CreatePhaseMetric("coords", "spin_equ,orbit_ecl,freq,fdots",
                                               "time_span", time_span,
                                               "ref_time", ref_time,
                                               "detectors", detectors,
                                               "spindowns", spindowns,
                                               "ephem_year", ephem_year,
                                               "fiducial_freq", fndot(1),
                                               "det_motion", det_motion);

      ## Construct super-sky metrics
      [ssmetric, skyoff, alignsky] = ConstructSuperSkyMetrics(sometric, coordIDs,
                                                              "sky_coords", sky_coords,
                                                              "residual_sky", true,
                                                              "aligned_sky", align_sky);
      if !offset_sky
        skyoff = zeros(size(skyoff));
      endif
      results.sky_offset = skyoff;

      ## Create tiling
      dim = 4 + spindowns;
      flt = CreateFlatLatticeTiling(dim);

      ## Add sky position bounds
      if length(skyxy_semis) < 2
        skyxy_semis(2) = skyxy_semis(1);
      endif
      SetFlatLatticeEllipticalBounds(flt, 0, skyxy(1), skyxy(2), skyxy_semis(1), skyxy_semis(2));
      switch skyz
        case "lower"
          skyz_type = FLSSNZ_LOWER;
        case "plane"
          skyz_type = FLSSNZ_PLANE;
        case "upper"
          skyz_type = FLSSNZ_UPPER;
        case "sphere"
          skyz_type = FLSSNZ_SPHERE;
        otherwise
          error("%s: unknown skyz option '%s'", funcName, skyz);
      endswitch
      SetFlatLatticeSuperSkyNZBound(flt, 2, skyz_type);

      ## Add frequency and spindown bounds
      if isempty(fndot_bands)
        fndot_bands = zeros(size(fndot));
      endif
      for i = 1:length(fndot)
        SetFlatLatticeFnDotConstantBound(flt, 0, skyoff(i,:), i+2, fndot(i), fndot(i) + fndot_bands(i));
      endfor

      ## Set metric
      gslmetric = new_gsl_matrix(dim, dim);
      gslmetric.data = ssmetric;

    otherwise
      error("%s: unknown tiling '%s'", funcName, tiling{1});

  endswitch

  ## Set lattice generator
  switch lattice
    case "Zn"
      SetFlatLatticeGenerator(flt, CubicLatticeGeneratorPtr);
    case "Ans"
      SetFlatLatticeGenerator(flt, AnstarLatticeGeneratorPtr);
    otherwise
      error("%s: unknown lattice '%s'", funcName, lattice);
  endswitch

  ## Set metric
  SetFlatLatticeMetric(flt, gslmetric, max_mismatch);

  ## Fill output struct
  results.metric = gslmetric.data(:,:);
  results.max_mismatch = max_mismatch;
  results.templates = [];
  results.injections = [];
  results.nearest_index = [];
  results.min_mismatch = [];
  results.mismatch_hgrm = [];

  ## Count number of templates
  results.num_templates = double(CountTotalFlatLatticePoints(flt));

  ## Generate templates, if requested
  if return_points
    results.templates = zeros(dim, results.num_templates);
    for i = 1:results.num_templates
      NextFlatLatticePoint(flt);
      assert(GetFlatLatticePointCount(flt) == i);
      template = GetFlatLatticePoint(flt);
      results.templates(:, i) = template.data(:);
    endfor
  endif

  if num_injections != 0

    ## If number of injections is negative, treat as ratio of number of generated templates
    if num_injections < 0
      num_injections = abs(num_injections) * results.num_templates;
    endif

    ## Round number of injections up
    num_injections = ceil(num_injections);
    results.num_injections = num_injections;

    ## Create random number generator
    rng = CreateRandomParams(floor(rand() * (2^31 - 1)));

    ## Return injections, nearest template index, and minimum mismatches, if requested
    if return_points
      results.injections = zeros(dim, num_injections);
      results.nearest_index = zeros(1, num_injections);
      results.min_mismatch = zeros(1, num_injections);
    endif

    ## Initialise arguments to NearestFlatLatticePointToRandomPoints()
    injections = [];
    nearest_index = [];
    min_mismatch = [];
    workspace = [];

    ## Create mismatch histogram, if requested
    if return_hgrm
      results.mismatch_hgrm = Hist(1);
    endif

    ## Iterate over injections
    while num_injections > 0

      ## If workspace size is larger than number of
      ## remaining injections, reduce workspace size
      if workspace_size > num_injections
        workspace_size = num_injections;
      endif

      ## Generate injections and find nearest template point
      [injections, nearest_index, min_mismatch, workspace] = ...
          NearestFlatLatticePointToRandomPoints(flt, rng, workspace_size, ...
                                                injections, nearest_index, min_mismatch, workspace);

      ## Add minimum mismatches to histogram
      if return_hgrm
        results.mismatch_hgrm = addDataToHist(results.mismatch_hgrm, min_mismatch.data / max_mismatch, 1.0 / histogram_bins);
      endif

      ## Decrement number of remaining injections
      num_injections -= workspace_size;

      ## Return injections, nearest template index, and minimum mismatches, if requested
      if return_points
        jj = num_injections + (1:workspace_size);
        results.injections(:, jj) = injections.data;
        results.nearest_index(jj) = 1 + double(nearest_index.data);
        results.min_mismatch(jj) = min_mismatch.data;
      endif

    endwhile

  endif

endfunction


## Generate reference template banks

%!#demo
%! parent_dir = fileparts(which("TestFlatLatticeTiling"));
%! square_ref = TestFlatLatticeTiling("tiling", {"freq_square", "time_span", 864000, "fndot", [100, -1e-7], "fndot_bands", [1e-8, 1e-7]}, ...
%!                                    "lattice", "Ans", "max_mismatch", 3.0, "num_injections", 0, "return_points", true);
%! save("-hdf5", fullfile(parent_dir, "TestFlatLatticeTiling_square_ref.h5"), "square_ref");

%!#demo
%! parent_dir = fileparts(which("TestFlatLatticeTiling"));
%! agebrake_ref = TestFlatLatticeTiling("tiling", {"freq_agebrake", "time_span", 864000, "freq", 100, "freq_band", 1e-8, ...
%!                                                 "age", 3e9, "f1dot_brake", [2, 7], "f2dot_brake", [2, 7]}, ...
%!                                      "lattice", "Ans", "max_mismatch", 3.0, "num_injections", 0, "return_points", true);
%! save("-hdf5", fullfile(parent_dir, "TestFlatLatticeTiling_agebrake_ref.h5"), "agebrake_ref");

## Test flat lattice tiling against reference template banks

%!test
%! parent_dir = fileparts(which("TestFlatLatticeTiling"));
%! load(fullfile(parent_dir, "TestFlatLatticeTiling_square_ref.h5"));
%! square = TestFlatLatticeTiling("tiling", {"freq_square", "time_span", 864000, "fndot", [100, -1e-7], "fndot_bands", [1e-8, 1e-7]}, ...
%!                                "lattice", "Ans", "max_mismatch", 3.0, "num_injections", 1000, "return_points", true);
%! assert(square.num_templates == square_ref.num_templates);
%! assert(all(all(abs(square.templates - square_ref.templates) < 1e-7 * abs(square_ref.templates))));
%! dx = square.injections - square.templates(:, square.nearest_index);
%! assert(all(abs(dot(dx, square.metric * dx) - square.min_mismatch) < 1e-7 * square.min_mismatch))

%!test
%! parent_dir = fileparts(which("TestFlatLatticeTiling"));
%! load(fullfile(parent_dir, "TestFlatLatticeTiling_agebrake_ref.h5"));
%! agebrake = TestFlatLatticeTiling("tiling", {"freq_agebrake", "time_span", 864000, "freq", 100, "freq_band", 1e-8, ...
%!                                             "age", 3e9, "f1dot_brake", [2, 7], "f2dot_brake", [2, 7]}, ...
%!                                  "lattice", "Ans", "max_mismatch", 3.0, "num_injections", 1000, "return_points", true);
%! assert(agebrake.num_templates == agebrake_ref.num_templates);
%! assert(all(all(abs(agebrake.templates - agebrake_ref.templates) < 1e-7 * abs(agebrake_ref.templates))));
%! dx = agebrake.injections - agebrake.templates(:, agebrake.nearest_index);
%! assert(all(abs(dot(dx, agebrake.metric * dx) - agebrake.min_mismatch) < 1e-7 * agebrake.min_mismatch))
