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

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"ref_time", "real,strictpos,scalar"},
               {"start_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephemerides", "a:swig_ref"},
               {"sft_time_span", "real,strictpos,scalar", 1800},
               {"sft_overlap", "real,positive,scalar", 0},
               {"inj_h0", "real,strictpos,row", []},
               {"inj_cosi", "real,row", []},
               {"inj_psi", "real,row", []},
               {"inj_phi0", "real,row", []},
               {"inj_alpha", "real,row", []},
               {"inj_delta", "real,row", []},
               {"inj_fndot", "real,matrix", [100]},
               {"inj_band_pad", "real,strictpos,scalar", 0.1},
               {"inj_rand_seed", "integer,strictpos,scalar", int32(rand()*(2^31-1))},
               {"sch_alpha", "real,row", []},
               {"sch_delta", "real,row", []},
               {"sch_fndot", "real,matrix", [100]},
               []);

  ## number of injection and search points
  assert(numel(inj_fndot) > 0);
  num_inj = size(inj_fndot, 2);
  assert(numel(sch_fndot) > 0);
  num_sch = size(sch_fndot, 2);

  ## check options
  assert(strcmp(swig_type(ephemerides), "EphemerisData"));
  assert(isempty(inj_h0)    || size(inj_h0, 2)    == num_inj);
  assert(isempty(inj_cosi)  || size(inj_cosi, 2)  == num_inj);
  assert(isempty(inj_psi)   || size(inj_psi, 2)   == num_inj);
  assert(isempty(inj_phi0)  || size(inj_phi0, 2)  == num_inj);
  assert(isempty(inj_alpha) || size(inj_alpha, 2) == num_inj);
  assert(isempty(inj_delta) || size(inj_delta, 2) == num_inj);
  assert(isempty(sch_alpha) || size(sch_alpha, 2) == num_sch);
  assert(isempty(sch_delta) || size(sch_delta, 2) == num_sch);

  ## create reference and start times
  refTime = new_LIGOTimeGPS(ref_time);
  if isempty(start_time)
    start_time = ref_time - 0.5 * time_span;
  endif
  startTime = new_LIGOTimeGPS(start_time);

  ## generate injection parameters as needed
  if isempty(inj_h0)
    inj_h0 = ones(1, num_inj);
  endif
  if isempty(inj_cosi)
    inj_cosi = -1 + 2*rand(size(inj_h0));
  endif
  if isempty(inj_psi)
    inj_psi = 2*pi*rand(size(inj_h0));
  endif
  if isempty(inj_phi0)
    inj_phi0 = 2*pi*rand(size(inj_h0));
  endif
  if isempty(inj_alpha)
    inj_alpha = 2*pi*rand(size(inj_h0));
  endif
  if isempty(inj_delta)
    inj_delta = asin(-1 + 2*rand(size(inj_h0)));
  endif

  ## create results struct
  results = struct;
  results.inj_h0 = inj_h0;
  results.inj_cosi = inj_cosi;
  results.inj_psi = inj_psi;
  results.inj_phi0 = inj_phi0;
  results.inj_alpha = inj_alpha;
  results.inj_delta = inj_delta;
  results.inj_fndot = inj_fndot;
  results.sch_alpha = sch_alpha;
  results.sch_delta = sch_delta;
  results.sch_fndot = sch_fndot;
  results.sch_twoF = zeros(1, num_sch);

  ## create and fill sources input vector for CWMakeFakeData()
  MFDsources = CreatePulsarParamsVector(num_inj);
  for i = 1:num_inj
    MFDsources.data{i}.Amp.h0   = inj_h0(i);
    MFDsources.data{i}.Amp.cosi = inj_cosi(i);
    MFDsources.data{i}.Amp.psi  = inj_psi(i);
    MFDsources.data{i}.Amp.phi0 = inj_phi0(i);
    MFDsources.data{i}.Doppler.Alpha = inj_alpha(i);
    MFDsources.data{i}.Doppler.Delta = inj_delta(i);
    MFDsources.data{i}.Doppler.fkdot = zeros(size(MFDsources.data{i}.Doppler.fkdot));
    MFDsources.data{i}.Doppler.fkdot(1:size(inj_fndot, 1)) = inj_fndot(:, i);
    MFDsources.data{i}.Doppler.refTime = refTime;
  endfor

  ## parse detector names, and check length of SFT noise sqrt(Sh) vector
  detNames = CreateStringVector(strsplit(detectors, ","){:});

  ## generate SFT timestamps
  multiTimestamps = MakeMultiTimestamps(startTime, time_span, sft_time_span, sft_overlap, detNames.length);

  ## create and fill input parameters struct for CWMakeFakeData()
  MFDparams = new_CWMFDataParams;
  MFDparams.fMin = min(inj_fndot(1, :)) - inj_band_pad;
  MFDparams.Band = max(inj_fndot(1, :)) + inj_band_pad - MFDparams.fMin;
  ParseMultiDetectorInfo(MFDparams.detInfo, detNames, []);
  MFDparams.multiTimestamps = multiTimestamps;
  MFDparams.randSeed = results.inj_rand_seed = inj_rand_seed;

  ## run CWMakeFakeData() to generate SFTs with injections
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

  ## create ComputeFStat() input and output structs
  Doppler = new_PulsarDopplerParams;
  Fstat = new_Fcomponents;

  ## run ComputeFStat() for each injection point
  CFSbuffer = new_ComputeFBuffer;
  for i = 1:num_sch

    ## fill input Doppler parameters struct for ComputeFStat()
    Doppler.Alpha = sch_alpha(i);
    Doppler.Delta = sch_delta(i);
    Doppler.fkdot = zeros(size(MFDsources.data{i}.Doppler.fkdot));
    Doppler.fkdot(1:size(sch_fndot, 1)) = sch_fndot(:, i);
    Doppler.refTime = refTime;

    ## run ComputeFStat()
    ComputeFStat(Fstat, Doppler, multiSFTs, [], detStates, CFSparams, CFSbuffer);

    ## return F-statistic values
    results.sch_twoF(i) = 2 * Fstat.F;

  endfor
  EmptyComputeFBuffer(CFSbuffer);

endfunction
