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

%% fAH = falseAlarm_HoughF ( nth, Nseg, Fth )
%%
%% compute Hough-on-Fstat false-alarm probability fAH for given number of segments Nseg,
%% a threshold on segment-crossings nth, and an F-statistic threshold per segment Fth.
%% A false-alarm is defined as n >= nth segments crossing the threshold Fth in the
%% absence of a signal
%%
%% NOTE: all arguments need to be scalars, use arrayfun() or cellfun() to iterate this
%% over vectors of arguments
%%

function fAH = falseAlarm_HoughF ( nth, Nseg, Fth )
  fn = "falseAlarm_HoughF()";

  if ( !isscalar(nth) || !isscalar(Nseg) || !isscalar(Fth) )
    error ("%s: All input arguments need to be scalars! nth (%d), Neg (%d), Fth (%d)\n",
           fn, length(nth), length(Nseg), length(Fth) );
  endif

  alpha = falseAlarm_chi2 ( 2 * Fth, 4 );

  ni  = [nth:Nseg];
  bci = bincoeff (Nseg, ni);

  logpni = log(bci) + ni * log(alpha) + (Nseg - ni) * log1p( - alpha );
  fAH = sum ( exp ( logpni ) );

endfunction
