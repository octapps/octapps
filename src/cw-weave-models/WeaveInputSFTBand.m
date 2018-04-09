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
## @deftypefn {Function File} { [ @var{SFT_freq_min}, @var{SFT_freq_max} ] =} WeaveInputSFTBand ( @var{opt}, @var{val}, @dots{} )
##
## Estimate the input SFT band required by @command{lalapps_Weave}
##
## @heading Arguments
##
## @table @var
## @item SFT_freq_min/max
## Minimum/maximum SFT frequency range
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
## @item segment_list
## Segment list
##
## @item ref_time
## GPS reference time
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
## @end table
##
## @item TSFT
## Length of an SFT (default: 1800s)
##
## @item Dterms
## Number of Dirichlet terms used by the F-statistic (default: 8)
##
## @item run_med_win
## Size of running median window used by the F-statistic (default: 101)
##
## @end table
##
## @end deftypefn

## octapps_run_link

function [SFT_freq_min, SFT_freq_max] = WeaveInputSFTBand(varargin)

  ## load constants
  UnitsConstants;

  ## parse options
  parseOptions(varargin,
               {"setup_file", "char", []},
               {"segment_list", "real,strictpos,matrix,cols:2,+exactlyone:setup_file", []},
               {"ref_time", "real,strictpos,scalar,+exactlyone:setup_file", []},
               {"result_file", "char", []},
               {"freq_min", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"freq_max", "real,strictpos,scalar,+exactlyone:result_file", []},
               {"f1dot_min", "real,scalar,+exactlyone:result_file", []},
               {"f1dot_max", "real,scalar,+exactlyone:result_file", []},
               {"f2dot_min", "real,scalar,+atmostone:result_file", 0},
               {"f2dot_max", "real,scalar,+atmostone:result_file", 0},
               {"TSFT", "integer,strictpos,scalar", 1800},
               {"Dterms", "integer,strictpos,scalar", 8},
               {"run_med_win", "integer,strictpos,scalar", 101},
               []);

  ## if given, load setup file and extract various parameters
  if !isempty(setup_file)
    setup = WeaveReadSetup(setup_file);
    segment_list = setup.segment_list;
    ref_time = setup.ref_time;
  endif

  ## if given, load result file and extract various parameters
  if !isempty(result_file)
    result = fitsread(result_file);
    result_hdr = result.primary.header;
    freq_min = result_hdr.semiparam_minfreq;
    freq_max = result_hdr.semiparam_maxfreq;
    f1dot_min = result_hdr.semiparam_minf1dot;
    f1dot_max = result_hdr.semiparam_maxf1dot;
    f2dot_min = getoptfield(0, result_hdr, "semiparam_minf2dot");
    f2dot_max = getoptfield(0, result_hdr, "semiparam_maxf2dot");
  endif

  ## enlarge frequency and spindown ranges to include supersky metric coordinate changes
  freq_min -= 1e-3 * freq_min;
  freq_max += 1e-3 * freq_max;
  f1dot_min -= 1e-10 * freq_min;
  f1dot_max += 1e-10 * freq_max;

  ## find range of frequencies covering segment list
  t = [segment_list(:, 1) - ref_time; segment_list(:, 2) - ref_time + TSFT];
  SFT_freq_min = min(freq_min + f1dot_min.*t + 0.5.*f2dot_min.*t.^2);
  SFT_freq_max = max(freq_max + f1dot_max.*t + 0.5.*f2dot_max.*t.^2);

  ## enlarge frequency band to account for detector motion
  ## - maximum value of the time derivative of the diurnal and (Ptolemaic) orbital phase, plus 5% for luck
  det_motion_per_freq = 1.05 * 2*pi / C_SI * ( (AU_SI/YRSID_SI) + (REARTH_SI/DAYSID_SI) );
  SFT_freq_min *= (1 - det_motion_per_freq);
  SFT_freq_max *= (1 + det_motion_per_freq);

  ## enlarge frequency band to account for extra bins read for D-terms / running median window
  extra_bins_freq = ceil(Dterms + 0.5*run_med_win + 1) / TSFT;
  SFT_freq_min += extra_bins_freq;
  SFT_freq_max -= extra_bins_freq;

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
%!  [SFT_freq_min, SFT_freq_max] = fevalstruct(@WeaveInputSFTBand, args);
%!  assert(SFT_freq_min <= min([results.segment_info.data.sft_min_freq]));
%!  assert(SFT_freq_max >= max([results.segment_info.data.sft_max_freq]));
