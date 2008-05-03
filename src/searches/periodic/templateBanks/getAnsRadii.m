%% Return packing- and covering-radius for An* lattice in n dimensions
%% referring to lattice-definition corresponding to the generator
%% returned by getAnsLatticeGenerator.m, or Eq.(76) in Conway&Sloane:
function [ packingRadius, coveringRadius ] = getAnsRadii ( dim )

  %% covering Radius of An* is R = sqrt( n*(n+2) / (12*(n+1)) ), see \ref CS99 */
  coveringRadius = sqrt ( 1.0 * dim * (dim + 2.0) / (12.0 * (dim + 1) ));

  packingRadius = coveringRadius * sqrt ( 3 / ( dim + 2) );

  return;

endfunction %% getAnsRadii()
