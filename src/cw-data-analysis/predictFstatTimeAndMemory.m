## Copyright (C) 2016, 2017 Reinhard Prix
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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{resampInfo}, @var{demodInfo} ] =} predictFstatTimeAndMemory ( @var{varargin} )
##
## Predict @strong{single-segment} F-statistic computation time per frequency bin per detector (@code{tauF_core} and @code{tauF_buffer})
## and corresponding memory requirements (@code{MBWorkspace}, @code{MBDataPerDetSeg}) for both @emph{Resampling} and @emph{Demod} Fstat methods.
##
## See the F-stat timing notes at https://dcc.ligo.org/LIGO-T1600531-v4 for a detailed description of the F-statistic timing model
## and notation.
##
## @heading Note
##
## The estimate is for @strong{one} coherent segment of length @code{Tcoh}, while@code{Tspan} is only used to correctly deal with the GCT code's handling of multi-segment searches, which
## can affect timing and memory requirements for each segment. In the case of @emph{Weave}, however, use Tspan = Tcoh [default].
##
## @heading Input parameters
##
## @table @code
## @item Tcoh
## coherent segment length
##
## @item Tspan
## total data time-span [Default: Tcoh].
## @strong{Note}: this is used to estimate the total memory in the case of the GCT search code,
## which load the full frequency band of data over all segments. In the case of the
## Weave code, the SFT frequency band is computed for each segment separately, so
## in this case one should use @code{Tspan}==@code{Tcoh} to correctly estimate the timing and memory!
##
## @item Freq0
## start search frequency
##
## @item FreqBand
## search frequency band
##
## @item dFreq
## search frequency spacing
##
## @end table
##
## @heading Optional arguments
##
## @table @code
## @item f1dot0
## @itemx f1dotBand
## first-order spindown range [f1dot0, f1dot0+f1dotBand]  [Default: 0]
##
## @item f2dot0
## @itemx f2dotBand
## 2nd-order spindown range [f2dot0,f2dot0+f2dotBand]    [Default: 0]
##
## @item Dterms
## number of @emph{Dterms} used in sinc-interpolation  [Default: 8]
##
## @item Nsft
## number of SFTs (for single segment, single detector) [Default: Nsft=Tcoh/Tsft]
##
## @item Tsft
## SFT length [Default: 1800]
##
## @item refTimeShift
## offset of reference time from starttime, measured in units of @var{Tspan}, ie @var{refTimeShift} = (@var{refTime} - @var{startTime})/@var{Tspan} [Default: 0.5]
##
## @item binaryMaxAsini
## Maximum projected semi-major axis a*sini/c (= 0 for isolated sources) [Default: 0]
##
## @item binaryMinPeriod
## Minimum orbital period (s); must be 0 for isolated signals [Default: 0]
##
## @item binaryMaxEcc
## Maximal binary eccentricity: must be 0 for isolated signals [Default: 0]
##
## @item resampFFTPowerOf2
## enforce FFT length to be a power of two (by rounding up) [Default: true]
##
## @end table
##
## @heading Resampling timing model coefficients
##
## @table @code
## @item tau0_Fbin
## Resampling timing coefficient for contributions scaling with output frequency bins NFbin
##
## @item tau0_FFT
## Resampling timing coefficient for FFT performance. Can be 2-element vector [@var{t1}, @var{t2}]: use @var{t1} if log2(NsampFFT) <= 18, @var{t2} otherwise
##
## @item tau0_spin
## Resampling timing coefficient for applying spin-down corrections
##
## @item tau0_bary
## Resampling timing coefficient (buffered) barycentering (contributes to tauF_buffer)
##
## @end table
##
## @heading Demod timing model coefficients
##
## @table @code
## @item tau0_coreLD
## Demod timing coefficient for core F-stat time
##
## @item tau0_bufferLD
## Demod timing coefficient for computation of buffered quantities
##
## @end table
##
## @heading Return values
##
## Two structs @var{resampInfo} and @var{demodInfo} with fields:
##
## @table @code
## @item tauF_core
## Fstat time per frequency bin per detector excluding time to compute buffered quantities (eg barycentering) [in seconds]
##
## @item tauF_buffer
## Fstat time per frequency bin per detector for computing all the buffered quantities once [in seconds]
## The effective F-stat time per frequency bin per detector is therefore
## tauF_eff = tauF_core + b * tauF_buffer, where b = 1/N_@{f1,f2,...@} is the fraction of calls to @command{XLALComputeFstat()} where the buffer can be re-used
##
## @item l2NsampFFT
## @strong{resamp only} log_2(NsampFFT) where NsampFFT is the number of FFT samples
##
## @item MBWorkspace
## @strong{resamp only} memory for (possibly shared) workspace [in MBytes]
##
## @item MBDataPerDetSeg
## memory to hold all data @strong{per detector}, @strong{per-segment} (original+buffered) [in MBytes]
## ie total data memory would be
## @verbatim
##   memData[all] = Nseg * Ndet * memDataPerDetSeg
## @end verbatim
##
## @end table
##
## @end deftypefn

