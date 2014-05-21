## Copyright (C) 2012, 2014 Karl Wette
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

## Test the LALSuite LatticeTiling algorithm.
## Usage:
##   results = TestLatticeTiling("opt", val, ...)
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
##   lattice: type of lattice to use.
##     Options:
##       "Zn": n-dimensional hypercubic lattice
##       "Ans": n-dimensional An* lattice
##   max_mismatch: maximum prescribed mismatch
##   num_injections: number of injection points to test with
##      if < 0, use as a ratio of number of generated templates
##   workspace_size: size of workspace for computing mismatch histogram
##   detailed: return more detailed information (default: false)
##   histogram_bins: number of bins to use in mismatch histogram

function res = TestLatticeTiling(varargin)

  ## Load LAL libraries
  lal;
  lalpulsar;

  ## Parse options
  parseOptions(varargin,
               {"tiling", "cell,vector"},
               {"lattice", "char"},
               {"max_mismatch", "real,strictpos,scalar"},
               {"num_injections", "real,scalar", 0},
               {"workspace_size", "real,scalar", 2000},
               {"detailed", "logical,scalar", false},
               {"histogram_bins", "integer,strictpos,scalar", 100},
               []);

  ## Check input
  if !ischar(tiling{1})
    error("%s: first argument to 'tiling' must be a string", funcName);
  endif

  ## Create output struct
  res = struct;

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
      latt = CreateLatticeTiling(dim);

      ## Add square bounds
      for i = 1:length(bounds)
        SetLatticeConstantBound(latt, i-1, 0, bounds(i));
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
      latt = CreateLatticeTiling(dim);

      ## Add elliptical bounds
      SetLatticeEllipticalBounds(latt, 0, 0.0, 0.0, semis(1), semis(2));

      ## Add square bounds
      for i = 1:length(bounds)
        SetLatticeConstantBound(latt, i+1, 0.0, bounds(i));
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
      latt = CreateLatticeTiling(dim);

      ## Add frequency and spindown bounds
      if isempty(fndot_bands)
        fndot_bands = zeros(size(fndot));
      endif
      for i = 1:length(fndot)
        SetLatticeConstantBound(latt, i-1, fndot(i), fndot(i) + fndot_bands(i));
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
      latt = CreateLatticeTiling(dim);

      ## Create frequency metric
      gslmetric = new_gsl_matrix(dim, dim);
      SpindownMetric(gslmetric, time_span);

      ## Add frequency bound
      SetLatticeConstantBound(latt, 0, freq, freq + freq_band);

      ## Add first spindown age-braking index bound
      SetLatticeF1DotAgeBrakingBound(latt, 0, 1, age, min(f1dot_brake), max(f1dot_brake));

      ## Add second spindown braking index bound
      SetLatticeF2DotBrakingBound(latt, 0, 1, 2, min(f2dot_brake), max(f2dot_brake));

    otherwise
      error("%s: unknown tiling '%s'", funcName, tiling{1});

  endswitch

  ## Set lattice generator
  res.lattice = lattice;
  switch lattice
    case "Zn"
      lattice_type = LATTICE_TYPE_CUBIC;
    case "Ans"
      lattice_type = LATTICE_TYPE_ANSTAR;
    otherwise
      error("%s: unknown lattice '%s'", funcName, lattice);
  endswitch

  ## Set metric
  res.metric = gslmetric.data(:,:);
  res.max_mismatch = max_mismatch;
  SetLatticeTypeAndMetric(latt, lattice_type, gslmetric, max_mismatch);

  ## Save number of dimensions
  res.dim = GetLatticeTotalDimensions(latt);
  res.tiled_dim = GetLatticeTiledDimensions(latt);

  ## Build lookup table required by NearestLatticePoints(), if required
  if num_injections != 0 || detailed
    BuildLatticeIndexLookup(latt);
  endif

  ## Count number of templates
  res.num_templates = double(CountLatticePoints(latt));

  ## Generate templates, and return if requested
  templates = zeros(dim, res.num_templates);
  template = new_gsl_vector(dim);
  for i = 1:res.num_templates
    NextLatticePoint(latt, template);
    assert(GetLatticePointCount(latt) == i);
    templates(:, i) = template.data(:);
  endfor
  if detailed
    res.templates = templates;
  endif

  ## Return indices of all templates, if requested
  if detailed

    ## Initialise arguments for NearestLatticePoints()
    templ_matrix = new_gsl_matrix(dim, res.num_templates);
    templ_matrix.data = templates;
    wksp_matrix = new_gsl_matrix(dim, res.num_templates);
    nearest_idx_vector = CreateUINT8Vector(res.num_templates);

    ## Find the nearest lattice points to each template, which should be the
    ## template itself, hence 'template_indices' should be 1:res.num_templates
    NearestLatticePoints(latt, templ_matrix, wksp_matrix, nearest_idx_vector);
    res.template_indices = 1 + reshape(double(nearest_idx_vector.data), 1, []);

    ## Cleanup
    clear templ_matrix wksp_matrix nearest_idx_vector;

  endif

  if num_injections != 0

    ## If number of injections is negative, treat as ratio of number of generated templates
    if num_injections < 0
      num_injections = abs(num_injections) * res.num_templates;
    endif

    ## Adjust number of injections and workspace size
    num_injections = ceil(num_injections);
    workspace_size = min(workspace_size, num_injections);
    num_injection_blocks = ceil(num_injections / workspace_size);
    res.num_injections = num_injection_blocks * workspace_size;

    ## Create random number generator
    rng = CreateRandomParams(floor(rand() * (2^31 - 1)));

    ## Initialise arguments for RandomLatticePoints() and NearestLatticePoints()
    injections = new_gsl_matrix(dim, workspace_size);
    nearest_templates = new_gsl_matrix(dim, workspace_size);
    nearest_idx_vector = CreateUINT8Vector(workspace_size);

    ## Return injections, nearest templates and their mismatch, if requested
    if detailed
      res.injections = zeros(dim, res.num_injections);
      res.nearest_templates = zeros(dim, res.num_injections);
      res.nearest_mismatch = zeros(1, res.num_injections);
      res.nearest_indices = zeros(1, res.num_injections);
      res.index_mismatch = zeros(1, res.num_injections);
    endif

    ## Create mismatch histograms
    res.mismatch_hgrm = Hist(1, {"lin", "dbin", 1.0 / histogram_bins});
    res.index_mismatch_hgrm = Hist(1, {"lin", "dbin", 1.0 / histogram_bins});

    ## Iterate over injections
    for j = 1:num_injection_blocks

      ## Generate random points
      RandomLatticePoints(latt, rng, injections);

      ## Find nearest lattice points
      NearestLatticePoints(latt, injections, nearest_templates, nearest_idx_vector);
      nearest_indices = 1 + reshape(double(nearest_idx_vector.data), 1, []);

      ## Compute mismatches betwen injections and nearest templates, and add to histogram
      dx = injections.data - nearest_templates.data;
      nearest_mismatch = dot(dx, res.metric * dx, 1) / max_mismatch;
      res.mismatch_hgrm = addDataToHist(res.mismatch_hgrm, nearest_mismatch(:));

      ## Compute mismatch between the returned nearest templates, and the
      ## templates indexed by the nearest indices, and add to histogram
      dx = templates(:, nearest_indices) - nearest_templates.data;
      index_mismatch = dot(dx, res.metric * dx, 1) / max_mismatch;
      res.index_mismatch_hgrm = addDataToHist(res.index_mismatch_hgrm, index_mismatch(:));

      ## Return injections, nearest templates and their mismatch, if requested
      if detailed
        jj = (j-1)*workspace_size + (1:workspace_size);
        res.injections(:, jj) = injections.data;
        res.nearest_templates(:, jj) = nearest_templates.data;
        res.nearest_mismatch(jj) = nearest_mismatch;
        res.nearest_indices(jj) = nearest_indices;
        res.index_mismatch(jj) = index_mismatch;
      endif

    endfor

    ## Cleanup
    clear injections nearest_templates nearest_idx_vector;

  endif

endfunction
