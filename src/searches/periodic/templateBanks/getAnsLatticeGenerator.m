%% generating matrix from Eq.(76) in Conway&Sloane99:
%% adapted from implementation in LAL/packages/pulsar/src/LatticeCovering.c:XLALGetLatticeGenerator()
function [ generator, base ] = getAnsLatticeGenerator ( dim )

  gen0 = zeros(dim,dim+1);
  for row = [1:dim]

    for col = [1:dim+1]
      %% ---------- find value for that matrix element ----------*/
      if ( row < dim )

	if ( col == 1 )
	  val = 1.0;
	elseif (col == row + 1)
	  val = -1.0;
	else
	  continue;
	endif
      else
	if ( col == 1 )
	  val = - 1.0 * dim / ( dim + 1.0);
	else
	  val =   1.0 / (dim + 1.0);
	endif
      endif
      %% ---------- set matrix element ---------- */
      gen0 ( row, col ) = val;

    endfor %% for col < dim + 1

  endfor %% for row < dim

  %% NOTE: the above is the An* generator in C&S99 conventions,
  %% i.e. each *LINE* of the generator-matrix represents one lattice vector.
  %% However, for some stupid reason, the idiot of CQG 24, 481 (2007)
  %% decided to use a convention where the *COLUMNS* of the generator contain
  %% the lattice-vectors. I'm afraid I'm stuck with the latter conventions now ...

  gen0 = gen0';	%% use transpose matrix: columns == lattice-vectors

  %% now convert this to a full-rank matrix so we have an n x n generator
  base = orth ( gen0 );
  generator = base' * gen0;

  return;

endfunction %% getAnsLatticeGenerator()
