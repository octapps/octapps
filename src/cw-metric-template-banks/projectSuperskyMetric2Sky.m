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
## @deftypefn {Function File} {@var{g_aa} =} projectSuperskyMetric2Sky ( @var{g_nn}, @var{alpha0}, @var{delta0} )
##
## returns metric in coordinates [a, ...] = [alpha, delta, ... ] at a given
## sky-position @var{alpha0},@var{delta0}, for the given input 'supersky' metric in coordinates
## [n, ...] = [ nx,ny,nz, ...].
##
## @heading Note
##
## the supersky-coordinates n = [nx,ny,nz] must be the first 3 coordinates of theinput metric @var{g_nn} and the output metric has a = [alpha,delta] as the first 2 coordinates
##
## @end deftypefn

function g_aa = projectSuperskyMetric2Sky ( g_nn, alpha0, delta0 )

  assert ( issymmetric ( g_nn ) > 0, "Input supersky metric 'g_nn' must be a symmetric square matrix" );
  nDim = columns(g_nn);
  assert ( nDim >= 3, "Input supersky metric must be at least 3x3 (got %dx%d)", nDim, nDim);

  ## jakobian d [n,fkdot] / d [a,fkdot]  (rows n^i, columns a^j}
  sind = sin(delta0); cosd = cos(delta0);
  sina = sin(alpha0); cosa = cos(alpha0);
  jak_n_a = [
             - cosd * sina, - sind * cosa;
             cosd * cosa, - sind * sina;
             0,   cosd
  ];
  nfkdot = nDim - 3;
  B_n_k = zeros ( 3, nfkdot );
  B_k_a = zeros(nfkdot, 2);
  C_k_k = eye ( nfkdot, nfkdot);

  Jak_n_a = [ jak_n_a,  B_n_k;
              B_k_a,  C_k_k;
            ];
  Jak_a_n = Jak_n_a';

  g_aa = Jak_a_n * g_nn * Jak_n_a;

  g_aa = 0.5 * ( g_aa + g_aa'); ## re-symmetriz (may be require due to numerical noise)

  return;
endfunction

%!test
%!  ## lalapps_FstatMetric_v2 -o gnn.dat --Alpha=1 --Delta=1 --coords="n3x_equ,n3y_equ,n3z_equ,freq,f1dot,f2dot"
%!  ## lalapps_FstatMetric_v2 -o gaa.dat --Alpha=1 --Delta=1 --coords="alpha,delta,freq,f1dot,f2dot"
%!  gnn = [
%!   9.7162064407348633e+04,  1.6162401439666748e+05,  6.9920271533966064e+04,  2.0355045456878051e+07, -1.4588751710937500e+09,  6.5922495973127800e+14;
%!   1.6162401439666748e+05,  2.6886818181991577e+05,  1.1631187004089355e+05,  3.3860346089623548e+07, -1.2671848879843750e+09,  1.0971813972709620e+15;
%!   6.9920271533966064e+04,  1.1631187004089355e+05,  5.0317088542461395e+04,  1.4648181998421121e+07, -8.1788653728125000e+08,  4.7469871192193475e+14;
%!   2.0355045456878051e+07,  3.3860346089623548e+07,  1.4648181998421121e+07,  4.2643423299322696e+09, -2.4811145795203839e+11,  1.3819371887744971e+17;
%!  -1.4588751710937500e+09, -1.2671848879843750e+09, -8.1788653728125000e+08, -2.4811145795203839e+11,  9.2138764319991376e+16, -1.3400518435962927e+19;
%!   6.5922495973127800e+14,  1.0971813972709620e+15,  4.7469871192193475e+14,  1.3819371887744971e+17, -1.3400518435962927e+19,  5.3316716910947309e+24;
%!  ];
%!
%!  gaa = [
%!   9.4392684805173118e+01, -3.7432745970430642e+03,  6.3033986158817098e+05,  2.9335076680322605e+08,  2.0580635047683145e+13;
%!  -3.7432745970430642e+03,  1.5028899244227595e+05, -2.5315559717512231e+07,  1.1186296727757726e+09, -8.2011995357922125e+14;
%!   6.3033986158817098e+05, -2.5315559717512231e+07,  4.2643423299322696e+09, -2.4811145795203839e+11,  1.3819371887744971e+17;
%!   2.9335076680322605e+08,  1.1186296727757726e+09, -2.4811145795203839e+11,  9.2138764319991376e+16, -1.3400518435962927e+19;
%!   2.0580635047683145e+13, -8.2011995357922125e+14,  1.3819371887744971e+17, -1.3400518435962927e+19,  5.3316716910947309e+24;
%!  ];
%!
%!  alpha=1; delta=1;
%!  gaa2 = projectSuperskyMetric2Sky ( gnn, alpha, delta );
%!  tol = -1e-8;        ## relative tolerance passes as <0 !
%!  assert ( gaa, gaa2, tol );
