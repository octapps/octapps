## Copyright (C) 2011 Karl Wette
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
## @deftypefn {Function File} {@var{Fsqr_t} =} TimeAvgSqrAntennaPattern ( @var{a0}, @var{b0}, @var{x}, @var{y}, @var{zeta}, @var{OmegaT}, @var{nmax} )
##
## Calculate the time-averaged squared antenna pattern of an interferometer
##
## @heading Arguments
##
## @table @var
## @item Fsqr_t
## time-averaged squared antenna pattern
##
## @item a0
## @itemx b0
## detector null vectors at observation mid-point,
## in equatorial coordinates
##
## @item x
## @itemx y
## polarisation null vectors in equatorial coordinates
##
## @item zeta
## angle between interferometer arms in radians
##
## @item OmegaT
## product of angular sidereal frequency and observation time
##
## @item nmax
## maximum sinc term to add up (0 to 4; default is 4)
##
## @end table
##
## @end deftypefn

function Fsqr_t = TimeAvgSqrAntennaPattern(a0, b0, x, y, zeta, OmegaT, nmax)

  ## check input arguments
  if isinf(OmegaT)
    ## OmegaT==inf implies nmax=0
    OmegaT = 0;
    if exist("nmax")
      error("%s: cannot use nmax with OmegaT=inf", funcName);
    endif
    nmax = 0;
  elseif !exist("nmax")
    nmax = 4;
  endif

  ## make sure input are the same size
  if isscalar(zeta)
    zeta .*= ones(1, size(a0, 2));
  elseif !(isvector(zeta) && length(zeta) == size(a0, 2))
    error("%s: zeta is not the right size", funcName);
  endif
  if isscalar(OmegaT)
    OmegaT .*= ones(1, size(a0, 2));
  elseif !(isvector(OmegaT) && length(OmegaT) == size(a0, 2))
    error("%s: OmegaT is not the right size", funcName);
  endif
  assert(all(size(a0) == size(b0)));
  assert(all(size(b0) == size(x)));
  assert(all(size(x) == size(y)));

  ## rotationally split components of a0 and b0
  zros = zeros(1, size(a0, 2));
  a0i = b0i = cell(1, 3);
  a0i{1} = [ a0(1,:); a0(2,:); zros ];    ## cross(cross(Omega_c, a0), Omega_c)
  b0i{1} = [ b0(1,:); b0(2,:); zros ];    ## cross(cross(Omega_c, b0), Omega_c)
  a0i{2} = [ -a0(2,:); a0(1,:); zros ];   ## cross(Omega_c, a0)
  b0i{2} = [ -b0(2,:); b0(1,:); zros ];   ## cross(Omega_c, b0)
  a0i{3} = [ zros; zros; a0(3,:) ];       ## dot(Omega_c, a0) Omega_c
  b0i{3} = [ zros; zros; b0(3,:) ];       ## dot(Omega_c, b0) Omega_c

  ## "JKS" expressions and sinc coefficients
  C = zeros(nmax+1, size(a0, 2));
  if nmax >= 0
    Jp3 = JKSexpr("J", +3, a0i, b0i, x, y);
    Km3 = JKSexpr("K", -3, a0i, b0i, x, y);
    Kp1 = JKSexpr("K", +1, a0i, b0i, x, y);
    Kp2 = JKSexpr("K", +2, a0i, b0i, x, y);
    Sm3 = JKSexpr("S", -3, a0i, b0i, x, y);
    C(0+1,:) = 2.375.*Jp3.^2 + 0.125.*Km3.^2 + 0.5.*(Kp1.^2 + Kp2.^2 + Sm3.^2);
  endif
  if nmax >= 1
    Jm1 = JKSexpr("J", -1, a0i, b0i, x, y);
    Kp3 = JKSexpr("K", +3, a0i, b0i, x, y);
    C(1+1,:) = (2.5.*Jp3 - Jm1).*Kp2 + 0.5.*Kp1.*Kp3;
  endif
  if nmax >= 2
    Jm3 = JKSexpr("J", -3, a0i, b0i, x, y);
    C(2+1,:) = 1.5.*Jm3.*Jp3 + 0.5.*(Kp2.^2 - Kp1.^2);
  endif
  if nmax >= 3
    C(3+1,:) = 0.5.*(Jm3.*Kp2 - Kp1.*Kp3);
  endif
  if nmax >= 4
    C(4+1,:) = 0.125.*(Jm3.^2 - Kp3.^2);
  endif

  ## time-averaged squared antenna pattern
  Fsqr_t = zros;
  for n = 0:nmax
    Fsqr_t += C(n+1,:) .* sinc((n/2).*OmegaT);
  endfor
  Fsqr_t .*= sin(zeta).^2;

endfunction

## calculate "JKS" expressions
function JKS = JKSexpr(expr, i, a0i, b0i, x, y)
  zeta = pi/2;
  ip  = mod(i,  3) + 1;
  ipp = mod(ip, 3) + 1;
  if strcmp(expr, "J") || strcmp(expr, "S")
    Bipip   = AntennaPattern(a0i{ip }, b0i{ip }, x, y, zeta);
    Bippipp = AntennaPattern(a0i{ipp}, b0i{ipp}, x, y, zeta);
  endif
  if strcmp(expr, "K") || strcmp(expr, "S")
    Bipipp = AntennaPattern(a0i{ip }, b0i{ipp}, x, y, zeta);
    Bippip = AntennaPattern(a0i{ipp}, b0i{ip }, x, y, zeta);
  endif
  if strcmp(expr, "J")
    JKS = Bipip + sign(i).*Bippipp;
  elseif strcmp(expr, "K")
    JKS = Bipipp + sign(i).*Bippip;
  elseif strcmp(expr, "S")
    JKS = sqrt(Bipipp.*Bippip + sign(i).*Bipip.*Bippipp);
  else
    error("%s: invalid JKS expression '%s'", expr);
  endif
endfunction

%!assert(TimeAvgSqrAntennaPattern([1;0;0], [0;1;0], [0;0.5;0.5], [0;0.5;-0.5], pi/2, inf), 0.03125)
