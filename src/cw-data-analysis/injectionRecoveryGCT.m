## Copyright (C) 2017 Christoph Dreissigacker
## Copyright (C) 2016 Reinhard Prix
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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{results} =} injectionRecoveryGCT ( @var{opt}, @var{val}, @dots{} )
##
## Perform signal injection and (area-search) recovery using @command{HierarchSearchGCT}
##
## @heading Arguments
##
## @table @var
## @item results
## structure containing various histograms of measured statistics and mismatches from the injection+recovery runs, and
##
## @end table
##
## @heading Options
##
## @table @code
## @item Ntrials
## (optional) number of repeated injection+recovery trials to perform [default: 1]
##
## @item timestampsFiles
## CSV list of SFT timestamp filenames
##
## @item IFOs
## CSV list of IFO names (eg "H1,L1,...")
##
## @item segmentList
## filename of segment list (containing lines of the form "startGPS endGPS\n")
##
## @item inj_sqrtSX
## injections: (optional) CSV list of per-detector noise-floor sqrt(PSD) to generate
##
## @item inj_h0
## injections: signal amplitude 'h0' of signals
##
## @item inj_SNR
## injections: alternative: signal-to-noise ratio 'SNR' of signals
##
## @item inj_AlphaRange
## injections: range of sky-position alpha to (isotropically) draw from [default: [0, 2pi]]
##
## @item inj_DeltaRange
## injections: range of sky-position delta to (isotropically) draw from [default: [-pi/2, pi/2]]
##
## @item inj_FreqRange
## injections: range of signal frequencies to draw from
##
## @item inj_fkdotRange
## injections: [numSpindowns x 2] ranges of spindown-values to draw from [default: []]
##
## @item dFreq
## search: frequency resolution
##
## @item dfkdot
## search: numSpindowns vector of spindown resolutions to use in search
##
## @item gammaRefine
## search: numSpindowns vector of 'gammeRefine[s]' refinement factors to use
##
## @item skyGridFile
## search: sky-grid file to use
##
## @item sch_Nsky
## search-box: number of nearest-neighbor skygrid points to use around injection
##
## @item sch_Nfreq
## search-box: number of frequency bins to use around injection frequency
##
## @item sch_Nfkdot
## search-box: number of spindown-bins to use around injection spindown-value
##
## @item FstatMethod
## search: F-statistic method to use: "DemodBest", "ResampBest", ...
##
## @item computeBSGL
## search: additionally compute and histogram B_S/GL statistic values
##
## @item Fstar0
## search: BSGL parameter 'Fstar0sc'
##
## @item nCand
## search: number of toplist candidates to keep
##
## @item GCT_binary
## which GCT executable to use for searching
##
## @item debugLevel
## control debug-output level
##
## @item cleanup
## boolean: remove intermediate output files at the end or not
##
## @end table
##
## @end deftypefn

