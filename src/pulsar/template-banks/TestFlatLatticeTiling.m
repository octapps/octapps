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
##       {diag_square, ...}: Diagonal metric and square parameter space.
##         Options:
##           diagelem: diagonal elements of metric (default: 1s)
##           bounds: size of parameter space in each dimension.
##       {diag_ellipse, ...}: Diagonal metric and elliptical parameter space.
##         Options:
##           diagelem: diagonal elements of metric (default: 1s)
##           semis: elliptical parameter space semi-diameters (default: 1s)
##       {freq_square, ...}: CW frequency metric and square parameter space.
##         Options:
##           time_span: observation time in seconds
##           fndots: list of frequency and spindown values, in Hz, Hz/s, etc.
##           num_fndots: number of frequency/spindown values to tile in each dimension
##                       (mutually exclusive with fndot_bands)
##           fndot_bands: list of frequency and spindown bands (may be negative)
##                        (mutually exclusive with num_fndots)
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
##           fndots: list of frequency and spindown values, in Hz, Hz/s, etc.
##           num_fndots: number of frequency/spindown values to tile in each dimension
##                       (mutually exclusive with fndot_bands)
##           fndot_bands: list of frequency and spindown bands (may be negative)
##                        (mutually exclusive with num_fndots)
##           ref_time: reference time, in GPS seconds
##           detectors: comma-separated list of detector names
##           ephem_year: ephemeris year (default: 05-09)
##           sky_coords: super-sky coordinate system (default: equatorial)
##           sky_aligned: use sky-aligned super-sky metric (default: true)
##           ptolemaic: use Ptolemaic ephemerides (default: false)
##   lattice: type of lattice to use.
##     Options:
##       "Zn": n-dimensional hypercubic lattice
##       "Ans": n-dimensional An* lattice
##   max_mismatch: maximum prescribed mismatch
##   num_injections: number of injection points to test with
##      if < 0, use as a ratio of number of generated templates
##   workspace_size: size of workspace for computing mismatch histogram
##   histogram_bins: number of mismatch histogram bins
##   return_points: return templates and injections (default: false)

