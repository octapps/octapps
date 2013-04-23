function gProj_ss = projectMetric2Subspace ( g_ij, sSpace )
  %% gProj_ss = projectMetric2Subspace ( g_ij, sSpace )
  %%
  %% function to compute the 'projection' of a given symmetric metric 'g_ij'
  %% onto the s-subspace defined by coordinates sSpace = [s1,s2,...], which is a vector of coordinate-indices
  %%
  %% If we denotes the indices of the projection-subspace as s and the remaining coordinates
  %% as k, such that for an n-dimensional space, writing vn = {1,2,...n}, we have k = vn \ sSpace,
  %% then the projection operation is defined as
  %%
  %% gProj_{ss'} = g_{ss'} - gkInv^{kk'} g_{ks} g_{k's'}
  %%
  %% where gkInv is the inverse matrix of g_{kk'}, ie the inverse of g restricted to the k-subspace excluding coordinates 's'
  %%
  %% Note 1: this function generalizes projectMetric(g_ij,k1) to projecting out more than one dimension k = [k1,k2,...],
  %%         contrary to projectMetric(), we only return the projected metric of the subspace, ie gProj_{ss'}
  %%
  %% Note 2: gProj_{ss'} gives the smallest possible distance mMin = gProj_{ss'} dl^{s} dl^{s'} of the general distance
  %%         function m = g_{ij} dl^{i} dl^{j} if we fix the offset in the s-subspace, if for fixed dl^{s}, if one can freely
  %%         vary the remaining coordinate offsets dl^{k}
  %%
  %% Note 3: gProj_{ss'} is just the Schur complement of g_{kk'}, see https://en.wikipedia.org/wiki/Schur_complement
  %%

  assert ( issymmetric ( g_ij ), "Input metric 'g_ij' must be a symmetric square matrix" );

  n = columns ( g_ij );

  nSpace = [1:n];
  kSpace = setdiff ( nSpace, sSpace );	%% coordinates of complementary k-space

  gkk = g_ij( kSpace, kSpace );
  gks = g_ij( kSpace, sSpace );
  gsk = g_ij( sSpace, kSpace );  %% = gks'
  gss = g_ij( sSpace, sSpace );

  gkInv = inv ( gkk );

  gProj_ss = gss - gsk * gkInv * gks;

  return;

endfunction


%!test
%! rand("seed", 2); tmp = rand(4,4); gij = (tmp + tmp'); %% 4x4 pos-definite matrix, det~3.6, cond~9
%! tol = 10*eps;
%!
%! sSpace1 = [2,3,4]; g1_old = projectMetric ( gij, 1 )(sSpace1,sSpace1); g1_new = projectMetric2Subspace(gij, sSpace1);
%! assert ( g1_old, g1_new, tol );
%!
%! sSpace2 = [1,3,4]; g2_old = projectMetric ( gij, 2 )(sSpace2,sSpace2); g2_new = projectMetric2Subspace(gij, sSpace2);
%! assert ( g2_old, g2_new, tol );
%!
%! sSpace12 = [3,4]; g12_old = projectMetric( projectMetric ( gij, 2 ), 1)(sSpace12,sSpace12); g12_new = projectMetric2Subspace(gij, sSpace12);
%! assert ( g12_old, g12_new, tol );
