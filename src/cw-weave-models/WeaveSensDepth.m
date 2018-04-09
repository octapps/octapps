## Copyright (C) 2017 Karl Wette
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
## @deftypefn {Function File} {@var{depth} =} WeaveSensDepth ( @var{opt}, @var{val}, @dots{} )
##
## Estimate the sensitivity depth of @command{lalapps_Weave}.
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
## number of segments
##
## @item detectors
## comma-separated list of detectors
##
## @item coh_Tspan
## time span of coherent segments
##
## @item semi_Tspan
## total time span of semicoherent search
##
## @end table
##
## @item alpha
## @itemx delta
## If not searching over sky parameters, give sky point of
## search (default: all-sky)
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
## @item NSFTs
## total number of SFTs used by search
##
## @item pFD
## false dismissal probability of search
##
## @item @strong{EITHER}
## @table @code
##
## @item pFA
## false alarm probability of search
##
## @item semi_ntmpl
## number of semicoherent templates used by search
##
## @end table
##
## @item @strong{OR}
## @table @code
##
## @item mean2F_th
## threshold on mean 2F
##
## @item TSFT
## Time span of a single SFT (default: 1800 seconds)
##
## @end table
##
## @end table
##
## @heading Outputs
## @table @var
## @item depth
## estimated sensitivity depth
##
## @item mismatch_hgrm
## mismatch histogram
##
## @end table
##
## @end deftypefn

## octapps_run_link

function [depth, mismatch_hgrm] = WeaveSensDepth(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"detectors", "char,+exactlyone:setup_file", []},
               {"Nsegments", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"coh_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"semi_Tspan", "real,strictpos,scalar,+exactlyone:setup_file,+noneorall:coh_Tspan", []},
               {"alpha", "real,vector", []},
               {"delta", "real,vector,+noneorall:alpha", []},
               {"spindowns", "integer,positive,scalar"},
               {"lattice", "char", "Ans"},
               {"coh_max_mismatch", "real,positive,scalar"},
               {"semi_max_mismatch", "real,positive,scalar"},
               {"NSFTs", "integer,strictpos,scalar"},
               {"pFD", "real,strictpos,column", 0.1},
               {"pFA", "real,strictpos,column,+exactlyone:mean2F_th", []},
               {"semi_ntmpl", "real,strictpos,column,+exactlyone:mean2F_th,+noneorall:pFA", []},
               {"mean2F_th", "real,strictpos,column", []},
               {"TSFT", "integer,strictpos,scalar", 1800},
               []);

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = WeaveReadSetup(setup_file);
    Nsegments  = setup.Nsegments;
    detectors  = strjoin(setup.detectors,",");
    coh_Tspan  = setup.coh_Tspan;
    semi_Tspan = setup.semi_Tspan;
  endif

  ## get mismatch histogram
  args = struct;
  if !isempty(setup_file)
    args.setup_file = setup_file;
  else
    args.coh_Tspan = coh_Tspan;
    args.semi_Tspan = semi_Tspan;
  endif
  args.sky = isempty(alpha);
  args.spindowns = spindowns;
  args.lattice = lattice;
  args.coh_max_mismatch = coh_max_mismatch;
  args.semi_max_mismatch = semi_max_mismatch;
  mismatch_hgrm = fevalstruct(@WeaveFstatMismatch, args);

  ## calculate sensitivity
  args = struct;
  args.Nseg = Nsegments;
  args.Tdata = NSFTs * TSFT;
  args.misHist = mismatch_hgrm;
  args.detectors = detectors;
  args.pFD = pFD;
  if !isempty(pFA)
    args.pFA = pFA ./ semi_ntmpl;
  else
    args.avg2Fth = mean2F_th;
  endif
  if !isempty(alpha)
    args.alpha = alpha;
    args.delta = delta;
  endif
  depth = fevalstruct(@SensitivityDepthStackSlide, args);

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
%!  args.NSFTs = results.primary.header.nsfts;
%!  args.pFA = 0.01;
%!  args.semi_ntmpl = results.primary.header.nsemitpl;
%!  depth = fevalstruct(@WeaveSensDepth, args);
%!  assert(depth, 29.573, 0.1);
