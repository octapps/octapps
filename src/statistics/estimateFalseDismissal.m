function [fDEst, dfDEst] = estimateFalseDismissal ( fA, stat_0, stat_s )
  %% [fDEst, dfDEst] = estimateFalseDismissal ( fA, stat_0, stat_s )
  %% function to estimate false-dismissals plus Jackknife error-estimates for given false-alarms
  %% and samples of the statistic in no-signal case (stat_0) and in case of signal+noise (stat_s)
  %% new version 2011/01: for N<100 samples, just calculate fDest without errors; for N>100, but not multiple, truncate to closest multiple

  Nbins      = length ( fA );
  Nsamples_0 = length ( stat_0 );
  Nsamples_s = length ( stat_s );

  stat_thresh = empirical_inv (1 - fA, stat_0 );
  fDEst       = empirical_cdf ( stat_thresh, stat_s );

  if ( length(stat_0) < 100 || length(stat_s) < 100 )
    dfDEst = zeros(1,length(fDEst));
    printf("Warning: In function estimateFalseDismissal: Cannot reshape sample array because length=%d smaller than 100. No errors have been computed.\n", length(stat_0));

  else
    g = 100;

    if ( round(length(stat_0)/g) != length(stat_0)/g || round(length(stat_s)/g) != length(stat_s)/g )

      printf("Warning: In function estimateFalseDismissal: Cannot reshape sample array because \n\
          length=%d is not multiple of 100. Samples are truncated to closest multiple for error computation.\n", length(stat_0));
      stat_0 = resize (stat_0, 1, g*floor(length(stat_0)/g));
      stat_s = resize (stat_s, 1, g*floor(length(stat_s)/g));

    endif

    h_0 = round(Nsamples_0 / g );
    h_s = round(Nsamples_s / g );
    %% Jackknife error-estimate on g=100 subgroups
    stat_0_j = reshape ( stat_0, g, Nsamples_0/g );
    stat_s_j = reshape ( stat_s, g, Nsamples_s/g );

    diffs_j = zeros(g, Nbins);
    for j = 1:g
      thresh_j     = empirical_inv (1 - fA, stat_0_j(j,:) );
      fD_j         = empirical_cdf ( thresh_j, stat_s_j(j,:) );
      diffs_j(j,:) = fD_j - fDEst;
    endfor

    varfD = 1/(g * (g-1)) * sumsq ( diffs_j, 1 );

    dfDEst = sqrt ( varfD );

  endif

endfunction