function [resampInfo, demodInfo] = predictFstatTimeAndMemory ( varargin )

  ## parse options
  uvar = parseOptions ( varargin,
                        {"Tcoh",        "strictpos,matrix"},
                        {"Tspan",       "positive,matrix",      0},
                        {"Freq0",       "strictpos,matrix"},
                        {"FreqBand",    "positive,matrix"},
                        {"dFreq",       "strictpos,matrix"},
                        {"f1dot0",      "real,matrix",   0},
                        {"f1dotBand",   "real,matrix",   0},
                        {"f2dot0",      "real,matrix",   0},
                        {"f2dotBand",   "real,matrix",   0},
                        {"refTimeShift", "matrix",    0.5 },
                        {"Dterms",      "strictpos,matrix", 8 },
                        {"Tsft",        "strictpos,matrix", 1800 },
                        {"Nsft",        "positive,matrix", 0 },
                        {"binaryMaxAsini",  "positive,matrix", 0 },
                        {"binaryMinPeriod", "positive,matrix", 0},
                        {"binaryMaxEcc",    "positive,matrix", 0},
                        {"resampFFTPowerOf2", "bool",  true },          ## is XLALComputeFstat() we using FFT rounded to next power of 2 (see optArgs->resampFFTPowerOf2)
                        ## Resamp timing model coefficients
                        {"tau0_Fbin",    "strictpos,scalar", 5.4e-8 },
                        {"tau0_FFT",     "strictpos,vector", [1.5e-10, 3.6e-10] },   ## FFT timing coefficient [t1, t2] where t1 if log2(NsampFFT) <= 18, t2 otherwise
                        {"tau0_spin",    "strictpos,scalar", 5.1e-8 },
                        {"tau0_bary",    "strictpos,scalar", 3.3e-7 },
                        ## Demod timing model coefficients
                        {"tau0_coreLD",   "strictpos,scalar", 4.6e-8 },
                        {"tau0_bufferLD", "strictpos,scalar", 4.8e-7 }
                      );

  ## load swigged LAL libraries
  lal;
  lalpulsar;

  if ( uvar.Tspan == 0 )
    uvar.Tspan = uvar.Tcoh;
  endif
  assert ( length(uvar.tau0_FFT) == 1 || length(uvar.tau0_FFT) == 2, "tau0_FFT can be scalar or 2-element vector");

  [err, Tspan, Tcoh, Freq0, FreqBand, dFreq, f1dot0, f1dotBand, f2dot0, f2dotBand, refTimeShift, Dterms, Nsft, Tsft, binaryMaxAsini, binaryMinPeriod, binaryMaxEcc ] = common_size ( uvar.Tspan, uvar.Tcoh, uvar.Freq0, uvar.FreqBand, uvar.dFreq, uvar.f1dot0, uvar.f1dotBand, uvar.f2dot0, uvar.f2dotBand, uvar.refTimeShift, uvar.Dterms, uvar.Nsft, uvar.Tsft, uvar.binaryMaxAsini, uvar.binaryMinPeriod, uvar.binaryMaxEcc  );
  assert(err == 0, "Input variables are not of common size");
  len = length ( Tspan(:) );
  ## deal with potentially FFT-length-dependent FFT-timing
  if ( length ( uvar.tau0_FFT ) == 1 )
    tau0_FFT = [ uvar.tau0_FFT, uvar.tau0_FFT ];
  else
    tau0_FFT = uvar.tau0_FFT;
  endif
  l2NsampFFT_sep = 18;  ## if <= this value then use tau0_FFT(1), above use tau0_FFT(2), see also http://www.fftw.org/speed/CoreDuo-3.0GHz-icc64/

  ## estimate sidebands as closely as possible to what's done in ComputeFstat, by using XLALCWSignalCoveringBand()
  FreqBandRS = zeros ( size(Tspan) );
  extraBinsMethod = 8;  ## resampling 'extra bins' value
  fudge_up = 1 + 10 * eps;
  fudge_down = 1 - 10 * eps;
  for i = 1 : len
    assert ( (binaryMaxAsini(i) != 0) || (binaryMinPeriod(i) == 0 && binaryMaxEcc(i) == 0) );
    refTime = floor ( refTimeShift(i) * Tspan(i) );
    fkdotRef     = [ Freq0(i),    f1dot0(i),    f2dot0(i) ];
    fkdotBandRef = [ FreqBand(i), f1dotBand(i), f2dotBand(i) ];

    time1 = new_LIGOTimeGPS ( 0 );
    time2 = new_LIGOTimeGPS ( Tspan(i) );
    spinRange = new_PulsarSpinRange;
    spinRange.refTime   = refTime;
    spinRange.fkdot     = resize ( fkdotRef, [1, PULSAR_MAX_SPINS] );
    spinRange.fkdotBand = resize ( fkdotBandRef, [1, PULSAR_MAX_SPINS] );
    [ minCoverFreq, maxCoverFreq ] = XLALCWSignalCoveringBand ( time1, time2, spinRange, binaryMaxAsini(i), binaryMinPeriod(i), binaryMaxEcc(i));
    df = 1.0 / Tsft(i);
    minFreq = minCoverFreq - extraBinsMethod * df;
    maxFreq = maxCoverFreq + extraBinsMethod * df;
    tmp = minFreq / df;
    iMin = floor ( tmp * fudge_up );
    tmp = maxFreq / df;
    iMax = ceil  ( tmp * fudge_down );
    numBins = ( iMax - iMin + 1 );
    FreqBandLoad = numBins * df;

    ## increase band for windowed-sinc
    extraBand = 2.0  / ( 2 * Dterms(i) + 1 ) * FreqBandLoad;
    fMinIn = iMin * df;
    tmp = (fMinIn - extraBand) / df;
    iMin1 = floor ( tmp * fudge_up );
    tmp = (fMinIn + FreqBandLoad + extraBand) / df;
    iMax1 = ceil  ( tmp * fudge_down );
    numBinsRS = iMax1 - iMin1 + 1;
    FreqBandRS(i) = numBinsRS * df;
  endfor

  dtDET = 1 ./ FreqBandRS;
  NFbin = ceil ( FreqBand ./ dFreq );
  D = ceil ( Tcoh .* dFreq );
  TFFT = 1 ./ ( dFreq ./ D );
  NsampFFT0 = ceil ( TFFT ./ dtDET );
  l2NsampFFT = log2 ( NsampFFT0 );
  if ( uvar.resampFFTPowerOf2 )
    l2NsampFFT = ceil ( l2NsampFFT );
  endif
  h_or_l = ones ( size(l2NsampFFT)) + ( l2NsampFFT > l2NsampFFT_sep );
  NsampFFT  = 2.^l2NsampFFT;
  dtSRC = TFFT ./ NsampFFT;

  NsampSRC = floor ( Tcoh ./ dtSRC );
  R = Tcoh ./ TFFT;

  ## ----- resampling timing model
  tau0_FFT_h_l = tau0_FFT(h_or_l)';
  resampInfo.tauF_core   = uvar.tau0_Fbin + (NsampFFT ./ NFbin ) .* ( R .* uvar.tau0_spin + 5 * l2NsampFFT .* tau0_FFT_h_l );
  resampInfo.tauF_buffer = R .* NsampFFT ./ NFbin .* uvar.tau0_bary;
  resampInfo.l2NsampFFT  = l2NsampFFT;

  ## ----- resampling memory model
  MB = 1024 * 1024;
  resampInfo.MBDataPerDetSeg   = ( R .* NsampFFT0 + ( 1 + 2*R) .* NsampFFT ) * 8 / MB;
  resampInfo.MBWorkspace       = ( ( 2 + 3*R ) .* NsampFFT + 4 * NFbin ) * 8 / MB;

  ## ----- demod timing model:
  if ( uvar.Nsft == 0 )
    Nsft = round ( Tcoh ./ Tsft );      ## default: assume gapless
  endif
  demodInfo.tauF_core   = Nsft * uvar.tau0_coreLD;
  demodInfo.tauF_buffer = Nsft ./ NFbin * uvar.tau0_bufferLD;
  ## ----- demod memory model:
  demodInfo.MBDataPerDetSeg =  Nsft .* numBins * 8 / MB;
  ##

  return;

endfunction

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  [resampInfo, demodInfo] = predictFstatTimeAndMemory("Tcoh", 86400, "Freq0", 100, "FreqBand", 1e-2, "dFreq", 1e-7);
%!  assert(isstruct(resampInfo));
%!  assert(isfield(resampInfo, "tauF_core"));
%!  assert(resampInfo.tauF_core > 0);
%!  assert(isfield(resampInfo, "tauF_buffer"));
%!  assert(resampInfo.tauF_buffer > 0);
%!  assert(isfield(resampInfo, "MBDataPerDetSeg"));
%!  assert(resampInfo.MBDataPerDetSeg > 0);
%!  assert(isstruct(demodInfo));
%!  assert(isfield(demodInfo, "tauF_core"));
%!  assert(demodInfo.tauF_core > 0);
%!  assert(isfield(demodInfo, "tauF_buffer"));
%!  assert(demodInfo.tauF_buffer > 0);
%!  assert(isfield(demodInfo, "MBDataPerDetSeg"));
%!  assert(demodInfo.MBDataPerDetSeg > 0);
