## Copyright (C) 2015 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{mtwoF} =} EmpiricalFstatMismatch ( @var{Tcoh}, @var{Tsemi}, @var{mcoh}, @var{msemi} )
## @deftypefnx{Function File} { [ @var{mtwoF}, @var{stwoF} ] =} EmpiricalFstatMismatch ( @var{Tcoh}, @var{Tsemi}, @var{mcoh}, @var{msemi}, @var{scoh}, @var{ssemi} )
##
## Compute an empirical fit, derived from numerical simulations,
## to the F-statistic mismatch as a function of the coherent and
## semicoherent time-spans and metric mismatches.
##
## @heading Arguments
##
## @table @var
## @item mtwoF
## mean F-statistic mismatch
##
## @item stwoF
## standard deviation of F-statistic mismatch
##
## @item Tcoh
## coherent segment time-span, in seconds
##
## @item Tsemi
## semicoherent search time-span, in seconds
##
## @item mcoh
## mean coherent metric mismatch
##
## @item msemi
## mean semicoherent metric mismatch
##
## @item scoh
## standard deviation of coherent metric mismatch
##
## @item ssemi
## standard deviation of semicoherent metric mismatch
##
## @end table
##
## Input variables may also be vectors.
## Note that a non-interpolating search implies @var{mcoh} = 0.
##
## @end deftypefn

function [mtwoF, stwoF] = EmpiricalFstatMismatch(Tcoh, Tsemi, mcoh, msemi, scoh=0, ssemi=0)

  ## load constants
  UnitsConstants;

  ## check input
  narginchk(4, 6);
  assert(all(0 <= Tcoh(:)));
  assert(all(0 <= Tsemi(:)));
  assert(all(0 <= mcoh(:)));
  assert(all(0 <= msemi(:)));
  assert(all(0 <= scoh(:)));
  assert(all(0 <= ssemi(:)));
  [err, Tcoh, Tsemi, mcoh, msemi, scoh, ssemi] = common_size(Tcoh, Tsemi, mcoh, msemi, scoh, ssemi);
  assert(err == 0, "Input variables are not of common size");

  ## normalise time-spans
  Tcoh = Tcoh / DAYS;
  Tsemi = Tsemi / YEARS;

  ## data for mean mismatch fit
  afit = [  1.48126e+00  1.27742e+00  7.99402e-01  7.01600e-01  1.03182e+00 ];
  bfit = [  6.50997e-01  1.03557e+00  9.77561e-01  1.11537e+00  9.96942e-01 ];
  cfit = [ -1.72811e+00 -3.43110e-01 -5.41792e-01 -4.19821e-01 -6.22845e-01 ];
  dfit = [ -1.35307e+00 -9.83193e-01 -1.09032e+00 -9.89340e-01 -1.03754e+00 ];
  efit = [  2.88332e-03  1.38692e+00  9.32447e-02  4.77692e-01  7.48594e-01 ];
  ffit = [  1.50450e-02  6.64467e-01  3.17907e-01  4.87757e-01  7.46120e-01 ];

  ## compute mean mismatch fit
  mtwoF_numer = mtwoF_denom = 0;
  for n = 1:length(afit)
    mtwoF_numer += 1/n .* exp( -( afit(n) + exp( bfit(n) + cfit(n).*Tsemi + dfit(n).*Tcoh ) + efit(n).*msemi + ffit(n).*mcoh ).^2 );
    mtwoF_denom += 1/n .* exp( -( afit(n) + exp( bfit(n) + cfit(n).*Tsemi + dfit(n).*Tcoh ) ).^2 );
  endfor
  mtwoF = 1 - ( mtwoF_numer ./ mtwoF_denom );
  mtwoF(mcoh == 0 & msemi == 0) = 0;
  mtwoF(mcoh == 0 & msemi == inf) = 1;
  mtwoF(mcoh == inf & msemi == 0) = 1;
  mtwoF(mcoh == inf & msemi == inf) = 1;
  mtwoF(mtwoF < 0) = 0;
  mtwoF(mtwoF > 1) = 1;

  ## data for standard deviation mismatch fit
  Nfit = [  2.91007e+00 ];
  Afit = [  8.85679e-01  2.40222e+00  2.03770e+00 ];
  Bfit = [ -3.57936e-01 -3.82609e-01  9.10348e-02 ];
  Cfit = [ -1.10326e-01 -1.70497e-02  5.93494e-02 ];
  Dfit = [  2.09243e+00  2.24303e+00  2.17538e+00 ];
  Efit = [ -2.47166e-03  2.99524e-01  1.95833e-02 ];
  Ffit = [  1.49599e-02  9.18875e-02  9.02407e-01 ];
  Gfit = [ -1.19849e+00 -2.18446e+00 -7.33651e+00 ];
  Hfit = [ -9.40613e-02 -2.64348e+00  1.00000e-05 ];

  ## compute standard deviation mismatch fit
  stwoF = 0;
  for n = 1:length(Afit)
    stwoF += Nfit .* 1/n .* exp( Afit(n) + Bfit(n).*Tsemi + Cfit(n).*Tcoh ) .* exp( -( Dfit(n) + Efit(n).*ssemi + Ffit(n).*scoh ).^2 ) .* ( 1 - exp( Gfit(n).*ssemi + Hfit(n).*scoh ) );
  endfor
  stwoF(scoh == 0 & ssemi == 0) = 0;
  stwoF(stwoF < 0) = 0;

endfunction

%!assert(EmpiricalFstatMismatch(0, 0, 0, 0) == 0)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, 0, 0) == 0)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, 0, 0.5) > 0)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, 0, 0.5) < 1)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, 0.1, 0.5) > 0)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, 0.1, 0.5) < 1)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, 0.1, 50) > 0)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, 0.1, 50) < 1)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, 50, inf) == 1)
%!assert(EmpiricalFstatMismatch(86400, 10*86400, inf, inf) == 1)
