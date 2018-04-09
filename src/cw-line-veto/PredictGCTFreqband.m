## Copyright (C) 2013-2014 David Keitel
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
## @deftypefn {Function File} { [ @var{gct_freq_min}, @var{gct_freq_band}, @var{gct_phys_freq_min}, @var{gct_phys_freq_band} ] =} PredictGCTFreqband ( @var{freq}, @var{freqband}, @var{dFreq}, @var{f1dot}, @var{f1dotband}, @var{df1dot}, @var{f2dot}, @var{f2dotband}, @var{df2dot}, @var{starttime}, @var{duration}, @var{reftime}, @var{Tsft}, @var{blocksRngMed}, @var{Dterms} )
##
## function to predict the frequency band required by a HSGCT search
## based on code snippets from LALSuite program HierarchSearchGCT and on @command{XLALCreateFstatInput()} from lalpulsar
## for older freqband convention (e.g. S6Bucket, S6LV1 runs), see PredictGCTFreqbandLegacy.m
##
## @heading Note
##
## this is for laldemod only, resampling is somewhat different
## @end deftypefn

function [gct_freq_min, gct_freq_band, gct_phys_freq_min, gct_phys_freq_band] = PredictGCTFreqband ( freq, freqband, dFreq, f1dot, f1dotband, df1dot, f2dot, f2dotband, df2dot, starttime, duration, reftime, Tsft, blocksRngMed, Dterms )

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

  ## get frequency and fdot bands at start / mid / end time of sfts by extrapolating from reftime
  numSpins = 2; ## used in ExtrapolatePulsarSpinRange with counting from 0, thus 2 = freq + 2 spindowns
  [fkdot_starttime, fkdotband_starttime] = ExtrapolatePulsarSpinRange ( reftime, starttime, fkdot_reftime, fkdotband_reftime, numSpins );
  midtime = starttime + 0.5*duration;
  [fkdot_midtime, fkdotband_midtime]     = ExtrapolatePulsarSpinRange ( reftime, midtime, fkdot_reftime, fkdotband_reftime, numSpins );
  endtime = starttime + duration;
  [fkdot_endtime, fkdotband_endtime]     = ExtrapolatePulsarSpinRange ( reftime, endtime, fkdot_reftime, fkdotband_reftime, numSpins );

  ## calculate number of bins for Fstat overhead due to residual spin-down
  extraBinsFstat = floor( 0.25*duration*(df1dot+duration*df2dot)/dFreq + 1e-6) + 1;

  ## set wings of sfts to be read
  ## NOTE: contrary to GCT code, do not translate again from midtime to starttime and endtime
  ## This is potentially 'wider' than the physically-requested template bank, and can therefore also require more SFT frequency bins!
  [minCoverFreq, maxCoverFreq] = CWSignalCoveringBand ( fkdot_starttime, fkdotband_endtime, fkdot_endtime, fkdotband_endtime );

  minCoverFreq -= extraBinsFstat * dFreq;
  maxCoverFreq += extraBinsFstat * dFreq;

  ## extra terms for laldemod method
  extraBinsMethod = Dterms;

  ## add number of extra frequency bins required by running median
  extraBinsFull = extraBinsMethod + blocksRngMed/2 + 1;

  ## extend frequency range by number of extra bins times SFT bin width
  extraFreqMethod = extraBinsMethod / Tsft;
  minFreqMethod = minCoverFreq - extraFreqMethod;
  maxFreqMethod = maxCoverFreq + extraFreqMethod;

  extraFreqFull = extraBinsFull / Tsft;
  minFreqFull = minCoverFreq - extraFreqFull;
  maxFreqFull = maxCoverFreq + extraFreqFull;

  ## full band for data readin
  gct_freq_min = minFreqFull;
  gct_freq_band = maxFreqFull - minFreqFull;

  ## physical band e.g. for adaptive oLGX tuning
  gct_phys_freq_min = minFreqMethod;
  gct_phys_freq_band = maxFreqMethod - minFreqMethod;

endfunction ## PredictGCTFreqband()

%!test
%!  [gct_freq_min, gct_freq_band, gct_phys_freq_min, gct_phys_freq_band] = PredictGCTFreqband(100, 0.1, 1e-7, -1e-8, 1e-8, 1e-11, 0, 0, 0, 800000000, 23*3600, 800000000, 1800, 101, 8);
%!  assert([gct_freq_min, gct_freq_band, gct_phys_freq_min, gct_phys_freq_band], [99.956, 0.18897, 99.984, 0.13175], 1e-2)
