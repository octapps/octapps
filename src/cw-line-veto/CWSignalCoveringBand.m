function [minCoverFreq, maxCoverFreq] = CWSignalCoveringBand  ( fkdot_starttime, fkdotband_starttime, fkdot_endtime, fkdotband_endtime )
 %% [minCoverFreq, maxCoverFreq] = CWSignalCoveringBand  ( fkdot_starttime, fkdotband_starttime, fkdot_endtime, fkdotband_endtime )
 %% based on XLALCWSignalCoveringBand() by R. Prix
 %% Determines a frequency band which covers the frequency evolution of a band of CW signals between two GPS times.
 %% The calculation accounts for the spin evolution of the signals, and the maximum possible Dopper modulation due to detector motion.
 %% binary orbital motion, which is supported by XLALCWSignalCoveringBand(), is dropped here.
 %% contrary to XLALCWSignalCoveringBand, fkdot and fkdotband must be pre-extrapolated to starttime, endtime

 % Determine the minimum and maximum frequencies covered
 minCoverFreq = min( fkdot_starttime(1), fkdot_endtime(1) );
 maxCoverFreq = max( fkdot_starttime(1) + fkdotband_starttime(1), fkdot_endtime(1) + fkdotband_endtime(1) );

 % Extra frequency range needed due to detector motion, per unit frequency
 % Maximum value of the time derivative of the diurnal and (Ptolemaic) orbital phase, plus 5% for luck
 c = 299792458;
 AU = 1.4959787066e11;
 Rearth = 6.378140e6;
 sidyr = 31558149.8;
 sidday = 86164.09053;
 extraPerFreq = 1.05 * 2.0 * pi / c * ( (AU/sidyr) + (Rearth/sidday) );

 % Expand frequency range
 minCoverFreq *= 1.0 - extraPerFreq;
 maxCoverFreq *= 1.0 + extraPerFreq;

endfunction # CWSignalCoveringBand()
