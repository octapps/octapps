#!/usr/bin/octave

function ret = CoxeterFewRogersBoundNormalized ( n )
  ## Coxter-Few-Rogers bound on normalized thickness in dimension n
  ret = ( 2 * n  ./ ( n + 1 ) ) .^ ( n/2 ) .* RogersBoundNormalized ( n );

endfunction
