## Copyright (C) 2016 Reinhard Prix
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

function [tauRS, tauLD, lg2NsampFFT] = estimateFstatTime ( varargin )
  %% estimate F-statistic computation time per template (incl. frequency bins)
  %% for given search parameters

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
  FreqBandDrift = 2e-4 * FreqMax + abs(f1dotMax) .* Tspan + abs(f2dotMax) .* Tspan.^2 / 4;
  FreqBandSFT = FreqBand + FreqBandDrift + 16/uvar.Tsft;

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

  tauRS = uvar.tauFbin + (NsampFFT ./ NFbin ) .* ( R * uvar.tauSpin + uvar.tauFFT );
  if ( uvar.Nsft == 0 )
    Nsft = (Tcoh / uvar.Tsft);
  else
    Nsft = uvar.Nsft;
  endif
  tauLD = Nsft * uvar.tauLDsft;

  return;

endfunction
