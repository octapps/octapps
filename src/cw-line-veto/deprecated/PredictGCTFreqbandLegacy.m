## Copyright (C) 2013 David Keitel
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
## @deftypefn {Function File} { [ @var{gct_freq_min}, @var{gct_freq_band} ] =} PredictGCTFreqbandLegacy ( @var{freq}, @var{freqband}, @var{dFreq}, @var{f1dot}, @var{f1dotband}, @var{df1dot}, @var{f2dot}, @var{f2dotband}, @var{df2dot}, @var{starttime}, @var{duration}, @var{reftime}, @var{deltaFsft}, @var{blocksRngMed}, @var{Dterms} )
##
## function to predict the frequency band required by a HSGCT search
## based on code snippets from LALSuite program HierarchSearchGCT
##
## @heading Note
##
## deltaFsft is usually 1.0/Tsft
##
## @heading Note
##
## this is for S6Bucket era GCT code, for newer versions see PredictGCTFreqband.m
## @end deftypefn

function [gct_freq_min, gct_freq_band] = PredictGCTFreqbandLegacy ( freq, freqband, dFreq, f1dot, f1dotband, df1dot, f2dot, f2dotband, df2dot, starttime, duration, reftime, deltaFsft, blocksRngMed, Dterms )

  ## input checks
  if ( dFreq == 0 )
    error("dFreq=0 will lead to divisions by 0 in calculating extraBinsFstat.");
  endif

  ## copy user specified spin variables at reftime
  ## NOTE: different index conventions between lalapps and octave - (k) here corresponds to [k-1] in LALExtrapolatePulsarSpinRange
  fkdot_reftime(1) = freq;  ## frequency
  fkdot_reftime(2) = f1dot; ## 1st spindown
  fkdot_reftime(3) = f2dot; ## 2nd spindown
  fkdotband_reftime(1) = freqband;  ## frequency range
  fkdotband_reftime(2) = f1dotband; ## 1st spindown range
  fkdotband_reftime(3) = f2dotband; ## 2nd spindown range

  ## calculate number of bins for Fstat overhead due to residual spin-down
  extraBinsFstat = floor( 0.25*duration*(df1dot+duration*df2dot)/dFreq + 1e-6) + 1;

  ## get frequency and fdot bands at start / mid / end time of sfts by extrapolating from reftime
  numSpins = 2; ## used in ExtrapolatePulsarSpinRange with counting from 0, thus 2 = freq + 2 spindowns
  [fkdot_starttime, fkdotband_starttime] = ExtrapolatePulsarSpinRange ( reftime, starttime, fkdot_reftime, fkdotband_reftime, numSpins );
  midtime = starttime + 0.5*duration;
  [fkdot_midtime, fkdotband_midtime]     = ExtrapolatePulsarSpinRange ( reftime, midtime, fkdot_reftime, fkdotband_reftime, numSpins );
  endtime = starttime + duration;
  [fkdot_endtime, fkdotband_endtime]     = ExtrapolatePulsarSpinRange ( reftime, endtime, fkdot_reftime, fkdotband_reftime, numSpins );

  ## calculate total number of bins for Fstat
  binsFstatSearch = floor(fkdotband_midtime(1)/dFreq + 1e-6) + 1;
  gct_freq_bins = binsFstatSearch + 2 * extraBinsFstat;

  ## set wings of sfts to be read
  ## the wings must be enough for the Doppler shift and extra bins
  ##   for the running median block size and Dterms for Fstat calculation.
  ##   In addition, it must also include wings for the spindown correcting
  ##   for the reference time
  ## calculate Doppler wings at the highest frequency
  startTime_freqLo = fkdot_starttime(1);                        ## lowest search freq at start time
  startTime_freqHi = startTime_freqLo + fkdotband_starttime(1); ## highest search freq. at start time
  endTime_freqLo = fkdot_endtime(1);                            ## lowest search freq at end time
  endTime_freqHi = endTime_freqLo + fkdotband_endtime(1);       ## highest search freq. at end time

  freqLo = min ( startTime_freqLo, endTime_freqLo );
  freqHi = max ( startTime_freqHi, endTime_freqHi );

  dopplerMax = 1.05e-4;
  doppWings = freqHi * dopplerMax; ## maximum Doppler wing -- probably larger than it has to be

  extraBins = max ( fix(blocksRngMed/2 + 1), Dterms ); ## do the same rounding as GCT code does implicitly via UINT4 division

  gct_freq_min = freqLo - doppWings - extraBins*deltaFsft - extraBinsFstat*dFreq;
  gct_freq_max = freqHi + doppWings + extraBins*deltaFsft + extraBinsFstat*dFreq;
  gct_freq_band = gct_freq_max - gct_freq_min;

endfunction ## PredictGCTFreqbandLegacy()
