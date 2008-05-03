function ret = normalizedThickness_RandomGrid ( nDim, falseDismissal )
  %% compute the normalized thickness, i.e. number of templates per
  %% volume for unity covering radius [ie mismatch^(1/2)], as
  %% a function of dimension and falseDismissal probability

  ret = - log(falseDismissal) * gamma( nDim/2 + 1 ) ./ pi.^(nDim/2);

endfunction
