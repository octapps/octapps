## Copyright (C) 2017 Karl Wette
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
## @deftypefn {Function File} {@var{cost_funs} =} CostFunctionsWeave ( @var{opt}, @var{val}, @dots{} )
##
## Cost function for @command{lalapps_Weave} for use with OptimalSolution4StackSlide_v2
##
## @heading Arguments
##
## @table @var
## @item cost_funs
## cost functions struct
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
## @item detectors
## Comma-separated list of detectors
##
## @item ref_time
## GPS reference time
##
## @item start_time
## GPS start time
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
## @item freq_min/max
## Minimum/maximum frequency range
##
## @item f1dot_min/max
## Minimum/maximum 1st spindown
##
## @item f2dot_min/max
## Minimum/maximum 2nd spindown (optional)
##
## @item NSFTs
## total number of SFTs
##
## @item Fmethod
## F-statistic method used by search
##
## @end table
##
## @item stats
## Comma-separated list of statistics being computed
##
## @item lattice
## Type of @var{lattice} to use (default: Ans)
##
## @item grid_interpolation
## If true, compute cost of interpolating search (i.e. semicoherent
## grid interpolates results on coherent grids)
## If false, compute cost of noninterpolating search (i.e. identical
## coherent and semicoherent grids)
##
## @item TSFT
## Length of an SFT (default: 1800s)
##
## @end table
##
## @end deftypefn

function cost_funs = CostFunctionsWeave(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"detectors", "char,+exactlyone:setup_file", []},
               {"ref_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"start_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"semi_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"result_file", "char", []},
               {"sky_area", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_min", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f1dot_min", "real,scalar,+exactlyone:result_file", []},
               {"f1dot_max", "real,scalar,+exactlyone:result_file", []},
               {"f2dot_min", "real,scalar,+atmostone:result_file", 0},
               {"f2dot_max", "real,scalar,+atmostone:result_file", 0},
               {"NSFTs", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Fmethod", "char,+exactlyone:result_file", []},
               {"stats", "char"},
               {"lattice", "char", "Ans"},
               {"grid_interpolation", "logical,scalar", true},
               {"TSFT", "integer,strictpos,scalar", 1800},
               []);

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = WeaveReadSetup(setup_file);
    detectors  = strjoin(setup.detectors,",");
    ref_time   = setup.ref_time;
    start_time = setup.start_time;
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
    NSFTs = result_hdr.nsfts;
    Fmethod = result_hdr.fstat_method;
  endif

  ## arguments for computing number of templates
  template_count_args = struct;
  template_count_args.detectors = detectors;
  template_count_args.ref_time = ref_time;
  template_count_args.semi_Tspan = semi_Tspan;
  template_count_args.sky_area = sky_area;
  template_count_args.freq_min = freq_min;
  template_count_args.freq_max = freq_max;
  template_count_args.f1dot_min = f1dot_min;
  template_count_args.f1dot_max = f1dot_max;
  template_count_args.f2dot_min = f2dot_min;
  template_count_args.f2dot_max = f2dot_max;
  template_count_args.lattice = lattice;

  ## arguments for computing run time
  run_time_args = struct;
  run_time_args.Ndetectors = length(strsplit(detectors, ","));
  run_time_args.ref_time = ref_time;
  run_time_args.start_time = start_time;
  run_time_args.semi_Tspan = semi_Tspan;
  run_time_args.freq_min = freq_min;
  run_time_args.freq_max = freq_max;
  run_time_args.f1dot_min = f1dot_min;
  run_time_args.f1dot_max = f1dot_max;
  run_time_args.f2dot_min = f2dot_min;
  run_time_args.f2dot_max = f2dot_max;
  run_time_args.NSFTs = NSFTs;
  run_time_args.Fmethod = Fmethod;
  run_time_args.stats = stats;
  run_time_args.TSFT = TSFT;

  ## return cost functions for use with OptimalSolution4StackSlide_v2
  cost_funs = struct( ...
                      "grid_interpolation", grid_interpolation, ...
                      "lattice", lattice, ...
                      "f", @(Nseg, Tseg, mCoh=0.5, mInc=0.5) weave_cost_function(Nseg, Tseg, mCoh, mInc, template_count_args, run_time_args) ...
                    );

endfunction

function [costCoh, costInc] = weave_cost_function(Nseg, Tseg, mCoh, mInc, template_count_args, run_time_args)

  [err, Nseg, Tseg, mCoh, mInc] = common_size ( Nseg, Tseg, mCoh, mInc );
  assert ( err == 0 );

  costCoh = costInc = zeros ( size ( Nseg ) );

  for i = 1 : numel(Nseg)

    ## compute number of templates
    template_count_args.Nsegments = Nseg(i);
    template_count_args.coh_Tspan = Tseg(i);
    template_count_args.coh_max_mismatch = mCoh(i);
    template_count_args.semi_max_mismatch = mInc(i);
    [coh_Nt, semi_Nt, dfreq] = fevalstruct(@WeaveTemplateCount, template_count_args);

    ## compute total cost
    run_time_args.Nsegments = round ( Nseg(i) );
    run_time_args.coh_Tspan = Tseg(i);
    run_time_args.dfreq = dfreq;
    run_time_args.Ncohres = coh_Nt;
    run_time_args.Nsemitpl = semi_Nt;
    costs = fevalstruct(@WeaveRunTime, run_time_args);

    ## split into coherent and incoherent costs
    costCoh_i = costInc_i = 0;
    for [cost, cost_name] = costs
      if strncmp(cost_name, "coh", 3)
        costCoh_i += cost;
      elseif strncmp(cost_name, "semi", 4)
        costInc_i += cost;
      endif
    endfor

    costCoh(i) = costCoh_i;
    costInc(i) = costInc_i;
  endfor

endfunction

%!test disp("to test CostFunctionsWeave(), run the WeaveSensDepth() test(s)")
