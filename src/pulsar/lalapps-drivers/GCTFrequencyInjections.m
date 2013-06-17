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

## Test the frequency-spindown grids of lalapps_HierarchSearchGCT with injections.
## Usage:
##   results = GCTFrequencyInjections(...)
## where:
##   results = structure containing results of injections
## Options:
##   "SFT_timestamp_files":     comma-separated SFT timestamp files; first two letters of
##                              filenames must give detector name (e.g. "H1...")
##   "GCT_segment_file":        segment file (columns: startGPS, endGPS, duration[h], NumSFTs)
##   "noise_Sh":                noise Sh of generated SFTs
##   "inject_h0":               injection h0
##   "SFT_band":                injection SFT bandwidth
##   "alpha":                   right ascension (radians)
##   "delta":                   declination (radians)
##   "ref_time":                GPS reference time
##   "freq":                    injection frequency (Hz)
##   "dfreq":                   frequency spacing (Hz)
##   "f1dot":                   first spindown start (Hz/s)
##   "f1dot_band":              first spindown band (Hz/s)
##   "df1dot":                  first spindown spacing (Hz/s)
##   "gamma1":                  first spindown refinement
##   "f2dot":                   second spindown start (Hz/s^2)
##   "f2dot_band":              second spindown band (Hz/s^2)
##   "df2dot":                  second spindown spacing (Hz/s^2)
##   "gamma2":                  second spindown refinement

function results = GCTFrequencyInjections(varargin)

  ## parse options
  opts = parseOptions(varargin,
                      {"SFT_timestamp_files", "char"},
                      {"GCT_segment_file", "char"},
                      {"noise_Sh", "real,positive,scalar"},
                      {"inject_h0", "real,strictpos,scalar"},
                      {"SFT_band", "real,strictpos,scalar"},
                      {"alpha", "real,scalar"},
                      {"delta", "real,scalar"},
                      {"ref_time", "real,strictpos,scalar"},
                      {"freq", "real,strictpos,scalar"},
                      {"dfreq", "real,strictpos,scalar"},
                      {"f1dot", "real,scalar"},
                      {"f1dot_band", "real,positive,scalar"},
                      {"df1dot", "real,strictpos,scalar"},
                      {"gamma1", "real,strictpos,scalar"},
                      {"f2dot", "real,scalar"},
                      {"f2dot_band", "real,positive,scalar"},
                      {"df2dot", "real,strictpos,scalar"},
                      {"gamma2", "real,strictpos,scalar"},
                      []);

  ## check for existence of files
  SFT_timestamp_files = strsplit(SFT_timestamp_files, ",", true);
  for i = 1:length(SFT_timestamp_files)
    if !exist(SFT_timestamp_files{i}, "file")
      error("%s: file '%s' does not exist", funcName, SFT_timestamp_files{i});
    endif
  endfor
  if !isempty(GCT_segment_file) && !exist(GCT_segment_file, "file")
    error("%s: file '%s' does not exist", funcName, GCT_segment_file);
  endif

  ## initialise result file
  results = struct;
  results.gitID = format_gitID(octapps_gitID());
  results.opts = opts;

  ## generate SFTs with injection
  MFD = struct;
  MFD.Alpha = alpha;
  MFD.Delta = delta;
  MFD.Freq = freq;
  MFD.Band = SFT_band;
  MFD.fmin = MFD.Freq - 0.5*MFD.Band;
  MFD.cosi = -1 + 2*rand();
  MFD.phi0 = 2*pi * rand();
  MFD.psi = 2*pi * rand();
  MFD.f1dot = f1dot + f1dot_band * rand();
  MFD.f2dot = 0 + f2dot_band * rand();		## !! Careful: for S6Directe testing, f2dot search band is always [0, f2dotBand]
  MFD.h0 = inject_h0;
  MFD.noiseSqrtSh = sqrt(noise_Sh);
  MFD.outSingleSFT = true;
  MFD.refTime = ref_time;
  SFT_files = cell(size(SFT_timestamp_files));
  for i = 1:length(SFT_timestamp_files)

    ## generate SFTs
    MFD.IFO = SFT_timestamp_files{i}(1:2);
    MFD.outSFTbname = SFT_files{i} = strcat(MFD.IFO, ".sft");
    MFD.timestampsFile = fullfile(".", SFT_timestamp_files{i});
    results.(strcat("MFD_", MFD.IFO)) = MFD;
    runCode(MFD, "lalapps_Makefakedata_v4", true);

  endfor

  ## run HierarchSearchGCT (no mismatch)
  GCT = struct;
  GCT.DataFiles1 = SFT_files{1};
  for i = 2:length(SFT_files)
    GCT.DataFiles1 = strcat(GCT.DataFiles1, ";", SFT_files{i});
  endfor
  GCT.skyRegion = sprintf("(%.16f,%.16f)", alpha, delta);
  GCT.gridType1 = 2;
  GCT.Freq = MFD.Freq;
  GCT.dFreq = dfreq;
  GCT.FreqBand = 0.0;
  GCT.f1dot = MFD.f1dot;
  GCT.df1dot = df1dot;
  GCT.f1dotBand = 0.0;
  GCT.f2dot = MFD.f2dot;
  GCT.df2dot = df2dot;
  GCT.f2dotBand = 0.0;
  GCT.segmentList = fullfile(".", GCT_segment_file);
  GCT.refTime = MFD.refTime;
  GCT.peakThrF = 0.0;
  GCT.SignalOnly = (noise_Sh == 0.0);
  GCT.printCand1 = true;
  GCT.semiCohToplist = true;
  GCT.fnameout = "GCT_Fstats";
  GCT.nCand1 = 1;
  GCT.gammaRefine = gamma1;
  GCT.gamma2Refine = gamma2;
  results.GCT_no_mismatch = GCT;
  runCode(GCT, "lalapps_HierarchSearchGCT", true);

  ## load no-mismatch Fstat results
  results.Fstats_no_mismatch = load(GCT.fnameout);

  ## run HierarchSearchGCT (with mismatch)
  GCT.FreqBand = dfreq;
  GCT.Freq += (-1 + rand())*GCT.dFreq;

  GCT.f1dot 	= f1dot;
  GCT.f1dotBand = f1dot_band;

  GCT.f2dot 	= f2dot;
  GCT.f2dotBand = f2dot_band;

  results.GCT_with_mismatch = GCT;
  runCode(GCT, "lalapps_HierarchSearchGCT", true);

  ## save with-mismatch Fstat result
  results.Fstats_with_mismatch = load(GCT.fnameout);

  ## compute and print mismatch
  results.twoF_no_mismatch = results.Fstats_no_mismatch(end);
  results.twoF_with_mismatch = results.Fstats_with_mismatch(end);
  results.mismatch = (results.twoF_no_mismatch - results.twoF_with_mismatch) / (results.twoF_no_mismatch - 4);
  printf("Mismatch: %0.2f\n", results.mismatch);

  ## delete temporary files
  for i = 1:length(SFT_files)
    delete(SFT_files{i});
  endfor
  delete(GCT.fnameout);

endfunction