function results = TestFlatLatticeTiling(varargin)

  ## Parse options
  parseOptions(varargin,
               {"tiling", "cell,vector"},
               {"lattice", "char"},
               {"max_mismatch", "real,strictpos,scalar", 1.0},
               {"num_injections", "real,scalar", 0},
               {"workspace_size", "real,scalar", 5000},
               {"histogram_bins", "integer,strictpos,scalar", 100},
               {"return_points", "logical,scalar", false},
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

  ## Create tiling, set up parameter space, and create metric
  switch tiling{1}

    case "diag_square"

      ## Parse options
      parseOptions(tiling(2:end),
                   {"diagelem", "real,vector", []},
                   {"bounds", "real,vector"},
                   []);
      assert(isempty(diagelem) || length(diagelem) == length(bounds));

      ## Create tiling
      dim = length(bounds);
      flt = CreateFlatLatticeTiling(dim);

      ## Add square bounds
      for i = 1:dim
        SetFlatLatticeConstantBound(flt, i-1, 0, bounds(i));
      endfor

      ## Create diagonal metric
      metric = new_gsl_matrix(dim, dim);
      if isempty(diagelem)
        metric.data = eye(dim);
      else
        metric.data = diag(diagelem);
      endif

    case "diag_ellipse"

      ## Parse options
      parseOptions(tiling(2:end),
                   {"diagelem", "real,vector", []},
                   {"semis", "real,vector", [1, 1]},
                   []);
      assert(length(semis) == 2);
      assert(isempty(diagelem) || length(diagelem) == length(semis));

      ## Create tiling
      dim = 2;
      flt = CreateFlatLatticeTiling(dim);

      ## Add elliptic bounds
      SetFlatLatticeEllipticBounds(flt, 0, semis(1), semis(2));

      ## Create diagonal metric
      metric = new_gsl_matrix(dim, dim);
      if isempty(diagelem)
        metric.data = eye(dim);
      else
        metric.data = diag(diagelem);
      endif

    case "freq_square"

      ## Parse options
      parseOptions(tiling(2:end),
                   {"time_span", "real,strictpos,scalar"},
                   {"fndots", "real,vector"},
                   {"num_fndots", "real,strictpos,vector", []},
                   {"fndot_bands", "real,vector", []},
                   []);
      assert(xor(isempty(fndot_bands), isempty(num_fndots)));
      assert(isempty(fndot_bands) || length(fndot_bands) == length(fndots));
      assert(isempty(num_fndots) || length(num_fndots) == length(fndots));

      ## Create tiling
      dim = length(fndots);
      flt = CreateFlatLatticeTiling(dim);

      ## Add frequency and spindown bounds
      if !isempty(num_fndots)
        for i = 1:dim
          SetFlatLatticeBBoxExtentBound(flt, i-1, fndots(i), num_fndots(i));
        endfor
      else
        if isempty(fndot_bands)
          fndot_bands = zeros(size(fndots));
        endif
        for i = 1:dim
          SetFlatLatticeConstantBound(flt, i-1, fndots(i), fndots(i) + fndot_bands(i));
        endfor
      endif

      ## Create frequency metric
      metric = new_gsl_matrix(dim, dim);
      SpindownMetric(metric, time_span);

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
      metric = new_gsl_matrix(dim, dim);
      SpindownMetric(metric, time_span);

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
                   {"fndots", "real,vector"},
                   {"num_fndots", "real,strictpos,vector", []},
                   {"fndot_bands", "real,vector", []},
                   {"ref_time", "real,strictpos,scalar"},
                   {"detectors", "char"},
                   {"ephem_year", "char", "05-09"},
                   {"sky_coords", "char", "equatorial"},
                   {"sky_aligned", "logical", true},
                   {"ptolemaic", "logical", false},
                   []);
      assert(xor(isempty(fndot_bands), isempty(num_fndots)));
      assert(isempty(fndot_bands) || length(fndot_bands) == length(fndots));
      assert(isempty(num_fndots) || length(num_fndots) == length(fndots));

      ## Calculate number of spindowns
      spindowns = length(fndots) - 1;

      ## Create spin-orbit metric
      [sometric, coordIDs] = CreatePhaseMetric("coords", "spin_equ,orbit_ecl,freq,fdots",
                                               "time_span", time_span,
                                               "ref_time", ref_time,
                                               "detectors", detectors,
                                               "spindowns", spindowns,
                                               "ephem_year", ephem_year,
                                               "fiducial_freq", fndots(1),
                                               "ptolemaic", ptolemaic);

      ## Construct super-sky metrics
      ssky_metrics = ConstructSuperSkyMetrics(sometric, coordIDs, sky_coords);
      if sky_aligned
        ssmetric = ssky_metrics.arssmetric;
      else
        ssmetric = ssky_metrics.rssmetric;
      endif

      ## Create tiling
      dim = 4 + spindowns;
      flt = CreateFlatLatticeTiling(dim);

      ## Add sky position bounds
      SetFlatLatticeSuperSkyAllBounds(flt, 0);

      ## Add frequency and spindown bounds
      if !isempty(num_fndots)
        for i = 1:length(fndots)
          SetFlatLatticeBBoxExtentBound(flt, i+2, fndots(i), num_fndots(i));
        endfor
      else
        if isempty(fndot_bands)
          fndot_bands = zeros(size(fndots));
        endif
        for i = 1:length(fndots)
          SetFlatLatticeConstantBound(flt, i+2, fndots(i), fndots(i) + fndot_bands(i));
        endfor
      endif

      ## Set metric
      metric = new_gsl_matrix(dim, dim);
      metric.data = ssmetric;

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
  SetFlatLatticeMetric(flt, metric, max_mismatch);

  ## Fill output struct
  results.metric = metric.data(:,:);
  results.templates = [];
  results.injections = [];
  results.nearest_index = [];
  results.min_mismatch = [];
  results.mismatch_hgrm = newHist(1);

  ## Count number of templates
  results.num_templates = double(CountTotalFlatLatticePoints(flt));

  ## Generate templates, if requested
  if return_points
    results.templates = zeros(dim, results.num_templates);
    for i = 1:results.num_templates
      template = NextFlatLatticePoint(flt);
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
    nearest_template = [];
    nearest_index = [];
    min_mismatch = [];
    workspace = [];

    ## Iterate over injections
    while num_injections > 0

      ## If workspace size is larger than number of
      ## remaining injections, reduce workspace size
      if workspace_size > num_injections
        workspace_size = num_injections;
      endif

      ## Generate injections and find nearest template point
      [injections, nearest_template, nearest_index, min_mismatch, workspace] = ...
          NearestFlatLatticePointToRandomPoints(flt, rng, workspace_size, ...
                                                injections, nearest_template, nearest_index, min_mismatch, workspace);

      ## Add minimum mismatches to histogram
      results.mismatch_hgrm = addDataToHist(results.mismatch_hgrm, min_mismatch.data / max_mismatch, 1.0 / histogram_bins);

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