function results = injectionRecoveryGCT ( varargin )

  ## parse options
  uvar = parseOptions ( varargin,
                        {"Ntrials", "real,strictpos,scalar", 1},
                        {"timestampsFiles", "char"},
                        {"IFOs", "char"},
                        {"segmentList", "char"},
                        {"inj_sqrtSX", "real,positive,scalar", [] },
                        {"inj_h0", "real,positive,scalar", [] },
                        {"inj_SNR", "real,positive,scalar", [] },
                        {"inj_AlphaRange", "real,vector", [0, 2*pi]},
                        {"inj_DeltaRange", "real,vector", [-pi/2, pi/2]},
                        {"inj_FreqRange", "real,strictpos,vector"},
                        {"inj_fkdotRange", "real,matrix", []},
                        {"dFreq", "real,strictpos,scalar"},
                        {"dfkdot", "real,positive,vector", []},
                        {"gammaRefine", "real,strictpos,vector", []},
                        {"skyGridFile", "char"},
                        {"sch_Nsky", "real,strictpos,scalar", 1 },
                        {"sch_Nfreq", "real,strictpos,scalar" },
                        {"sch_Nfkdot", "real,strictpos,vector" [] },
                        {"FstatMethod", "char", "DemodBest" },
                        {"computeBSGL", "bool, scalar", false},
                        {"Fstar0sc", "real, positive, scalar", 0},
                        {"nCand", "real,strictpos,scalar", 1 },
                        {"GCT_binary", "char", "lalapps_HierarchSearchGCT"},
                        {"debugLevel", "real,positive,scalar", 0},
                        {"cleanup", "bool,scalar", true},
                        []);

  global debugLevel;
  debugLevel = uvar.debugLevel;

  ## check input consistency
  have_h0 = !isempty(uvar.inj_h0);
  have_SNR = !isempty(uvar.inj_SNR);
  assert ( (have_h0 || have_SNR) && !(have_h0 && have_SNR), "Exactly one of 'inj_h0' or 'inj_SNR' must be specified\n");

  ## check input consistency: spindown-orders
  if ( !isempty ( uvar.inj_fkdotRange ) )
    [ spindown_order, numVals ] = size ( uvar.inj_fkdotRange );
    assert ( spindown_order <= 2, "Currently only up to 2nd spindown-order supported, got %d\n", spindown_order );
    assert ( numVals == 2, "Invalid range interval 'inj_fkdotRange' must be of size (spindown_order x 2), got (%d x %d)\n", spindown_order, numVals );
    [ r, c ] = size ( uvar.dfkdot );
    assert ( c == 1 && r == spindown_order, "Invalid size 'dfkdot' must be row-vector of length spindown_order = %d, got (%d x %d)\n", spindown_order, r, c );
    [ r, c ] = size ( uvar.gammaRefine );
    assert ( c == 1 && r == spindown_order, "Invalid size 'gammaRefine' must be row-vector of length spindown_order = %d, got (%d x %d)\n", spindown_order, r, c );
    [ r, c ] = size ( uvar.sch_Nfkdot );
    assert ( c == 1 && r == spindown_order, "Invalid size 'sch_Nfkdot' must be row-vector of length spindown_order = %d, got (%d x %d)\n", spindown_order, r, c );
  endif
  ## down-size spindown-order to actualy non-zero ranges
  for k = spindown_order : (-1) : 1
    if ( max ( abs ( uvar.inj_fkdotRange(k, :) ) ) == 0 )
      spindown_order --;
    endif
  endfor

  ## check for existence of input files
  timestampsFiles = strsplit ( uvar.timestampsFiles, "," );
  IFOs = strsplit ( uvar.IFOs, "," );
  numIFOs = numel ( IFOs );
  assert ( numIFOs == numel(timestampsFiles) );
  for i = 1:numIFOs
    assert ( exist ( timestampsFiles{i}, "file") == 2, "%s: file '%s' does not exist", funcName, timestampsFiles{i} );
  endfor
  assert ( exist ( uvar.segmentList, "file" ) == 2, "%s: file '%s' does not exist", funcName, uvar.segmentList );
  assert ( exist ( uvar.skyGridFile, "file" ) == 2, "%s: file '%s' does not exist", funcName, uvar.skyGridFile );

  ## initialise result file
  results = struct;
  results.gitID = format_gitID ( octapps_gitID() );
  results.opts = [];

  ## ---------- segment list: duration + refTime ----------
  segs = load ( uvar.segmentList );
  Nseg = size ( segs )(1);
  tSegStart = segs(:,1);
  tSegEnd   = segs(:,2);
  Tobs = tSegEnd(end) - tSegStart(1);
  ## figure out GCT reftime from actual timestamps
  tStart = inf; tEnd = 0;
  for i = 1 : length ( timestampsFiles )
    ts = load ( timestampsFiles{i} );
    tStart = min ( tStart, ts(1,1) );
    tEnd   = max ( tEnd, ts(end,1) );
  endfor
  Tsft = 1800;  ## assumed default
  inj.refTime = 0.5 * ( tStart + tEnd + Tsft ); ## make sure we hit the exact value the GCT code uses to avoid "grid bloat"

  ## ----- figure out maximal SFT bandwidth required -----
  inj_FreqMin = min ( uvar.inj_FreqRange );
  inj_FreqMax = max ( uvar.inj_FreqRange );
  inj_FreqBand = abs(diff(uvar.inj_FreqRange));

  maxOffset = max ( abs ( tStart - inj.refTime ), abs ( tEnd - inj.refTime ) );
  freq_range_fkdot = 0;
  extraBandFstat = 0;
  for k = 1 : spindown_order
    inj_fkdotMin(k)   = min ( uvar.inj_fkdotRange(k,:) );
    inj_fkdotMax(k)   = max ( uvar.inj_fkdotRange(k,:) );
    inj_fkdotAbsMax_k = max ( abs ( uvar.inj_fkdotRange(k,:) ) );
    freq_range_fkdot += inj_fkdotAbsMax_k * maxOffset^k / factorial(k);
    extraBandFstat   += 0.25 * ( Tobs^k * uvar.dfkdot(k) );
  endfor

  ## In E@H searches usually a wide frequency range is covered by many contiguous workunits,
  ## therefore we don't simulate 'boundary truncation' of the search box in frequency (only in fkdot):
  ## ==> widen the SFT band by Nfreq/2 bins on either side
  FreqPadding = uvar.sch_Nfreq * uvar.dFreq;
  SFT_band = inj_FreqBand  + FreqPadding + 2 * freq_range_fkdot + 2 * extraBandFstat + 2 * inj_FreqMax * 1.05e-4 + 2 * (16 + 50) / Tsft;

  ## ---------- generate empty 'dummy' SFTs purely as 'timesteps' ----------
  MFD = struct;

  MFD.fmin = inj_FreqMin - 0.5 * (SFT_band - inj_FreqBand);
  MFD.Band = SFT_band;
  if ( !isempty ( uvar.inj_sqrtSX ) )
    MFD.sqrtSX = uvar.inj_sqrtSX;
  endif
  MFD.outSFTdir = "./";
  MFD.outSingleSFT = true;
  MFD.IFOs = uvar.IFOs;
  MFD.timestampsFiles = uvar.timestampsFiles;

  runCode ( MFD, "lalapps_Makefakedata_v5", (uvar.debugLevel > 0) );
  results.mfd.args = MFD;
  SFTfiles = "*.sft";

  ## ---------- prepare histograms to store results in ----------
  hists.avgPFS           = Hist (1, {"lin", "dbin", 0.01} );
  hists.avgTwoFSig       = Hist (1, {"lin", "dbin", 0.01} );
  hists.avgTwoFMax       = Hist (1, {"lin", "dbin", 0.01} );
  hists.avgTwoFRMax      = Hist (1, {"lin", "dbin", 0.01} );
  if uvar.computeBSGL == true
    hists.log10BSGL   = Hist (1, {"lin", "dbin", 0.01} );
    hists.log10BSGLR  = Hist (1, {"lin", "dbin", 0.01} );
    hists.log10BSGLtL = Hist (1, {"lin", "dbin", 0.01} );
  endif

  hists.misSig   = Hist (1, {"lin", "dbin", 0.001 } );
  hists.misSC    = Hist (1, {"lin", "dbin", 0.01 } );
  hists.misSCR   = Hist (1, {"lin", "dbin", 0.01 } );

  hists.offsBins.skyInd = Hist (1, {"lin", "dbin", 1,   "bin0", 0 } );
  hists.offsBins.Freq   = Hist (1, {"lin", "dbin", 0.2, "bin0", -ceil(uvar.sch_Nfreq/2) } );

  hists.offsBinsR.skyInd = Hist (1, {"lin", "dbin", 1,   "bin0", 0 } );
  hists.offsBinsR.Freq   = Hist (1, {"lin", "dbin", 0.2, "bin0", -ceil(uvar.sch_Nfreq/2) } );

  for k = 1 : spindown_order
    hists.offsBins.fkdotIc(k)  = Hist (1, {"lin", "dbin", 1 } );
    hists.offsBinsR.fkdotIc(k) = Hist (1, {"lin", "dbin", 1 } );
  endfor

  hists.misCOH = Hist (1, {"lin", "dbin", 0.01 } );
  hists.misCOHperSeg = cell ( 1, Nseg );
  for l = 1 : Nseg
    hists.misCOHperSeg{l} = Hist (1, {"lin", "dbin", 0.01 } );
  endfor

  trials = cell ( 1, uvar.Ntrials );
  for iTrial = 1 : uvar.Ntrials

    DebugPrintf ( 1, "Starting trial %04d/%04d:\n", iTrial, uvar.Ntrials );

    ## ---------- pick random signal parameters ----------
    inj.cosi    = unifrnd ( -1, 1 );
    inj.psi     = unifrnd ( 0, pi );
    inj.phi0    = unifrnd ( 0, 2 *pi );

    inj.Alpha = unifrnd ( min(uvar.inj_AlphaRange), max(uvar.inj_AlphaRange) * (1 + sign(max(uvar.inj_AlphaRange))*eps) );
    sDeltaRange = sin ( uvar.inj_DeltaRange );
    inj.Delta   = asin ( unifrnd ( min(sDeltaRange), max(sDeltaRange) * (1 + sign(max(sDeltaRange))*eps) )  );
    inj.Freq    = unifrnd ( inj_FreqMin, inj_FreqMax * (1 + eps) );   #Freq is alway positive hence no sign()
    for k = 1 : spindown_order
      inj.fkdot(k)= unifrnd ( min(uvar.inj_fkdotRange(k, :)), max(uvar.inj_fkdotRange(k, :)) * (1 + sign(max(uvar.inj_fkdotRange(k, :)))*eps) );
    endfor

    ## ---------- run PredictFstat on all segments ==> "perfect match Fstats" ----------
    PFS = struct();
    if ( have_h0 )
      PFS.h0    = uvar.inj_h0;
    else
      PFS.h0    = 1;    ## rescale to given SNR at the end
    endif
    PFS.cosi    = inj.cosi;
    PFS.psi     = inj.psi;
    PFS.phi0    = inj.phi0;
    PFS.Alpha   = inj.Alpha;
    PFS.Delta   = inj.Delta;
    PFS.Freq    = inj.Freq;
    PFS.DataFiles = SFTfiles;
    if ( isempty ( uvar.inj_sqrtSX ) )
      PFS.assumeSqrtSX = 1;
    endif

    pfs = struct();
    pfs.twoFl = zeros ( 1, Nseg );
    for l = 1 : Nseg
      PFS.minStartTime = tSegStart ( l );
      PFS.maxStartTime = tSegEnd ( l );
      out = runCode ( PFS, "lalapps_PredictFstat", (uvar.debugLevel > 0) );
      pfs.twoFl(l) = str2num ( out );
    endfor ## l = 1:Nseg

    ## for fixed-SNR injections: determine correct h0 and rescale PFS values accordingly
    if ( have_SNR )
      avg2F = mean ( pfs.twoFl );
      SNR1 = sqrt(avg2F - 4);
      inj.h0 = uvar.inj_SNR / SNR1;
      PFS.h0 = inj.h0;
      pfs.twoFl = 4 + PFS.h0^2 * (pfs.twoFl - 4);
    elseif ( have_h0 )
      inj.h0 = uvar.inj_h0;
    else
      error ("Inconsistent input: need either 'inj_h0' or 'inj_SNR' to be set\n");
    endif

    pfs.twoF = mean ( pfs.twoFl );
    pfs.args = PFS;
    trials{iTrial}.pfs = pfs;
    hists.avgPFS  = addDataToHist ( hists.avgPFS, pfs.twoF );

    ## prepare injection sources
    inj.injectionSources = sprintf ( "{h0 = %g; cosi = %g; psi = %g; phi0 = %g; Alpha = %.16g; Delta = %.16g; Freq = %.16g; refTime = %.16g",
                                     inj.h0, inj.cosi, inj.psi, inj.phi0, inj.Alpha, inj.Delta, inj.Freq, inj.refTime );
    for k = 1 : spindown_order
      inj.injectionSources = sprintf ( "%s; f%ddot = %.16g", inj.injectionSources, k, inj.fkdot(k) );
    endfor
    inj.injectionSources = strcat ( inj.injectionSources, "}");
    trials{iTrial}.inj = inj;

    ## ---------- determine GCT search box on injection +- Nbins ----------
    DebugPrintf ( 1, "Determine GCT search box ... ");
    ## ----- Freq search range
    nFreq_GCT = ceil ( inj_FreqBand / uvar.dFreq );
    FreqGrid_GCT = inj_FreqMin + [0 : (nFreq_GCT-1) ] * uvar.dFreq;
    [ dummy, iFreq0 ] = min ( abs ( FreqGrid_GCT - inj.Freq ) );
    ## as mentioned above, we don't truncate the search frequency box to the
    ## 'GCT search grid', as we're assuming contiguous WUs above and below this
    ## search frequency range, so there's no "boundary"
    sch.Freq     = FreqGrid_GCT(iFreq0) - floor(uvar.sch_Nfreq/2) * uvar.dFreq;         ## start floor(Nfreq/2) bins below iFreq0 bin
    sch.FreqBand = (uvar.sch_Nfreq-1) * uvar.dFreq;                                     ## search Nfreq bins total

    ## ----- fkdot search range
    for k = 1 : spindown_order
      inj_fkdotBand_k   = inj_fkdotMax(k) - inj_fkdotMin(k); ## > 0
      nfkdot_GCT_k      = ceil ( inj_fkdotBand_k / uvar.dfkdot(k) ) + 1;
      fkdotGrid_GCT_k   = inj_fkdotMin(k) + [ 0 : (nfkdot_GCT_k-1) ] * uvar.dfkdot(k);
      [ foo, ifkdot0_k] = min ( abs ( fkdotGrid_GCT_k - inj.fkdot(k) ) );
      sch.fkdot(k)      = fkdotGrid_GCT_k(ifkdot0_k) - floor(uvar.sch_Nfkdot(k)/2) * uvar.dfkdot(k);    ## start floor(Nfkdot/2) bins below ifkdot0
      sch.fkdotBand(k)  = (uvar.sch_Nfkdot(k)-1) * uvar.dfkdot(k);                                      ## search Nfkdot bins total

      ## contrary to frequency, we *will* truncate this search box to the GCT search range,
      ## as this is typically represent the 'whole' range of the search, so we simulate 'boundary truncation'
      sch.fkdot(k)      = max ( [ inj_fkdotMin(k), sch.fkdot(k) ] );
      fkdotMax_k        = min ( [ inj_fkdotMax(k), sch.fkdot(k) + sch.fkdotBand(k) ] );
      sch.fkdotBand(k)  = fkdotMax_k - sch.fkdot(k);
    endfor ## k = 1:spindown_order

    ## ----- sky search range: find subset of Nsky 'closest' skygrid points
    skyGrid = load ( uvar.skyGridFile );
    NskyGrid = size(skyGrid)(1);
    ## convert to unit 3-vectors vn = [nx,ny,nz]
    skyGrid3 = skyAngles2Vector ( skyGrid );
    inj_Sky3 = skyAngles2Vector ( [ inj.Alpha, inj.Delta ] );
    ## convert to ecliptic coordinates
    skyGrid3Ecl = skyEquatorial2Ecliptic ( skyGrid3 );
    inj_Sky3Ecl = skyEquatorial2Ecliptic ( inj_Sky3 );
    ## neglect ecliptic-z axis and compute Euclidean distances in {x,y}
    offsEcl2 = repmat ( inj_Sky3Ecl([1:2]), [NskyGrid,1]) - skyGrid3Ecl(:,[1:2]);
    distSqEcl = sumsq ( offsEcl2, 2 );                  ## list of ecliptic-plane distances
    [sorted, iDist] = sort ( distSqEcl );               ## sort by increasing distanceSq
    sch.skyPatch = skyGrid ( iDist ( 1:uvar.sch_Nsky ), :);     ## search the Nsky 'closest' (in the above sense) sky-grid points
    tmp = sprintf ( "%.16g %.16g; ", sch.skyPatch' );
    sch.skyPatchString  = sprintf ( "{ %s }", tmp );

    ## ----- total number of fine-grid search templates
    sch.Ntempl_coh = uvar.sch_Nfreq * uvar.sch_Nsky;
    sch.Ntempl_inc = sch.Ntempl_coh;
    for k = 1 : spindown_order
      sch.Ntempl_coh *= uvar.sch_Nfkdot(k);
      sch.Ntempl_inc *= uvar.sch_Nfkdot(k) * uvar.gammaRefine(k);
    endfor
    DebugPrintf (1, "done.\n");

    ## 'signal only' convention is a bit messy/broken across different codes
    ## in particular: PFS will generally estimate (4 + SNR^2), while
    ## GCT --SignalOnly outputs <2F> = (4+SNR^2) *BUT* <2F_recalc> = SNR^2 !!
    ## ie no +4 is added to the recalculated 2F values in the SignalOnly case
    ## so we need to account for this here in order to correctly compute mismatches
    ## (relevant in the low-SNR limit used here for 2F histogram size reasons)
    SignalOnly = (isempty ( uvar.inj_sqrtSX ));
    if ( SignalOnly )
      SignalOnlyOffsetR = 4;
    else
      SignalOnlyOffsetR = 0;
    endif

    ## ---------- run HierarchSearchGCT box-search around injection ----------
    GCT = struct;
    GCT.DataFiles1      = SFTfiles;
    GCT.segmentList     = uvar.segmentList;
    GCT.refTime         = inj.refTime;

    GCT.injectionSources = inj.injectionSources;

    GCT.Freq            = sch.Freq;
    GCT.FreqBand        = sch.FreqBand;
    GCT.dFreq           = uvar.dFreq;

    if ( spindown_order >= 1 )
      GCT.f1dot         = sch.fkdot(1);
      GCT.f1dotBand     = sch.fkdotBand(1);
      GCT.df1dot        = uvar.dfkdot(1);
      GCT.gammaRefine   = uvar.gammaRefine(1);
    endif
    if ( spindown_order >= 2 )
      GCT.f2dot         = sch.fkdot(2);
      GCT.f2dotBand     = sch.fkdotBand(2);
      GCT.df2dot        = uvar.dfkdot(2);
      GCT.gamma2Refine  = uvar.gammaRefine(2);
    endif

    GCT.gridType1       = 3;
    GCT.skyGridFile     = sch.skyPatchString;

    GCT.peakThrF        = 0.0;
    GCT.SignalOnly      = SignalOnly;
    GCT.printCand1      = true;
    GCT.semiCohToplist  = true;
    GCT.fnameout        = "GCT.out";
    GCT.nCand1          = uvar.nCand;   ## keep this many candidates in toplist
    GCT.recalcToplistStats = true;      ## re-calculate toplist
    if uvar.computeBSGL
      GCT.SortToplist   = 3;    ## sort by 2F and BSGL
    else
      GCT.SortToplist   = 0;    ## sort by 2F
    endif
    GCT.FstatMethod     = uvar.FstatMethod;
    GCT.computeBSGL     = uvar.computeBSGL;
    GCT.Fstar0          = uvar.Fstar0sc; ## old option name as this is using an old GCT version
    if uvar.computeBSGL
      GCT.getMaxFperSeg = true;
    endif
    GCT.loudestTwoFPerSeg = true;

    runCode ( GCT, uvar.GCT_binary, (uvar.debugLevel > 0) );

    ## ---------- load avg-Fstat results and parse results
    DebugPrintf ( 1, "Loading GCT toplist file '%s' ... ", GCT.fnameout );
    out = load ( GCT.fnameout );
    DebugPrintf ( 1, "done.\n");

    ## store and analyse loudest-2F candidate ----------
    DebugPrintf ( 1, "Analysing mismatches and offsets ... " );
    maxTwoF = struct();
    [dummy,  iTwoF_max ]  = max ( out(:,7)(:) );
    maxTwoF.Freq     = out ( iTwoF_max, 1 );
    maxTwoF.Alpha    = out ( iTwoF_max, 2 );
    maxTwoF.Delta    = out ( iTwoF_max, 3 );
    maxTwoF.fkdot(1) = out ( iTwoF_max, 4 );
    maxTwoF.fkdot(2) = out ( iTwoF_max, 5 );
    maxTwoF.twoF     = out ( iTwoF_max, 7 );
    maxTwoF.twoFR    = out ( iTwoF_max, 8 ) + SignalOnlyOffsetR;

    if GCT.computeBSGL == true
      maxTwoF.twoFR    = out ( iTwoF_max, 19) + SignalOnlyOffsetR;
      maxTwoF.log10BSGL= out ( iTwoF_max, 8 );
      maxTwoF.log10BSGLR=out ( iTwoF_max, 20);
      maxTwoF.log10BSGLtL=out( iTwoF_max, 11);

      ## ---------- load BSGL results and parse results
      DebugPrintf ( 1, "Loading 2nd GCT toplist file '%s' ... ", strcat(GCT.fnameout, "-BSGL") );
      out = load ( strcat(GCT.fnameout,"-BSGL") );
      DebugPrintf ( 1, "done.\n");

      ## store analyse loudest BSGL candidate ----------
      DebugPrintf ( 1, "Analysing mismatches and offsets ... " );
      maxBSGL = struct();
      [dummy,  iBSGL_max ]  = max ( out(:,8)(:) );
      maxBSGL.Freq     = out ( iBSGL_max, 1 );
      maxBSGL.Alpha    = out ( iBSGL_max, 2 );
      maxBSGL.Delta    = out ( iBSGL_max, 3 );
      maxBSGL.fkdot(1) = out ( iBSGL_max, 4 );
      maxBSGL.fkdot(2) = out ( iBSGL_max, 5 );
      maxBSGL.twoF     = out ( iBSGL_max, 7 );
      maxBSGL.twoFR    = out ( iBSGL_max, 19) + SignalOnlyOffsetR;
      maxBSGL.log10BSGL= out ( iBSGL_max, 8 );
      maxBSGL.log10BSGLR=out ( iBSGL_max, 20);
      maxBSGL.log10BSGLtL=out( iBSGL_max, 11);

      hists.log10BSGL   = addDataToHist ( hists.log10BSGL, maxBSGL.log10BSGL);
    endif

    ## mismatch
    maxTwoF.mis = (pfs.twoF - maxTwoF.twoF) / (pfs.twoF - 4);

    hists.avgTwoFMax  = addDataToHist ( hists.avgTwoFMax, maxTwoF.twoF );

    ## quantify offset from injection in terms of 'grid-steps'
    maxTwoF.offsBins.Freq  = ( maxTwoF.Freq - inj.Freq ) / uvar.dFreq;
    for k = 1 : spindown_order
      maxTwoF.offsBins.fkdotIc(k) = ( maxTwoF.fkdot(k) - inj.fkdot(k) ) / (uvar.dfkdot(k) / uvar.gammaRefine(k) );
    endfor

    offsSky = sch.skyPatch - repmat ( [ maxTwoF.Alpha, maxTwoF.Delta ], [ uvar.sch_Nsky, 1 ] );
    distSqSky = sumsq ( offsSky, 2 );
    [dummy, iSkyBest] = min ( distSqSky );
    maxTwoF.offsBins.skyInd = iSkyBest - 1; ## 'skyPatch' was sorted from 'closest' to 'farthest'

    ## ---------- store and analyse loudest recalc 2Fr candidate ----------
    maxTwoFR = struct();
    if GCT.computeBSGL == true;
      [dummy, iTwoFR_max ] = max ( out(:,19)(:) );
    else
      [dummy, iTwoFR_max ] = max ( out(:,8)(:) );
    endif
    maxTwoFR.Freq     = out ( iTwoFR_max, 1 );
    maxTwoFR.Alpha    = out ( iTwoFR_max, 2 );
    maxTwoFR.Delta    = out ( iTwoFR_max, 3 );
    maxTwoFR.fkdot(1) = out ( iTwoFR_max, 4 );
    maxTwoFR.fkdot(2) = out ( iTwoFR_max, 5 );
    maxTwoFR.twoF     = out ( iTwoFR_max, 7 );
    maxTwoFR.twoFR    = out ( iTwoFR_max, 8 ) + SignalOnlyOffsetR;

    if GCT.computeBSGL == true
      maxTwoFR.twoFR    = out ( iTwoF_max, 19) + SignalOnlyOffsetR;
      maxTwoFR.log10BSGL= out ( iTwoF_max, 8 );
      maxTwoFR.log10BSGLR=out ( iTwoF_max, 20);
      maxTwoFR.log10BSGLtL=out( iTwoF_max, 11);

      ## store analyse loudest BSGL candidate ----------
      DebugPrintf ( 1, "Analysing mismatches and offsets ... " );
      maxBSGL = struct();
      [dummy,  iBSGLR_max ]  = max ( out(:,20)(:) );
      maxBSGLR.Freq     = out ( iBSGLR_max, 1 );
      maxBSGLR.Alpha    = out ( iBSGLR_max, 2 );
      maxBSGLR.Delta    = out ( iBSGLR_max, 3 );
      maxBSGLR.fkdot(1) = out ( iBSGLR_max, 4 );
      maxBSGLR.fkdot(2) = out ( iBSGLR_max, 5 );
      maxBSGLR.twoF     = out ( iBSGLR_max, 7 );
      maxBSGLR.twoFR    = out ( iBSGLR_max, 19) + SignalOnlyOffsetR;
      maxBSGLR.log10BSGL= out ( iBSGLR_max, 8 );
      maxBSGLR.log10BSGLR=out ( iBSGLR_max, 20);
      maxBSGLR.log10BSGLtL=out( iBSGLR_max, 11);

      hists.log10BSGLR = addDataToHist ( hists.log10BSGLR, maxBSGLR.log10BSGLR);
    endif

    ## mismatch
    maxTwoFR.mis = (pfs.twoF - maxTwoFR.twoFR) / (pfs.twoF - 4);

    hists.avgTwoFRMax = addDataToHist ( hists.avgTwoFRMax, maxTwoFR.twoFR );

    ## quantify offset from injection in terms of 'grid-steps'
    maxTwoFR.offsBins.Freq  = ( maxTwoFR.Freq - inj.Freq ) / uvar.dFreq;
    for k = 1 : spindown_order
      maxTwoFR.offsBins.fkdotIc(k) = ( maxTwoFR.fkdot(k) - inj.fkdot(k) ) / (uvar.dfkdot(k) / uvar.gammaRefine(k) );
    endfor

    offsSky = sch.skyPatch - repmat ( [ maxTwoFR.Alpha, maxTwoFR.Delta ], [ uvar.sch_Nsky, 1 ] );
    distSqSky = sumsq ( offsSky, 2 );
    [dummy, iSkyBest] = min ( distSqSky );
    maxTwoFR.offsBins.skyInd = iSkyBest - 1;    ## 'skyPatch' was sorted from 'closest' to 'farthest'

    gct.args = GCT;
    gct.maxTwoF  = maxTwoF;
    gct.maxTwoFR = maxTwoFR;
    DebugPrintf ( 1, "done.\n");

    ## ---------- load and parse loudest per-segment F-stat values ----------
    DebugPrintf ( 1, "Analysing coherent per-segment mismatch ... ");
    loudestTwoFperSeg_fname = strcat ( GCT.fnameout, "_loudestTwoFPerSeg" );
    loudestTwoFperSeg = load ( loudestTwoFperSeg_fname );
    assert ( length(loudestTwoFperSeg) == Nseg, "Inconsistent number of segments\n");
    for l = 1 : Nseg
      misCOH_l = (pfs.twoFl(l) - loudestTwoFperSeg(l)) / ( pfs.twoFl(l) - 4 );
      hists.misCOHperSeg{l} = addDataToHist ( hists.misCOHperSeg{l}, misCOH_l );
      hists.misCOH = addDataToHist ( hists.misCOH, misCOH_l );
    endfor
    DebugPrintf ( 1, "done.\n");

    ## ---------- run HierarchSearchGCT in perfectly-matched injection point ----------
    GCTSig = GCT;       ## inherit settings
    GCTSig.Freq         = inj.Freq;
    GCTSig.FreqBand     = 0;
    if ( spindown_order >= 1 )
      GCTSig.f1dot       = inj.fkdot(1);
      GCTSig.f1dotBand   = 0;
      GCTSig.df1dot      = uvar.dfkdot(1);
      GCTSig.gammaRefine = 1;
    endif
    if ( spindown_order >= 2 )
      GCTSig.f2dot        = inj.fkdot(2);
      GCTSig.f2dotBand    = 0;
      GCTSig.df2dot       = uvar.dfkdot(2);
      GCTSig.gamma2Refine = 1;
    endif

    GCTSig.skyGridFile  = sprintf ( "{ %.16g %.16g; }", inj.Alpha, inj.Delta );
    GCTSig.fnameout     = "GCT0.out";
    GCTSig.nCand1       = 1;    ## keep this many candidates in toplist
    GCTSig.loudestTwoFPerSeg = false;

    runCode ( GCTSig, uvar.GCT_binary, (uvar.debugLevel > 0) );

    ## load perfect-match GCT results
    outSig = load ( GCTSig.fnameout );
    assert ( size(outSig)(1) == 1 );

    gct.argsSig  = GCTSig;
    gct.twoFSig  = outSig(1,7);
    gct.twoFSigR = outSig(1,8) + SignalOnlyOffsetR;

    ## GCT mismatch in 'perfect-match' signal point (wrt PFS)
    gct.misSig = (pfs.twoF - gct.twoFSigR) / (pfs.twoF - 4);

    hists.avgTwoFSig = addDataToHist ( hists.avgTwoFSig, gct.twoFSigR );
    ## ----- store individual per-trial results
    trials{iTrial}.gct = gct;

    ## ----- add mismatches and offsets to histograms
    hists.misSig = addDataToHist ( hists.misSig, gct.misSig );
    hists.misSC  = addDataToHist ( hists.misSC,  gct.maxTwoF.mis );
    hists.misSCR = addDataToHist ( hists.misSCR, gct.maxTwoFR.mis );

    hists.offsBins.Freq   = addDataToHist ( hists.offsBins.Freq,   gct.maxTwoF.offsBins.Freq );
    hists.offsBins.skyInd = addDataToHist ( hists.offsBins.skyInd, gct.maxTwoF.offsBins.skyInd );

    hists.offsBinsR.Freq   = addDataToHist ( hists.offsBinsR.Freq,   gct.maxTwoFR.offsBins.Freq );
    hists.offsBinsR.skyInd = addDataToHist ( hists.offsBinsR.skyInd, gct.maxTwoFR.offsBins.skyInd );

    for k = 1 : spindown_order
      hists.offsBins.fkdotIc(k)  = addDataToHist ( hists.offsBins.fkdotIc(k),  gct.maxTwoF.offsBins.fkdotIc(k) );
      hists.offsBinsR.fkdotIc(k) = addDataToHist ( hists.offsBinsR.fkdotIc(k), gct.maxTwoFR.offsBins.fkdotIc(k) );
    endfor

  endfor ## iTrial = 1:Ntrials

  results.trials = trials;
  results.hists = hists;

  ## delete temporary files
  if ( uvar.cleanup )
    delete ( SFTfiles );
    delete ( GCT.fnameout );
    delete ( GCTSig.fnameout );
  endif

endfunction ## measureGCTmismatch()

%!test
%!  if isempty(file_in_path(getenv("PATH"), "lalapps_HierarchSearchGCT"))
%!    disp("skipping test: LALApps programs not available"); return;
%!  endif
%!  output = nthargout(2, @system, "lalapps_HierarchSearchGCT --version");
%!  LALApps_version = versionstr2hex(nthargout(5, @regexp, output, "LALApps: ([0-9.]+)"){1}{1,1});
%!  if LALApps_version <= 0x06210000
%!    disp("cannot run test as version of lalapps_HierarchSearchGCT is too old"); return;
%!  endif
%!  oldpwd = pwd;
%!  basedir = mkpath(tempname(tempdir));
%!  unwind_protect
%!    cd(basedir);
%!    args = struct;
%!    args.timestampsFiles = "H1.txt";
%!    args.IFOs = "H1";
%!    args.segmentList = "segs.txt";
%!    args.inj_sqrtSX = 1.0;
%!    args.inj_h0 = 1.0;
%!    args.inj_AlphaRange = [0, 2*pi];
%!    args.inj_DeltaRange = [-pi/2, pi/2];
%!    args.inj_FreqRange = [100, 100.01];
%!    args.inj_fkdotRange = [-1e-8, 0];
%!    args.dFreq = 1e-7;
%!    args.dfkdot = 1e-11;
%!    args.gammaRefine = 100;
%!    args.skyGridFile = "sky.txt";
%!    args.sch_Nsky = 5;
%!    args.sch_Nfreq = 5;
%!    args.sch_Nfkdot = 5;
%!    args.FstatMethod = "DemodBest";
%!    args.cleanup = true;
%!    fid = fopen(args.timestampsFiles, "w");
%!    for i = 1:10
%!      fprintf(fid, "%i\n", 800000000 + 1800*i);
%!    endfor
%!    fclose(fid);
%!    fid = fopen(args.segmentList, "w");
%!    fprintf(fid, "%i %i\n", 800000000 + 1800*[0, 5]);
%!    fprintf(fid, "%i %i\n", 800000000 + 1800*[5, 10]);
%!    fclose(fid);
%!    fid = fopen(args.skyGridFile, "w");
%!    for i = 1:50
%!      fprintf(fid, "%.5f %.5f\n", unifrnd(0, 2*pi), unifrnd(-pi/2, pi/2));
%!    endfor
%!    fclose(fid);
%!    fevalstruct(@injectionRecoveryGCT, args);
%!  unwind_protect_cleanup
%!    cd(oldpwd);
%!  end_unwind_protect
