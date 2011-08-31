%% Calculates the approximate scaling of the sensitivity constant "Q",
%% by using the mean value of "R^2" instead of its distribution, and
%% a normal approximation to the non-central chi^2 distribution
%% Syntax:
%%   Q0 = RoughScalingQ(pd, k, sa, Rsqr)
%% where:
%%   Q0     = scaling of sensitivity constant
%%   pd     = false dismissal probability / rate
%%   N      = number of segments
%%   k      = statistical degrees of freedom per segment
%%   sa     = false alarm threshold on statistic per segment
%%   Rsqr   = histogram of "R^2" component of the optimal SNR
function Q0 = RoughScalingQ(pd, N, k, sa, Rsqr)

  %% check input
  assert(isHist(Rsqr));

  %% make N, pd, k, and sa common size
  [errcode, N, pd, k, sa] = common_size(N, pd, k, sa);
  if errcode > 0
    error("Input arguments 'N', 'pd', 'k', and 'sa' must be either the same size or scalars");
  endif

  %% use the mean value of "R^2" instead of its distribution
  mRsqr = meanOfHist(Rsqr);

  %% calculate scaling of Q, assuming normal approximation to non-central chi^2 c.d.f
  c = sqrt(8) .* erfinv(2.*pd - 1) ./ sqrt(N);
  Q0 = (sqrt(c.^2 + 4.*(sa - k)) - c) ./ (2 .* sqrt(mRsqr));

endfunction
