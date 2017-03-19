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

function [tauRS, tauLD, lg2NsampFFT, dtauRSBary] = estimateFstatTime ( varargin )
  %% [tauRS, tauLD, lg2NsampFFT, dtauRSBary] = estimateFstatTime ( varargin )
  %%
  %% estimate F-statistic computation time per frequency bin per detector,
  %% for Demod and Resampling methods of computing F-statistic
  %%
  %% ----- Input parameters:
  %% "Tcoh":	coherent segment length
  %% "Tspan":	total data time-span
  %% "FreqMax":	maximal search frequency
  %% "FreqBand": search frequency band
  %% "dFreq":	search frequency spacing
  %% "f1dotMax":	maximal first-order spindown
  %% "f2dotMax":	maximal 2nd-order spindown
  %% "tauFbin":	Resampling timing coefficient 'tauFbin'
  %% "tauFFT":	Resampling timing coefficient 'tauFFT'
  %% "tauSpin":	Resampling timing coefficient 'tauSpin'
  %% "tauBary":	Resampling timing coefficient 'tauBary'
  %% "tauLDsft": Demod timing coefficient 'tauLDsft': time per SFT per frequency bin
  %% "Tsft":	SFT length [default: 1800]
  %% "Nsft":	Number of sfts
  %%
  %% ----- Return values
  %% tauRS:	Resampling Fstat time per frequency bin per detector assuming perfect buffering (ie excluding barycentering time)
  %% tauLD:	Demod Fstat time per frequency bin per detector assuming perfect buffering  (ie excluding barycentering time)
  %% dtauRSBary: time per detector per frequency bin for resampling barycentering

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
  %% tauRSeff = tauRS + dtauRSBary, where
  %% dtauRSBary = TauBary/NFbin = R * (NsFFT/NFbin) * tauBary
  %%

  ## parse options
  uvar = parseOptions ( varargin,
                        {"Tcoh", 	"strictpos,matrix"},
                        {"Tspan", 	"positive,matrix", 	0},
                        {"FreqMax", 	"strictpos,matrix"},
                        {"FreqBand",	"strictpos,matrix"},
                        {"dFreq",	"strictpos,matrix"},
                        {"f1dotMax",	"real,matrix", 		0},
                        {"f2dotMax", 	"real,matrix", 		0},
                        {"tauFbin",	"strictpos,scalar", 6.1e-8 },
                        {"tauFFT",	"strictpos,scalar", 3.3e-8 },	%% FFT time assuming NFFT>2^18
                        {"tauSpin",	"strictpos,scalar", 7.7e-8 },
                        {"tauBary",	"strictpos,scalar", 2.6e-7 },
                        {"tauLDsft",	"strictpos,scalar", 7.4e-8 },	%% Demod time per SFT
                        {"Tsft",	"strictpos,scalar", 1800 },
                        {"Nsft", 	"positive,scalar", 0}
                      );

  if ( uvar.Tspan == 0 )
    uvar.Tspan = uvar.Tcoh;
  endif
  [err, Tspan, Tcoh, FreqMax, FreqBand, dFreq, f1dotMax, f2dotMax] = common_size ( uvar.Tspan, uvar.Tcoh, uvar.FreqMax, uvar.FreqBand, uvar.dFreq, uvar.f1dotMax, uvar.f2dotMax );
  assert(err == 0, "Input variables are not of common size");

  %% implement Resampling timing model starting from physical parameters
  FreqBandDrift = abs(f1dotMax) .* Tspan + abs(f2dotMax) .* Tspan.^2 / 4;
  UnitsConstants;
  extraPerFreq = 1.05 * (2*pi / C_SI) * ( (AU_SI/YRSID_SI) + (REARTH_SI/DAYSID_SI) );
  %% try and estimate this as closely as possible to what's done in ComputeFstat and XLALCWSignalCoveringBand()
  FreqBandSFT = FreqBand + FreqBandDrift + 2 * FreqMax * extraPerFreq + 16/uvar.Tsft;

  dtDET = 1 ./ FreqBandSFT;
  NFbin = ceil ( FreqBand ./ dFreq );
  D = ceil ( Tcoh .* dFreq );
  TFFT = 1 ./ ( dFreq ./ D );
  NsampFFT0 = floor ( TFFT ./ dtDET );
  lg2NsampFFT = ceil ( log2 ( NsampFFT0 ) );
  NsampFFT  = 2.^lg2NsampFFT;
  dtSRC = TFFT ./ NsampFFT;

  NsampSRC = floor ( Tcoh ./ dtSRC );
  R = Tcoh ./ TFFT;

  tauRS      = uvar.tauFbin + (NsampFFT ./ NFbin ) .* ( R * uvar.tauSpin + uvar.tauFFT );
  dtauRSBary = R .* (NsampFFT ./ NFbin) .* uvar.tauBary;

  if ( uvar.Nsft == 0 )
    Nsft = (Tcoh / uvar.Tsft);
  else
    Nsft = uvar.Nsft;
  endif
  tauLD = Nsft * uvar.tauLDsft;

  return;

endfunction
