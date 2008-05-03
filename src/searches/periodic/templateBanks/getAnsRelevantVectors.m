%% return matrix of 2(n+1) 'Voronoi-relevant' vectors for An*

function relevants = getAnsRelevantVectors ( dim )

  val1 = dim / ( dim + 1 );
  val0 = - ( 1 / ( dim + 1 ) );

  baseVplus = zeros ( dim, dim + 1 );
  for i = [ 1:dim+1 ]
    p0 = val0 * ones ( 1, i - 1);
    p1 = val0 * ones ( 1, dim - i + 1 );
    baseVplus(i,:) = [ p0, val1, p1 ];
  endfor

  baseVminus = - baseVplus;

  rel0 = [ baseVplus; baseVminus ];

  %% NOTE: similar to getAnsLatticeGenerator(),
  %% we follow our own convention where column == lattice-vectors
  %% so we need to transpose the final result

  rel0 = rel0';

  %% now convert this to a full-rank matrix so we have an n x n generator
  [ generator, base ] = getAnsLatticeGenerator ( dim );
  relevants = base' * rel0;

endfunction %% getAnsRelevantVectors()
