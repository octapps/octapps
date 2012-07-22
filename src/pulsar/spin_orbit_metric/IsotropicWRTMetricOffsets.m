function dp = IsotropicWRTMetricOffsets(dp, V, D, mu, method)

  ## Check input
  assert(isvector(mu));
  mu = mu(:)';
  assert(size(dp, 1) == size(V, 1));
  assert(size(dp, 2) == length(mu));

  if method
  
    ## Rescale dp to give mismatch of mu
    rescale = sqrt(mu) ./ norm(dp, "cols");
    for i = 1:size(dp, 1)
      dp(i, :) .*= rescale;
    endfor
    
    ## Transform points
    dp = V * inv(sqrt(D)) * V' * dp;

  else

    dp = inv(sqrt(D)) * dp;
    
    rescale = sqrt(mu ./ dot(dp, D * dp));
    for i = 1:size(dp, 1)
      dp(i, :) .*= rescale;
    endfor
    
    dp = V * dp;

  endif

  

endfunction
