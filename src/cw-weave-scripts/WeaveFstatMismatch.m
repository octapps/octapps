## Copyright (C) 2016 Karl Wette
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

## Estimate the F-statistic mismatch distribution of 'lalapps_Weave'.
## Usage:
##   hgrm = WeaveFstatMismatch("opt", val, ...)
##   octapps_run WeaveFstatMismatch --opt=val ...
## Options:
##   setup_file:
##     Weave setup file, from which to extract segment list
##   coh_Tspan,semi_Tspan:
##     Alternatives to 'setup_file'; give time span of coherent
##     segments, and total time span of semicoherent search
##   spindowns:
##     Number of spindown parameters being searched
##   lattice:
##     Type of lattice used by search (default: Ans)
##   coh_max_mismatch,semi_max_mismatch:
##     Maximum coherent and semicoherent mismatches; for a single-
##     segment or non-interpolating search, set coh_max_mismatch=0
##   output:
##     if given, print various information to screen:
##       output=mean: mean F-statistic mismatch
##       output=stdv: standard deviation of F-statistic mismatch
##       output=hist: ASCII table of F-statistic mismatch histogram

function varargout = WeaveFstatMismatch(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"coh_Tspan", "real,strictpos,scalar", []},
               {"semi_Tspan", "real,strictpos,scalar", []},
               {"spindowns", "integer,positive,scalar"},
               {"lattice", "char", "Ans"},
               {"coh_max_mismatch", "real,positive,scalar"},
               {"semi_max_mismatch", "real,positive,scalar"},
               {"output", "char", []},
               []);
  assert(xor(!isempty(setup_file), !isempty(coh_Tspan)), "'setup_file' and 'coh_Tspan' are mutually exclusive");
  assert(xor(!isempty(setup_file), !isempty(semi_Tspan)), "'setup_file' and 'semi_Tspan' are mutually exclusive");
  assert(!or(!isempty(coh_Tspan), !isempty(semi_Tspan)), "'coh_Tspan' and 'semi_Tspan' are mutually required");

  ## if given, load setup file and extract coherent and semicoherent time spans
  if !isempty(setup_file)
    setup = fitsread(setup_file);
    assert(isfield(setup, "segments"));
    segs = setup.segments.data;
    segment_list = [ [segs.start_s] + 1e-9*[segs.start_ns]; [segs.end_s] + 1e-9*[segs.end_ns] ]';
    segment_props = AnalyseSegmentList(segment_list);
    coh_Tspan = segment_props.coh_mean_Tspan;
    semi_Tspan = segment_props.inc_Tspan;
  endif

  ## dimensionality of search parameter space: 2 sky + 1 frequency + spindowns
  dim = 3 + spindowns;

  ## get the lattice histogram for the given dimensionality and type
  lattice_hgrm = LatticeMismatchHist(dim, lattice);

  ## compute the mean and standard deviation of the coherent mismatch distribution
  coh_mean_mismatch = coh_max_mismatch * meanOfHist(lattice_hgrm);
  coh_stdv_mismatch = coh_max_mismatch * stdvOfHist(lattice_hgrm);

  ## compute the mean and standard deviation of the semicoherent mismatch distribution
  semi_mean_mismatch = semi_max_mismatch * meanOfHist(lattice_hgrm);
  semi_stdv_mismatch = semi_max_mismatch * stdvOfHist(lattice_hgrm);

  ## compute the mean and standard deviation of the F-statistic mismatch distribution
  [mean_twoF, stdv_twoF] = EmpiricalFstatMismatch(coh_Tspan, semi_Tspan, coh_mean_mismatch, semi_mean_mismatch, coh_stdv_mismatch, semi_stdv_mismatch);

  ## create a Gaussian histogram with the required mean and standard deviation
  hgrm = createGaussianHist(mean_twoF, stdv_twoF, "binsize", 0.01, "domain", [0, 1]);

  ## either return histogram (Octave usage) or print histogram properties (command line usage)
  switch output
    case ""
      varargout = {hgrm};
    case "mean"
      printf("%0.4g\n", meanOfHist(hgrm));
    case "stdv"
      printf("%0.4e\n", stdvOfHist(hgrm));
    case "hist"
      hgrm = restrictHist(thresholdHist(hgrm, 1e-3));
      mu = histBins(hgrm, 1, "finite", "centre");
      p = histProbs(hgrm, "finite");
      assert(length(mu) == length(p));
      printf("%0.4g %0.4g\n", [mu(:)'; p(:)']);
    otherwise
      error("unknown option 'output=%s'", output);
  endswitch

endfunction
