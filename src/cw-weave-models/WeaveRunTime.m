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
## @deftypefn {Function File} { [ @var{times}, @var{maxmem}, @var{tau} ] =} WeaveRunTime ( @var{opt}, @var{val}, @dots{} )
##
## Estimate the run time and maximum memory usage of @command{lalapps_Weave}.
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
## @item Ndetectors
## number of detectors
##
## @item ref_time
## GPS reference time
##
## @item start_time
## GPS start time
##
## @item coh_Tspan
## time span of coherent segments
##
## @item semi_Tspan
## total time span of semicoherent search
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
## minimum/maximum frequency range
##
## @item dfreq
## frequency spacing
##
## @item f1dot_min/max
## minimum/maximum 1st spindown
##
## @item f2dot_min/max
## minimum/maximum 2nd spindown (optional)
##
## @item NSFTs
## total number of SFTs
##
## @item Fmethod
## F-statistic method used by search
##
## @item Ncohres
## total number of computed coherent results
##
## @item Nsemitpl
## number of computed semicoherent results
##
## @item cache_max
## maximum size of coherent results cache
##
## @end table
##
## @item stats
## Comma-separated list of statistics being computed
##
## @item TSFT
## Length of an SFT (default: 1800s)
##
## @end table
##
## @heading Outputs
## @itemize
## @item @var{times}.total:
## estimate of total CPU run time (seconds)
##
## @item @var{times}.@samp{field}:
## estimate of CPU time (seconds) to perform action @samp{field};
## see the script itself for further documentation
##
## @item @var{maxmem}.total:
## estimate of maximum total memory usage (MB)
##
## @item @var{maxmem}.@samp{field}:
## estimate of maximum memory usage (MB) of component @samp{field};
## see the script itself for further documentation
##
## @item @var{tau}.@samp{field}:
## fundamental timing constants
##
## @end itemize
##
## @end deftypefn

## octapps_run_link

