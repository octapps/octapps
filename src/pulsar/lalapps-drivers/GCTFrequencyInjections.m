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
##   "SFT_timestamp_files":	cell array of SFT timestamp files; first two letters of
##				filenames must give detector name (e.g. H1)
##   "GCT_segment_file":	segment file (columns: startGPS, endGPS, duration[h], NumSFTs)
##   "ephem_year":		ephemeris year (e.g. 09-11)
##   "noise_Sh":		noise Sh of generated SFTs
##   "inject_h0":		injection h0
##   "alpha":			right ascension (radians)
##   "delta":			declination (radians)
##   "freq":			injection frequency (Hz)
##   "f1dot_band":		first spindown band (Hz/s)
##   "f2dot_band":		second spindown band (Hz/s^2)
##   "f2dot_refine":		second spindown refinement factor
##   "mismatch_per_dim":	mismatch per dimension
##   "debug_level":		LAL debug level

function results = GCTFrequencyInjections(varargin)

  ## parse options
  opts = parseOptions(varargin,
                      {"SFT_timestamp_files", "cell"},
                      {"GCT_segment_file", "char"},
                      {"ephem_year", "char"},
                      {"noise_Sh", "real,positive,scalar"},
                      {"inject_h0", "real,strictpos,scalar"},
                      {"alpha", "real,scalar"},
                      {"delta", "real,scalar"},
                      {"freq", "real,strictpos,scalar"},
                      {"f1dot_band", "real,positive,scalar"},
                      {"f2dot_band", "real,positive,scalar"},
                      {"f2dot_refine", "real,strictpos,scalar"},
                      {"mismatch_per_dim", "real,strictpos,scalar"},
                      {"debug_level", "integer,scalar", 0},
                      []);

  ## check input
  for i = 1:length(SFT_timestamp_files)
    if !exist(SFT_timestamp_files{i}, "file")
      error("%s: file '%s' does not exist", funcName, SFT_timestamp_files{i});
    endif
  endfor
  if !exist(GCT_segment_file, "file")
    error("%s: file '%s' does not exist", funcName, GCT_segment_file);
  endif

  ## initialise result file
  results = struct;
  results.gitID = format_gitID(octapps_gitID());
  results.opts = opts;
  
  ## get reference time and average segment time span
  segs = load(GCT_segment_file);
  ref_time = mean([segs(1,1), segs(end, 2)]);
  seg_span = mean(segs(:,2) - segs(:,1));

  ## generate SFTs with injection
  MFD = struct;
  MFD.v = debug_level;
  MFD.Alpha = alpha;
  MFD.Delta = delta;
  MFD.Freq = freq;
  MFD.Band = 1.0;
  MFD.fmin = MFD.Freq - 0.5*MFD.Band;
  MFD.cosi = -1 + 2*rand();
  MFD.ephemYear = ephem_year;
  MFD.f1dot = -f1dot_band * rand();
  MFD.f2dot = f2dot_band * rand();
  MFD.h0 = inject_h0;
  MFD.noiseSqrtSh = sqrt(noise_Sh);
  MFD.outSingleSFT = true;
  MFD.phi0 = 2*pi * rand();
  MFD.psi = 2*pi * rand();
  MFD.refTime = ref_time;
  SFT_files = cell(size(SFT_timestamp_files));
  for i = 1:length(SFT_timestamp_files)
    
    ## generate SFTs
    MFD.IFO = SFT_timestamp_files{i}(1:2);
    MFD.outSFTbname = SFT_files{i} = strcat(MFD.IFO, ".sft");
    MFD.timestampsFile = fullfile(".", SFT_timestamp_files{i});
    results.(strcat("MFD_", MFD.IFO)) = MFD;
    runCode(MFD, "lalapps_Makefakedata_v4");

  endfor

  ## calculate frequency and spindown spacings from metric
  i = 0:2;
  gii = ( 4*pi^2 .* (1+i).^2 .* seg_span.^(2+2*i) ) ./ ( (3+2*i) .* factorial(2+i).^2 );
  dfndot = 2 .* sqrt(mismatch_per_dim ./ gii);

  ## run HierarchSearchGCT (no mismatch)
  GCT = struct;
  GCT.d = debug_level;
  GCT.DataFiles1 = SFT_files{1};
  for i = 2:length(SFT_files)
    GCT.DataFiles1 = strcat(GCT.DataFiles1, ";", SFT_files{i});
  endfor
  GCT.useWholeSFTs = true;
  GCT.skyRegion = sprintf("(%.16f,%.16f)", alpha, delta);
  GCT.gridType1 = 2;
  GCT.Freq = MFD.Freq;
  GCT.dFreq = dfndot(1);
  nFreqs = 10;
  GCT.FreqBand = 0.0;
  GCT.ephemE = sprintf("earth%s.dat", MFD.ephemYear);
  GCT.ephemS = sprintf("sun%s.dat", MFD.ephemYear);
  GCT.f1dot = MFD.f1dot;
  nf1dots = 10;
  GCT.df1dot = min(dfndot(2), f1dot_band / nf1dots);
  GCT.f1dotBand = 0.0;
  GCT.f2dot = MFD.f2dot;
  nf2dots = 10;
  GCT.df2dot = min(dfndot(3), f2dot_band / nf2dots);
  GCT.f2dotBand = 0.0;
  GCT.segmentList = fullfile(".", GCT_segment_file);
  GCT.refTime = MFD.refTime;
  GCT.peakThrF = 0.0;
  GCT.SignalOnly = (noise_Sh == 0.0);
  GCT.printCand1 = true;
  GCT.semiCohToplist = true;
  GCT.fnameout = "GCT_Fstats";
  GCT.nCand1 = 1;
  GCT.gamma2Refine = f2dot_refine;
  results.GCT_no_mismatch = GCT;
  runCode(GCT, "lalapps_HierarchSearchGCT");

  ## load no-mismatch Fstat results
  results.Fstats_no_mismatch = load(GCT.fnameout);

  ## run HierarchSearchGCT (with mismatch)
  GCT.FreqBand = nFreqs * GCT.dFreq;
  GCT.f1dotBand = nf1dots * GCT.df1dot;
  GCT.f2dotBand = nf2dots * GCT.df2dot;
  GCT.Freq += (-1 + 2*rand())*GCT.dFreq - 0.5*GCT.FreqBand;
  GCT.f1dot += (-1 + 2*rand())*GCT.df1dot - 0.5*GCT.f1dotBand;
  GCT.f2dot += (-1 + 2*rand())*GCT.df2dot - 0.5*GCT.f2dotBand;
  results.GCT_with_mismatch = GCT;
  runCode(GCT, "lalapps_HierarchSearchGCT");

  ## save with-mismatch Fstat result
  results.Fstats_with_mismatch = load(GCT.fnameout);

  ## delete temporary files
  for i = 1:length(SFT_files)
    delete(SFT_files{i});
  endfor
  delete(GCT.fnameout);

endfunction
