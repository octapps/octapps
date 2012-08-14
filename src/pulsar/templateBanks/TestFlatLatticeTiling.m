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
##   mismatch_hgrm = TestFlatLatticeTiling(...)
## Options:
##   tiling: type of tiling to generate.
##     Options are:
##       "eye": generate a tiling using the identity metric.
##         Requires options:
##           square: list of bounds to place on parameter space
##       "spin": generate a tiling using CW spindown metric.
##         Requires options:
##           square: list of frequency, spindown, etc. bounds
##           Tspan: observation time-span
##   lattice: type of lattice to use.
##     Options are:
##       "Zn": n-dimensional hypercubic lattice
##       "Ans": n-dimensional An* lattice
##   num_injections: if >0, number of injection points to test with
##   wksp_size: size of workspace for computing min. mismatch

function mismatch_hgrm = TestFlatLatticeTiling(varargin)

  ## Parse options
  opts = parseOptions(varargin,
                      {"tiling", "char"},
                      {"square", "numeric,vector", []},
                      {"Tspan", "numeric,scalar", 0},
                      {"lattice", "char"},
                      {"num_injections", "numeric,scalar"},
                      {"wksp_size", "numeric,scalar", 1000},
                      []);

  ## Load LAL libraries
  lal;
  lalpulsar;

  ## Create tiling, set up parameter space and metric
  switch tiling

    case "eye"   ## Identity metric and square parameter space

      ## Check input
      if length(square) == 0
        error("%s: 'square' must have length > 0 for tiling='eye'", funcName);
      endif
      dim = length(square);

      ## Create tiling
      flt = CreateFlatLatticeTiling(dim);

      ## Add bounds
      for i = 1:dim
        AddFlatLatticeConstantBound(flt, 0, square(i));
      endfor

      ## Create metric
      metric = new_gsl_matrix(dim, dim);
      metric.data = eye(dim);

    case "spin"   ## CW spindown metric and square parameter space

      ## Check input
      if length(square) == 0
        error("%s: 'square' must have length > 0 for tiling='spin'", funcName);
      endif
      dim = length(square);
      if Tspan <= 0
        error("%s: Tspan must be strictly positive for tiling='spin'", funcName);
      endif

      ## Create tiling
      flt = CreateFlatLatticeTiling(dim);

      ## Add bounds
      for i = 1:dim
        bounds = [0, square(i)];
        AddFlatLatticeConstantBound(flt, min(bounds), max(bounds));
      endfor

      ## Create metric
      metric = SpindownMetric(dim, Tspan);

    otherwise
      error("%s: unknown tiling '%s'", funcName, tiling);

  endswitch

  ## Set metric
  SetFlatLatticeMetric(flt, metric, 1.0);

  ## Set lattice generator
  switch lattice
    case "Zn"
      SetFlatLatticeGenerator(flt, CubicLatticeGeneratorPtr);
    case "Ans"
      SetFlatLatticeGenerator(flt, AnstarLatticeGeneratorPtr);
    otherwise
      error("%s: unknown lattice '%s'", funcName, lattice);
  endswitch

  if num_injections > 0

    ## Create mismatch histogram
    mismatch_hgrm = newHist(1);

    ## Create injection workspace
    wksp = CreateNearestTemplateWorkspace(metric, wksp_size, wksp_size);

    ## Create random number generator
    randpar = CreateRandomParams(floor(rand() * (2^31 - 1)));

    ## Create matrices for storing templates and injections
    injections = new_gsl_matrix(dim, wksp_size);
    templates = new_gsl_matrix(dim, wksp_size);

    ## Create vectors for storing minimum distance, and index of nearest template
    min_mismatch = new_gsl_vector(wksp_size);
    nearest_template = new_gsl_vector_uint(wksp_size);

    ## Round number of injections up to workspace size
    injection_iter = ceil(num_injections / wksp_size);
    while injection_iter-- > 0

      ## Restart tiling
      RestartFlatLatticeTiling(flt);

      ## Generate injections
      GenerateRandomFlatLatticePoints(flt, randpar, injections);

      ## Update workspace with injections
      UpdateWorkspaceInjections(wksp, injections, min_mismatch);

      ## Iterate over template bank
      while 1

        ## Generate templates
        if NextFlatLatticePoints(flt, templates, true) == 0
          break
        endif

        ## Update workspace with injections
        UpdateWorkspaceTemplates(wksp, templates, nearest_template);

        ## Update minimum mismatch and nearest template
        UpdateNearestTemplateToInjections(wksp, min_mismatch, nearest_template);

      endwhile

      ## Add minimum mismatches to histogram
      mismatch_hgrm = addDataToHist(mismatch_hgrm, min_mismatch.data, 0.01);

    endwhile

  endif

endfunction