function [times, maxmem, tau] = WeaveRunTime(varargin)

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"Nsegments", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"Ndetectors", "integer,strictpos,scalar,+exactlyone:setup_file", []},
               {"ref_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"start_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"coh_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"semi_Tspan", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"result_file", "char", []},
               {"freq_min", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"dfreq", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f1dot_min", "real,scalar,+exactlyone:result_file", []},
               {"f1dot_max", "real,scalar,+exactlyone:result_file", []},
               {"f2dot_min", "real,scalar,+atmostone:result_file", 0},
               {"f2dot_max", "real,scalar,+atmostone:result_file", 0},
               {"NSFTs", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Fmethod", "char,+exactlyone:result_file", []},
               {"Ncohres", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"Nsemitpl", "integer,strictpos,scalar,+exactlyone:result_file", []},
               {"cache_max", "integer,strictpos,scalar,+atmostone:result_file", []},
               {"stats", "char"},
               {"TSFT", "integer,strictpos,scalar", 1800},
               []);
  stats = strsplit(stats, ",");

  ## initialise output variables
  times = maxmem = tau = struct;

  ## fundamental timing constants
  tau.iter_psemi                          = 1.36256e-10; ## mean
  tau.query_psemi_pseg                    = 8.55514e-11; ## mean
  tau.semiseg_sum2f_psemi_psegm           = 7.33955e-10; ## mean
  tau.semi_mean2f_psemi                   = 8.28286e-10; ## mean
  tau.output_psemi_ptopl                  = 7.91060e-10; ## mean
  tau.semiseg_max2f_psemi_psegm           = 1.16579e-09; ## mean
  tau.semiseg_max2f_det_psemi_psegm       = 1.12084e-09; ## mean
  tau.semiseg_sum2f_det_psemi_psegm       = 6.85809e-10; ## mean
  tau.semi_log10bsgl_psemi                = 9.89425e-09; ## mean
  tau.semi_log10bsgltl_psemi              = 1.77331e-08; ## mean
  tau.semi_log10btsgltl_psemi             = 1.79320e-08; ## mean
  demod_fstat_tau0_coreld                 = 5.05010e-08; ## mean
  demod_fstat_tau0_bufferld               = 8.61947e-07; ## mean
  resamp_fstat_tau0_fbin                  = 6.97346e-08; ## mean
  resamp_fstat_tau0_spin                  = 6.41612e-08; ## mean
  resamp_fstat_tau0_fft_le18              = 2.51857e-10; ## mean
  resamp_fstat_tau0_fft_gt18              = 4.50738e-10; ## mean
  resamp_fstat_tau0_bary                  = 4.18658e-07; ## mean
  fstat_b                                 = 5.35952e-01; ## mean

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = WeaveReadSetup(setup_file);
    Nsegments  = setup.Nsegments;
    Ndetectors = setup.Ndetectors;
    ref_time   = setup.ref_time;
    start_time = setup.start_time;
    coh_Tspan  = setup.coh_Tspan;
    semi_Tspan = setup.semi_Tspan;
  endif

  ## if given, load result file and extract various parameters
  if !isempty(result_file)
    result = fitsread(result_file);
    result_hdr = result.primary.header;
    freq_min = result_hdr.semiparam_minfreq;
    freq_max = result_hdr.semiparam_maxfreq;
    dfreq = result_hdr.dfreq;
    f1dot_min = result_hdr.semiparam_minf1dot;
    f1dot_max = result_hdr.semiparam_maxf1dot;
    f2dot_min = getoptfield(0, result_hdr, "semiparam_minf2dot");
    f2dot_max = getoptfield(0, result_hdr, "semiparam_maxf2dot");
    NSFTs = result_hdr.nsfts;
    Fmethod = result_hdr.fstat_method;
    Ncohres = result_hdr.ncohres;
    Nsemitpl = result_hdr.nsemitpl;
    cache_max = result_hdr.cachemax;
  endif
  Nsemiseg = Nsemitpl * Nsegments;
  Nsemisegm = Nsemitpl * (Nsegments - 1);
  Nsemitoplists = Nsemitpl * length(stats);

  ## check parameter-space ranges
  assert(freq_max >= freq_min);
  assert(f1dot_max >= f1dot_min);
  assert(f2dot_max >= f2dot_min);

  ## estimate time to iterate over lattice tiling
  time_iter = tau.iter_psemi * Nsemitpl;

  ## estimate time to perform nearest-neighbour lookup queries
  time_query = tau.query_psemi_pseg * Nsemiseg;

  ## estimate coherent F-statistic time and memory usage
  args = struct;
  args.Tcoh = coh_Tspan;
  args.Freq0 = freq_min;
  args.FreqBand = freq_max - freq_min;
  args.dFreq = dfreq;
  args.f1dot0 = f1dot_min;
  args.f1dotBand = f1dot_max - f1dot_min;
  args.f2dot0 = f2dot_min;
  args.f2dotBand = f2dot_max - f2dot_min;
  args.refTimeShift = (ref_time - start_time) / semi_Tspan;
  args.tau0_coreLD = demod_fstat_tau0_coreld;
  args.tau0_bufferLD = demod_fstat_tau0_bufferld;
  args.tau0_Fbin = resamp_fstat_tau0_fbin;
  args.tau0_FFT = [resamp_fstat_tau0_fft_le18, resamp_fstat_tau0_fft_gt18];
  args.tau0_spin = resamp_fstat_tau0_spin;
  args.tau0_bary = resamp_fstat_tau0_bary;
  args.Nsft = NSFTs / (Nsegments * Ndetectors);
  args.Tsft = TSFT;
  [resamp_info, demod_info] = fevalstruct(@predictFstatTimeAndMemory, args);
  if strncmpi(Fmethod, "Resamp", 6)
    tau.Fstat = resamp_info.tauF_core + fstat_b * resamp_info.tauF_buffer;
    maxmem.Fstat = resamp_info.MBWorkspace + resamp_info.MBDataPerDetSeg * Ndetectors * Nsegments;
  elseif strncmpi(Fmethod, "Demod", 5)
    tau.Fstat = demod_info.tauF_core + fstat_b * demod_info.tauF_buffer;
    maxmem.Fstat = demod_info.MBDataPerDetSeg * Ndetectors * Nsegments;
  else
    error("%s: unknown F-statistic method '%s'", funcName, Fmethod);
  endif

  ## estimate time to compute coherent F-statistics
  time_coh2F = tau.Fstat * Ndetectors * Ncohres;

  ## estimate time to compute semicoherent F-statistics
  time_sum2F = tau.semiseg_sum2f_psemi_psegm * Nsemisegm;
  time_sum2F_det = tau.semiseg_sum2f_det_psemi_psegm * Nsemisegm;
  time_max2F = tau.semiseg_max2f_psemi_psegm * Nsemisegm;
  time_max2F_det = tau.semiseg_max2f_det_psemi_psegm * Nsemisegm;
  time_mean2F = tau.semi_mean2f_psemi * Nsemitpl;

  ## estimate time to compute line-robust statistics
  time_log10BSGL = tau.semi_log10bsgl_psemi * Nsemitpl;
  time_log10BSGLtL = tau.semi_log10bsgltl_psemi * Nsemitpl;
  time_log10BtSGLtL = tau.semi_log10btsgltl_psemi * Nsemitpl;

  ## estimate time to output results
  time_output = tau.output_psemi_ptopl * Nsemitoplists;

  ## fill in times struct based on requested statistics
  times.iter = time_iter;
  times.query = time_query;
  for i = 1:length(stats)
    switch stats{i}
      case "sum2F"
        times.coh_coh2f = time_coh2F;
        times.semiseg_sum2f = time_sum2F;
      case "mean2F"
        times.coh_coh2f = time_coh2F;
        times.semiseg_sum2f = time_sum2F;
        times.semi_mean2f = time_mean2F;
      case "log10BSGL"
        times.coh_coh2f = time_coh2F;
        times.semiseg_sum2f = time_sum2F;
        times.semiseg_sum2f_det = time_sum2F_det * Ndetectors;
        times.semi_log10bsgl = time_log10BSGL;
      case "log10BSGLtL"
        times.coh_coh2f = time_coh2F;
        times.semiseg_sum2f = time_sum2F;
        times.semiseg_sum2f_det = time_sum2F_det * Ndetectors;
        times.semiseg_max2f = time_max2F;
        times.semiseg_max2f_det = time_max2F_det * Ndetectors;
        times.semi_log10bsgltl = time_log10BSGLtL;
      case "log10BtSGLtL"
        times.coh_coh2f = time_coh2F;
        times.semiseg_sum2f = time_sum2F;
        times.semiseg_sum2f_det = time_sum2F_det * Ndetectors;
        times.semiseg_max2f = time_max2F;
        times.semiseg_max2f_det = time_max2F_det * Ndetectors;
        times.semi_log10btsgltl = time_log10BtSGLtL;
      otherwise
        error("%s: invalid statistic '%s'", funcName, stats{i});
    endswitch
  endfor
  times.output = time_output;

  ## estimate total run time
  times.total = sum(structfun(@sum, times));

  if !isempty(cache_max)

    ## estimate maximum memory usage of components
    MB = 1024 * 1024;
    mem_cache_pbin = struct;
    for i = 1:length(stats)
      switch stats{i}
        case "sum2F"
          mem_cache_pbin.coh2F = 4;
        case "mean2F"
          mem_cache_pbin.coh2F = 4;
        case "log10BSGL"
          mem_cache_pbin.coh2F = 4;
          mem_cache_pbin.coh2F_det = 4 * Ndetectors;
        case "log10BSGLtL"
          mem_cache_pbin.coh2F = 4;
          mem_cache_pbin.coh2F_det = 4 * Ndetectors;
        case "log10BtSGLtL"
          mem_cache_pbin.coh2F = 4;
          mem_cache_pbin.coh2F_det = 4 * Ndetectors;
        otherwise
          error("%s: invalid statistic '%s'", funcName, stats{i});
      endswitch
    endfor
    mem_cache_pbin = sum(structfun(@sum, mem_cache_pbin));
    mem_cache_bins = (freq_max - freq_min) / dfreq;
    maxmem.cache = cache_max * mem_cache_bins * mem_cache_pbin / MB;

    ## estimate maximum total memory usage
    maxmem.total = sum(structfun(@sum, maxmem));

  endif

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
%!  args.stats = "sum2F,mean2F,log10BSGL,log10BSGLtL,log10BtSGLtL";
%!  [times, maxmem, tau] = fevalstruct(@WeaveRunTime, args);
%!  assert(times.total > 0);
%!  assert(maxmem.total > 0);
%!  assert(all(structfun(@(t) t > 0, tau)));
