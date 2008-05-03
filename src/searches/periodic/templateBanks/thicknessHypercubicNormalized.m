function ret = thicknessHypercubicNormalized ( nDim )
  %% normalized thickness of hypercubic grid in nDim dimensions
  ret = 2.^(-nDim) .* nDim.^(nDim/2);
endfunction
