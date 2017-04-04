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

function resampInfo = predictResampTimeAndMemory ( varargin )
  %% resampInfo = predictResampTimeAndMemory ( varargin )
  %%
  %% predict Resampling F-statistic computation time per frequency bin per detector ('tauRS', 'dtauRSBary'),
  %% and memory requirements ('memWorkspace', 'memData', 'memOutput')
  %%
  %% ----- Input parameters:
  %% "Tcoh":     coherent segment length
  %% "Tspan":    total data time-span
  %% "Freq0":     start search frequency
  %% "FreqBand": search frequency band
  %% "dFreq":    search frequency spacing
  %% "f1dot0","f1dotBand": first-order spindown range [f1dot0, f1dot0+f1dotBand]
  %% "f2dot0","f2dotBand": 2nd-order spindown range [f2dot0,f2dot0+f2dotBand]
  %% "Dterms":   number of 'Dterms' used in sinc-interpolation
  %% "tauFbin":  Resampling timing coefficient 'tauFbin'
  %% "tauFFT":   Resampling timing coefficient 'tauFFT': can be 2-element vector (t1, t2): use t1 if lg2(NsampFFT) <= 18, t2 otherwise
  %% "tauSpin":  Resampling timing coefficient 'tauSpin'
  %% "tauBary":  Resampling timing coefficient 'tauBary'
  %% "Tsft":     SFT length [default: 1800]
  %% "refTimeShift": offset of reference time from starttime, measured in units of Tspan, ie refTimeShift = (refTime - startTime)/Tspan
  %%
  %% ----- Return values
  %% struct 'resampInfo' with fields
  %% tauRS:            Resampling Fstat time per frequency bin per detector assuming perfect buffering (ie excluding barycentering time) [in seconds]
  %% dtauRSBary:       time per detector per frequency bin for resampling barycentering,  [in seconds]
  %%                   total "effective" resampling time per detector per bin: tauRSeff = tauRS + b * dtauRSBary
  %% lg2NsampFFT:      log_2 ( NsampFFT): number of FFT samples = 2 ^ lg2NsampFFT
  %% MBWorkspace:      memory for (possibly shared) workspace [in MBytes]
  %% MBDataPerDetSeg:  memory to hold all data *per detector*, *per-segment* (original+buffered) [in MBytes]
  %%                   ie total data memory would be memData[all] = Nseg * Ndet * memDataPerDetSeg
  %%
  %% ----- Resampling timing model ----------
  %% See the resampling F-stat notes at https://dcc.ligo.org/LIGO-T1600531-v2 for a detailed
  %% description of the resampling timing model
  %%
  %% tauRS = (TauTotal - b*TauBary) / NFbin
  %% tauRS-predicted = tauFbin + (NsFFT/NFbin) * ( R * tauSpin + tauFFT )
  %% with the frequency resolution in natural units, R = Tspan / T_FFT = NsSRC / NsFFT,
  %% Total time per detector generally contains an additional barycentering contribution b * TauBary,
  %% where the buffering weight b = 1/N_{f1dot,f2dot,..} goes to 0 for many spindowns per sky+binary template
  %% Including the maximal barycentering contribution (assuming no buffering, ie b=1) to the Resampling time per frequency bin is
  %% tauRSeff = tauRS + b * dtauRSBary, where
  %% dtauRSBary = TauBary/NFbin = R * (NsFFT/NFbin) * tauBary
  %%

  ## parse options
  uvar = parseOptions ( varargin,
                        {"Tcoh",        "strictpos,matrix"},
                        {"Tspan",       "positive,matrix",      0},
                        {"Freq0",       "strictpos,matrix"},
                        {"FreqBand",    "positive,matrix"},
                        {"dFreq",       "strictpos,matrix"},
                        {"f1dot0", 	"real,matrix",   0},
                        {"f1dotBand", 	"real,matrix",   0},
                        {"f2dot0",      "real,matrix",   0},
                        {"f2dotBand",   "real,matrix",   0},
                        {"refTimeShift", "matrix",    0.5 },
                        {"tauFbin",     "strictpos,scalar", 6.1e-8 },
                        {"tauFFT",      "strictpos,vector", [1.5e-08, 3.4e-8] },   %% FFT time (t1, t2) where t1 if lg2(NsampFFT) <= 18, t2 otherwise
                        {"tauSpin",     "strictpos,scalar", 7.7e-8 },
                        {"tauBary",     "strictpos,scalar", 2.6e-7 },
                        {"Dterms",      "strictpos,matrix", 8 },
                        {"Tsft",        "strictpos,scalar", 1800 }
                      );

  if ( uvar.Tspan == 0 )
    uvar.Tspan = uvar.Tcoh;
  endif
  assert ( length(uvar.tauFFT) == 1 || length(uvar.tauFFT) == 2, "tauFFT can be scalar or 2-element vector");

  [err, Tspan, Tcoh, Freq0, FreqBand, dFreq, f1dot0, f1dotBand, f2dot0, f2dotBand, refTimeShift, Dterms] = common_size ( uvar.Tspan, uvar.Tcoh, uvar.Freq0, uvar.FreqBand, uvar.dFreq, uvar.f1dot0, uvar.f1dotBand, uvar.f2dot0, uvar.f2dotBand, uvar.refTimeShift, uvar.Dterms );
  assert(err == 0, "Input variables are not of common size");
  len = length ( Tspan(:) );
  %% deal with potentially FFT-length-dependent FFT-timing
  if ( length ( uvar.tauFFT ) == 1 )
    tauFFT = [ uvar.tauFFT, uvar.tauFFT ];
  else
    tauFFT = uvar.tauFFT;
  endif
  lg2NsampFFT_sep = 18;	%% <= this, use tauFFT(1), above use tauFFT(2)

  %% try and estimate sidebands as closely as possible to what's done in ComputeFstat and XLALCWSignalCoveringBand()
  FreqBandLoad = zeros ( size(Tspan) );
  fudge_up = 1 + 10 * eps;
  fudge_down = 1 - 10 * eps;
  for i = 1 : len
    startEpoch = 0;
    endEpoch = Tspan(i);
    refTime = refTimeShift(i) * Tspan(i);
    fkdotRef     = [ Freq0(i),    f1dot0(i),    f2dot0(i) ];
    fkdotBandRef = [ FreqBand(i), f1dotBand(i), f2dotBand(i) ];
    [fkdot_epoch1, fkdotband_epoch1] = ExtrapolatePulsarSpinRange ( refTime, startEpoch, fkdotRef, fkdotBandRef, 2 );
    [fkdot_epoch2, fkdotband_epoch2] = ExtrapolatePulsarSpinRange ( refTime, endEpoch, fkdotRef, fkdotBandRef, 2 );

    minCoverFreq = min( [fkdot_epoch1(1), fkdot_epoch2(1)] );
    maxCoverFreq = max( [ fkdot_epoch1(1) + fkdotband_epoch1(1), fkdot_epoch2(1) + fkdotband_epoch2(1)] );
    UnitsConstants;
    extraPerFreq = 1.05 * (2*pi) / C_SI * ( (AU_SI/YRSID_SI) + (REARTH_SI/DAYSID_SI) );
    %% FIXME add binary parameter support here
    %% if ( binaryMaxAsini > 0 ) {
    %% REAL8 maxOmega = LAL_TWOPI / binaryMinPeriod;
    %% extraPerFreq += maxOmega * binaryMaxAsini / ( 1.0 - binaryMaxEcc );
    %% }
    %% Expand frequency range
    minCoverFreq *= (1.0 - extraPerFreq);
    maxCoverFreq *= (1.0 + extraPerFreq);
    minFreq = minCoverFreq - 8 / uvar.Tsft;
    maxFreq = maxCoverFreq + 8 / uvar.Tsft;
    iMin = floor ( minFreq * uvar.Tsft * fudge_up );
    iMax = ceil  ( maxFreq * uvar.Tsft * fudge_down );
    numBins = ( iMax - iMin + 1 );
    FreqBandLoad(i) = numBins / uvar.Tsft;
  endfor

  FreqBandSFT  = FreqBandLoad .* ( 1 + 4 ./ ( 2 * Dterms + 1 ) );

  dtDET = 1 ./ FreqBandSFT;
  NFbin = ceil ( FreqBand ./ dFreq );
  D = ceil ( Tcoh .* dFreq );
  TFFT = 1 ./ ( dFreq ./ D );
  NsampFFT0 = floor ( TFFT ./ dtDET );
  lg2NsampFFT = ceil ( log2 ( NsampFFT0 ) );
  h_or_l = ones ( size(lg2NsampFFT)) + ( lg2NsampFFT > lg2NsampFFT_sep );
  NsampFFT  = 2.^lg2NsampFFT;
  dtSRC = TFFT ./ NsampFFT;

  NsampSRC = floor ( Tcoh ./ dtSRC );
  R = Tcoh ./ TFFT;

  %% resampling timing components
  tauFFTeff = tauFFT(h_or_l)';
  resampInfo.tauRS      = uvar.tauFbin + (NsampFFT ./ NFbin ) .* ( R * uvar.tauSpin + tauFFTeff );
  resampInfo.dtauRSBary = R .* (NsampFFT ./ NFbin) .* uvar.tauBary;
  resampInfo.lg2NsampFFT = lg2NsampFFT;

  %% resampling memory model
  MB = 1024 * 1024;
  resampInfo.MBWorkspace       = ( 3 * NsampFFT .* ( 1 + R ) + 4 * NFbin ) * 8 / MB;
  resampInfo.MBDataPerDetSeg   = R .* ( NsampFFT0 + 2 * NsampFFT ) * 8 / MB;

  %%
  return;

endfunction
