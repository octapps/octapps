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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{hgrm} =} WeaveFstatMismatch ( @var{opt}, @var{val}, @dots{} )
##
## Estimate the F-statistic mismatch distribution of @command{lalapps_Weave}.
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
## @item coh_Tspan
## time span of coherent segments
##
## @item semi_Tspan
## total time span of semicoherent search
##
## @end table
##
## @item sky
## Whether to include search over @var{sky} parameters (default: true)
##
## @item spindowns
## Number of spindown parameters being searched
##
## @item lattice
## Type of @var{lattice} used by search (default: Ans)
##
## @item coh_max_mismatch
## @itemx semi_max_mismatch
## Maximum coherent and semicoherent mismatches; for a single-
## segment or non-interpolating search, set @var{coh_max_mismatch}=0
##
## @end table
##
## @heading Outputs
##
## @table @var
## @item hgrm
## Histogram of F-statistic mismatch distribution
##
## @end table
##
## @end deftypefn

## octapps_run_link

function hgrm = WeaveFstatMismatch(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"coh_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"semi_Tspan", "real,strictpos,scalar,+exactlyone:setup_file,+noneorall:coh_Tspan", []},
               {"sky", "logical,scalar", true},
               {"spindowns", "integer,positive,scalar"},
               {"lattice", "char", "Ans"},
               {"coh_max_mismatch", "real,positive,scalar"},
               {"semi_max_mismatch", "real,positive,scalar"},
               []);

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = WeaveReadSetup(setup_file);
    coh_Tspan  = setup.coh_Tspan;
    semi_Tspan = setup.semi_Tspan;
  endif

  ## dimensionality of search parameter space: 2 sky + 1 frequency + spindowns
  dim = ifelse(sky, 2, 0) + 1 + spindowns;

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
%!  args.spindowns = results.primary.header.nspins;
%!  args.coh_max_mismatch = str2double(results.primary.header.progarg_coh_max_mismatch);
%!  args.semi_max_mismatch = str2double(results.primary.header.progarg_semi_max_mismatch);
%!  hgrm = fevalstruct(@WeaveFstatMismatch, args);
%!  assert(meanOfHist(hgrm), 0.0876, 1e-3);
