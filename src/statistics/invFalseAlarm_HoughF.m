%% Copyright (C) 2011 Reinhard Prix
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with with program; see the file COPYING. If not, write to the
%% Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%% MA  02111-1307  USA

%% [nth, fAH] = invFalseAlarm_HoughF ( fAH, Nseg, Fth )
%%
%% 'invert' false-alarm function to obtain discrete numer-count threshold nth which comes
%% closest to the desired false-alarm probability fAH0 for Hough-on-Fstat,
%% for given number of segments Nseg, and an F-statistic threshold per segment Fth.
%% A false-alarm is defined as n >= nth segments crossing the threshold Fth in the
%% absence of a signal
%%
%% returns nth and corresponding actual false-alarm probability fAH
%%
%% NOTE: all arguments need to be scalars, use arrayfun() or cellfun() to iterate this
%% over vectors of arguments
%%

function [nth, fAH] = invFalseAlarm_HoughF ( fAH0, Nseg, Fth )
  fn = "invFalseAlarm_HoughF()";

  if ( !isscalar(fAH0) || !isscalar(Nseg) || !isscalar(Fth) )
    error ("%s: All input arguments need to be scalars! fAH0 (%d), Neg (%d), Fth (%d)\n",
           fn, length(fAH0), length(Nseg), length(Fth) );
  endif

  if ( fAH0 < 0 || fAH0 > 1 )
    error ("%s: invalid false-alarm probability range %g not within [0,1]\n", fn, fAH0 );
  endif

  %% very simple and naive implemention: calculate fAH for *all* possible values of n = 1:Nseg
  %% return the one that's closests to fAH0
  %% this could possibly be accelerated by using binary search

  ni = [0:Nseg];

  fct_fA = @(n) falseAlarm_HoughF ( n, Nseg, Fth );
  fAHi = arrayfun ( fct_fA, ni );

  %% now find the closest fAH to fAH0: this is a bit tricky due to the potentially vastly
  %% different scales of these numbers => must not compute direct differences but only ratios!
  %% (or equivalently, differences of logs)
  dfA = abs(log(fAHi) - log(fAH0));
  iMin = find ( dfA == min ( dfA ) );

  nth = ni(iMin);
  fAH = fAHi(iMin);

endfunction
