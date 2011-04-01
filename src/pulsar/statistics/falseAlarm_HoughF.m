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

  alpha = falseAlarm_2F ( 2 * Fth );

  ni  = [nth:Nseg];
  bci = bincoeff (Nseg, ni);

  logpni = log(bci) + ni * log(alpha) + (Nseg - ni) * log1p( - alpha );
  fAH = sum ( exp ( logpni ) );

endfunction
