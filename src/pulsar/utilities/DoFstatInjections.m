## Copyright (C) 2013 Karl Wette
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

function results = DoFstatInjections(varargin)

  ## parse options
  parseOptions(varargin,
               {"h0", "real,strictpos,scalar", 1.0},
               {"cosi", "real,scalar", -1 + 2*rand()},
               {"psi", "real,scalar", 2*pi*rand()},
               {"phi0", "real,scalar", 2*pi*rand()},
               {"alpha", "real,scalar", 2*pi*rand()},
               {"delta", "real,scalar", asin(-1 + 2*rand())},
               {"fndot", "real,vector", [100]},
               {"ref_time", "real,strictpos,scalar"},
               {"start_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephemerides", "a:swig_ref"},
               {"inj_band", "real,strictpos,scalar", 0.2},
               {"inj_rand_seed", "integer,strictpos,scalar", int32(rand()*(2^31-1))},
               {"sft_time_span", "real,strictpos,scalar", 1800},
               {"sft_overlap", "real,positive,scalar", 0},
               []);
  assert(length(fndot) > 0);

  ## load LAL libraries
  lal;
  lalpulsar;

  ## check type of ephemerides is correct
  assert(strcmp(swig_type(ephemerides), "EphemerisData"));

  ## create results struct
  results = struct;

  ## create reference and start times
  refTime = new_LIGOTimeGPS(ref_time);
  if isempty(start_time)
    start_time = ref_time - 0.5 * time_span;
  endif
  startTime = new_LIGOTimeGPS(start_time);

  ## create and fill sources input vector for CWMakeFakeData()
  MFDsources = CreatePulsarParamsVector(1);
  MFDsource = MFDsources.data{1};
  MFDsource.Amp.h0   = results.h0   = h0;
  MFDsource.Amp.cosi = results.cosi = cosi;
  MFDsource.Amp.psi  = results.psi  = psi;
  MFDsource.Amp.phi0 = results.phi0 = phi0;
  MFDsource.Doppler.Alpha = results.Alpha = alpha;
  MFDsource.Doppler.Delta = results.Delta = delta;
  MFDsource.Doppler.fkdot = zeros(size(MFDsource.Doppler.fkdot));
  MFDsource.Doppler.fkdot(1:length(fndot)) = fndot;
  MFDsource.Doppler.refTime = refTime;

  ## parse detector names, and check length of SFT noise sqrt(Sh) vector
  detNames = CreateStringVector(strsplit(detectors, ","){:});

  ## generate SFT timestamps
  multiTimestamps = MakeMultiTimestamps(startTime, time_span, sft_time_span, sft_overlap, detNames.length);

  ## create and fill input parameters struct for CWMakeFakeData()
  MFDparams = new_CWMFDataParams;
  MFDparams.fMin = fndot(1) - 0.5*inj_band;
  MFDparams.Band = inj_band;
  ParseMultiDetectorInfo(MFDparams.detInfo, detNames, []);
  MFDparams.multiTimestamps = multiTimestamps;
  MFDparams.randSeed = results.inj_rand_seed = inj_rand_seed;

  ## run CWMakeFakeData() to generate SFTs with injection
  multiSFTs = [];
  multiSFTs = CWMakeFakeMultiData(multiSFTs, [], MFDsources, MFDparams, ephemerides);

  ## generate multi-detector states
  multiIFO = ExtractMultiLALDetectorFromSFTs(multiSFTs);
  multiTS = ExtractMultiTimestampsFromSFTs(multiSFTs);
  Tsft = 1.0 / multiSFTs.data{1}.data{1}.deltaF;
  tOffset = 0.5 * Tsft;
  detStates = GetMultiDetectorStates(multiTS, multiIFO, ephemerides, tOffset);

  ## create and fill input parameters struct for ComputeFStat()
  CFSparams = new_ComputeFParams;
  CFSparams.Dterms = 16;
  CFSparams.SSBprec = SSBPREC_RELATIVISTIC;
  CFSparams.buffer = [];
  CFSparams.useRAA = false;
  CFSparams.bufferedRAA = false;
  CFSparams.edat = ephemerides;
  CFSparams.returnAtoms = false;
  CFSparams.returnSingleF = false;
  CFSparams.upsampling = 1;

  ## create ComputeFStat() output struct
  Fstat = new_Fcomponents;

  ## run ComputeFStat() to search for injection
  CFSbuffer = new_ComputeFBuffer;
  ComputeFStat(Fstat, MFDsource.Doppler, multiSFTs, [], detStates, CFSparams, CFSbuffer);
  EmptyComputeFBuffer(CFSbuffer);

  ## return F-statistic values
  results.twoF = 2 * Fstat.F;

endfunction
