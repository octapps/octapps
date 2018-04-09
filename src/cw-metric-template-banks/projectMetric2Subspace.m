## Copyright (C) 2013 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {@var{gProj_ss} =} projectMetric2Subspace ( @var{g_ij}, @var{sSpace} )
##
## function to compute the 'projection' of a given symmetric metric @var{g_ij}'
## onto the s-subspace defined by coordinates @var{sSpace} = [s1,s2,...], which is a vector of coordinate-indices
##
## If we denotes the indices of the projection-subspace as s and the remaining coordinates
## as k, such that for an n-dimensional space, writing vn = @{1,2,...n@}, we have k = vn \ @var{sSpace},
## then the projection operation is defined as
##
## gProj_@{ss'@} = g_@{ss'@} - gkInv^@{kk'@} g_@{ks@} g_@{k's'@}
##
## where gkInv is the inverse matrix of g_@{kk'@}, ie the inverse of g restricted to the k-subspace excluding coordinates 's'
##
## @heading Notes
## @enumerate
## @item
## this function generalizes projectMetric(@var{g_ij},k1) to projecting out more than one dimension k = [k1,k2,...],
## contrary to @command{projectMetric()}, we only return the projected metric of the subspace, ie gProj_@{ss'@}
##
## @item
## gProj_@{ss'@} gives the smallest possible distance mMin = gProj_@{ss'@} dl^@{s@} dl^@{s'@} of the general distance
## function m = g_@{ij@} dl^@{i@} dl^@{j@} if we fix the offset in the s-subspace, if for fixed dl^@{s@}, if one can freely
## vary the remaining coordinate offsets dl^@{k@}
##
## @item
## gProj_@{ss'@} is just the Schur complement of g_@{kk'@}, see https://en.wikipedia.org/wiki/Schur_complement
##
## @end enumerate
##
## @end deftypefn

function gProj_ss = projectMetric2Subspace ( g_ij, sSpace )

  assert ( issymmetric ( g_ij ) > 0, "Input metric 'g_ij' must be a symmetric square matrix" );

  n = columns ( g_ij );

  nSpace = [1:n];
  kSpace = setdiff ( nSpace, sSpace );  ## coordinates of complementary k-space

  gkk = g_ij( kSpace, kSpace );
  gks = g_ij( kSpace, sSpace );
  gsk = g_ij( sSpace, kSpace );  ## = gks'
  gss = g_ij( sSpace, sSpace );

  gkInv = inv ( gkk );

  gProj_ss = gss - gsk * gkInv * gks;

  gProj_ss = 0.5 * ( gProj_ss + gProj_ss' );    ## re-symmetrize (may be required due to numerical noise)

  return;

endfunction

%!shared gij, tol
%!  rand("seed", 2); tmp = rand(4,4); gij = (tmp + tmp'); ## 4x4 pos-definite matrix, det~3.6, cond~9
%!  tol = 10*eps;

%!test
%!  sSpace1 = [2,3,4]; g1_old = projectMetric ( gij, 1 )(sSpace1,sSpace1); g1_new = projectMetric2Subspace(gij, sSpace1);
%!  assert ( g1_old, g1_new, tol );

%!test
%!  sSpace2 = [1,3,4]; g2_old = projectMetric ( gij, 2 )(sSpace2,sSpace2); g2_new = projectMetric2Subspace(gij, sSpace2);
%!  assert ( g2_old, g2_new, tol );

%!test
%!  sSpace12 = [3,4]; g12_old = projectMetric( projectMetric ( gij, 2 ), 1)(sSpace12,sSpace12); g12_new = projectMetric2Subspace(gij, sSpace12);
%!  assert ( g12_old, g12_new, tol );
