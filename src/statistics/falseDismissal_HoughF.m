%% fDH = falseDismissal_HoughF ( nth, Nseg, Fth, SNR0sq )
%%
%% compute Hough-on-Fstat false-dismissal probability fDH for given number of segments Nseg,
%% a threshold on segment-crossings nth, an F-statistic threshold per segment Fth,
%% and the optimal signal SNR^2 per segment SNR0sq, which is assumed constant across all segments.
%%
%% A false-dismissal is defined as n < nth segments crossing the threshold Fth in the
%% presence of a signal
%%
%% NOTE: all arguments need to be scalars, use arrayfun() or cellfun() to iterate this
%% over vectors of arguments
%%

function fDH = falseDismissal_HoughF ( nth, Nseg, Fth, SNR0sq )
  fn = "falseDismissal_HoughF()";

  if ( !isscalar(nth) || !isscalar(Nseg) || !isscalar(Fth) || !isscalar(SNR0sq) )
    error ("%s: All input arguments need to be scalars! nth (%d), Neg (%d), Fth (%d), SNR0sq (%d)\n",
           fn, length(nth), length(Nseg), length(Fth), length(SNR0sq) );
  endif

  %% eta = threshold-crossing probability for one segment
  fDF = ChiSquare_cdf( 2*Fth, 4, SNR0sq );
  eta = 1 - fDF;

  ni  = [0:(nth-1)];
  bci = bincoeff (Nseg, ni);
  %% printf ("%s: SNR0sq = %g, nth = %d, Fth = %g, eta = %g\n", fn, SNR0sq, nth, Fth, eta );
  logpni = log(bci) + ni * log(eta) + (Nseg - ni) * log1p( - eta );

  fDH = sum ( exp ( logpni ) );

endfunction
