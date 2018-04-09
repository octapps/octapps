## Copyright (C) 2013, 2015 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{gctco} =} GCTCoherentMetric ( @code{togct}, @var{phyco}, @var{opt}, @var{val}, @dots{} )
## @deftypefnx{Function File} {@var{phyco} =} GCTCoherentMetric ( @code{tophy}, @var{gctco}, @var{opt}, @var{val}, @dots{} )
##
## Computes the coherent global correlation coordinates, as
## given in Pletsch, PRD 82 042002 (2010)
##
## @heading Arguments
##
## @table @var
## @item phyco
## matrix of physical coordinates: [alpha; delta; freq; f1dot; @var{...}]
##
## @item gctco
## matrix of GCT coordinates; order matches that of @command{GCTCoherentMetric()}
##
## @end table
##
## @heading Options
##
## @heading Options
##
## @table @code
## @item t0
## value of @var{t0}, an overall reference time
##
## @item T
## value of @var{T}, the coherent time span
##
## @item detector
## @var{detector} name, e.g. H1
##
## @item fmax
## maximum frequency to assume when converting sky coordinates
##
## @item sgndelta
## sign of declination when converting to physical coordinates [default: 1]
##
## @item ephemerides
## Earth/Sun @var{ephemerides} from @command{loadEphemerides()}
##
## @item ptolemaic
## use Ptolemaic orbital motion
##
## @end table
##
## @end deftypefn

function outco = GCTCoordinates(mode, inco, varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"t0", "real,scalar"},
               {"T", "real,strictpos,scalar"},
               {"detector", "char"},
               {"fmax", "real,strictpos,scalar"},
               {"sgndelta", "real,vector", 1},
               {"ephemerides", "a:swig_ref", []},
               {"ptolemaic", "logical,scalar", false},
               []);

  ## check options
  smax = size(inco, 1) - 3;
  assert(smax >= 0, "Not enough coordinate dimensions in 'inco'");
  assert(smax <= 2, "Only up to second spindown is supported");
  assert(isempty(strfind(detector, ",")), "Only a single detector is supported");

  ## load ephemerides if needed and not supplied
  if !ptolemaic && isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## get detector information
  multiIFO = new_MultiLALDetector;
  XLALParseMultiLALDetector(multiIFO, XLALCreateStringVector(detector));
  assert(multiIFO.length == 1, "Could not parse detector '%s'", detector);
  detLat = multiIFO.sites{1}.frDetector.vertexLatitudeRadians;
  detLong = multiIFO.sites{1}.frDetector.vertexLongitudeRadians;

  ## get position of GMT at reference time t0
  zeroLong = mod(XLALGreenwichMeanSiderealTime(LIGOTimeGPS(t0)), 2*pi);

  ## compute sky coordinates
  tau_E = LAL_REARTH_SI / LAL_C_SI;
  alphaD = detLong + zeroLong;
  n_prefac = 2*pi * fmax * tau_E * cos(detLat);
  switch mode
    case "togct"

      ## 'inco' are physical coordinates
      alpha = inco(1, :);
      delta = inco(2, :);

      ## compute GCT sky coordinates
      nx = n_prefac .* cos(delta) .* cos(alpha - alphaD);
      ny = n_prefac .* cos(delta) .* sin(alpha - alphaD);

    case "tophy"

      ## 'inco' are GCT coordinates
      nx = inco(end-1, :);
      ny = inco(end, :);
      assert(isscalar(sgndelta) || all(size(sgndelta) == size(nx)));

      ## compute physical sky coordinates
      alpha = atan2(ny, nx) + alphaD;
      cosdelta = sqrt(nx.^2 + ny.^2) ./ n_prefac;
      delta = acos(max(-1, min(cosdelta, 1))) .* sign(sgndelta);

    otherwise
      error("%s: invalid first argument '%s'", funcName, mode);
  endswitch

  ## compute orbital derivatives in equatorial coordinates
  if !ptolemaic
    orbit_deriv = XLALComputeOrbitalDerivatives(3, t0, ephemerides);
    xindot = native(orbit_deriv);
  else

    ## get orbital position of the Earth
    [_, tAutumn] = XLALGetEarthTimes(t0);

    ## compute various constants required for calculating derivatives
    Omegao = 2*pi / LAL_YRSID_SI;
    phio = -Omegao * tAutumn;
    Ro_cos_phio = LAL_AU_SI / LAL_C_SI * cos(phio);
    Ro_sin_phio = LAL_AU_SI / LAL_C_SI * sin(phio);
    ecl_to_equ = [1 0; 0 LAL_COSIEARTH; 0 LAL_SINIEARTH];

    ## compute Ptolemaic derivatives
    xindot = zeros(4, 3);
    xindot(1, :) = ecl_to_equ * [Ro_cos_phio; Ro_sin_phio];
    xindot(2, :) = Omegao * ecl_to_equ * [-Ro_sin_phio; Ro_cos_phio];
    xindot(3, :) = Omegao^2 * ecl_to_equ * [-Ro_cos_phio; -Ro_sin_phio];
    xindot(4, :) = Omegao^3 * ecl_to_equ * [Ro_sin_phio; -Ro_cos_phio];

  endif

  ## compute sky position vector in equatorial coordinates
  n = [cos(alpha).*cos(delta); sin(alpha).*cos(delta); sin(delta)];

  ## compute dot product of orbital derivatives with sky position vector
  xi_n = xindot(1, :) * n;
  xid_n = xindot(2, :) * n;
  xidd_n = xindot(3, :) * n;
  xiddd_n = xindot(4, :) * n;

  ## compute frequency/spindown coordinates
  switch mode
    case "togct"

      ## 'inco' are physical coordinates
      fndot = inco(3:end, :);
      fndot(end+1:3, :) = 0;
      f = fndot(1, :);
      fd = fndot(2, :);
      fdd = fndot(3, :);

      ## compute GCT frequency/spindown coordinates
      nukdot(1, :) = 2.*pi .* (T/2) .* (f + f.*xid_n + fd.*xi_n);
      nukdot(2, :) = 2.*pi .* (T/2).^2 .* (1/2.*fd + 1/2.*f.*xidd_n + fd.*xid_n + 1/2.*fdd.*xi_n);
      nukdot(3, :) = 2.*pi .* (T/2).^3 .* (1/6.*fdd + 1/6.*f.*xiddd_n + 1/2.*fd.*xidd_n + 1/2.*fdd.*xid_n);

    case "tophy"

      ## 'inco' are GCT coordinates
      nukdot = inco(1:end-2, :);
      nukdot(end+1:3, :) = 0;
      nu = nukdot(1, :);
      nud = nukdot(2, :);
      nudd = nukdot(3, :);

      ## compute physical frequency/spindown coordinates
      invdet = 1 ./ ( pi .* T.^3 .* ( 1 + xid_n.*(6 + xid_n.*(11 + 6.*xid_n)) - 4.*xidd_n.*xi_n - 6.*xidd_n.*xid_n.*xi_n + xiddd_n.*xi_n.^2 ) );
      fndot(1, :) = invdet .* ( T.^2.*(1 + xid_n.*(5 + 6.*xid_n) - 3.*xidd_n.*xi_n).*nu - 4.*T.*(1 + 3.*xid_n).*xi_n.*nud + 24.*xi_n.^2.*nudd );
      fndot(2, :) = invdet .* ( -T.^2.*(xidd_n + 3.*xidd_n.*xid_n - xiddd_n.*xi_n).*nu + 4.*T.*(1 + xid_n).*(1 + 3.*xid_n).*nud - 24.*(1 + xid_n).*xi_n.*nudd );
      fndot(3, :) = invdet .* ( -T.^2.*(xiddd_n - 3.*xidd_n.^2 + 2.*xiddd_n.*xid_n).*nu + 4.*T.*(-3.*xidd_n.*(1 + xid_n) + xiddd_n.*xi_n).*nud + 24.*(1 + xid_n.*(3 + 2.*xid_n) - xidd_n.*xi_n).*nudd );

    otherwise
      error("%s: invalid first argument '%s'", funcName, mode);
  endswitch

  ## return coordinates
  switch mode
    case "togct"
      outco = [nukdot(1:smax+1, :); nx; ny];
    case "tophy"
      outco = [alpha; delta; fndot(1:smax+1, :)];
    otherwise
      error("%s: invalid first argument '%s'", funcName, mode);
  endswitch

endfunction

%!shared alpha_ref, delta_ref, fndot_ref, gctco_ref
%!  alpha_ref = [1.1604229, 3.4494408, 0.3384569, 3.2528905, 4.2220307, 4.0216501, 4.4586725, 2.6643348, 4.5368049, 4.1968573, 1.0090024, 2.3518049, 6.1686511, 2.7418963, 5.7136839, 4.8999429, 3.5196677, 3.5462285];
%!  delta_ref = [0.1932254, 0.1094716,-0.9947154, 0.0326421, 0.8608284,-0.5364847,-0.7566707, 0.3503306,-0.5262539,-0.7215617,-0.2617862,-0.4193604,-1.0175479, 0.4204785,-0.2233229,-0.2677687,-0.1032384, 1.4105888];
%!  fndot_ref = [6.2948e-3, 1.3900e-3, 7.4630e-3, 3.4649e-3, 8.1318e-3, 4.6111e-3, 9.9765e-3, 2.4069e-3, 8.0775e-3, 6.0784e-3, 1.2569e-3, 8.3437e-3, 8.1557e-3, 4.2130e-3, 7.0748e-4, 4.0846e-3, 3.1204e-3, 3.8858e-3;
%!               0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000,-1.859e-10,-1.7734e-9,-6.7179e-9,-7.6231e-9,-5.9919e-9,-4.7396e-9,-8.0516e-9,-4.0123e-9,-9.1149e-9,-5.3355e-9,-2.0422e-9,-7.7313e-9;
%!               0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000, 2.596e-17, 9.455e-17, 1.913e-17, 6.869e-17, 2.286e-17, 1.743e-17];
%!  gctco_ref = [1.7085e+3, 3.7728e+2, 2.0258e+3, 9.4045e+2, 2.2072e+3, 1.2517e+3, 2.7081e+3, 6.5316e+2, 2.1921e+3, 1.6492e+3, 3.4180e+2, 2.2644e+3, 2.2141e+3, 1.1432e+3, 1.9251e+2, 1.1085e+3, 8.4669e+2, 1.0548e+3;
%!               5.9246e-4,-1.4654e-4, 2.8904e-4,-3.4929e-4,-3.5437e-4,-4.7675e-4,-1.0908e+0,-1.0396e+1,-3.9393e+1,-4.4699e+1,-3.5128e+1,-2.7784e+1,-4.7212e+1,-2.3520e+1,-5.3450e+1,-3.1288e+1,-1.1973e+1,-4.5325e+1;
%!               1.1578e-6, 1.3190e-7,-1.0014e-6, 4.9297e-7,-7.7033e-8,-6.1422e-7,-1.6373e-6, 4.2624e-6, 2.0069e-5, 2.8420e-5,-2.3158e-5, 8.9556e-6, 2.1817e-3, 7.9903e-3, 1.5984e-3, 5.8097e-3, 1.9400e-3, 1.4695e-3;
%!              -1.1593e-3, 2.2515e-3,-1.2265e-3, 2.3005e-3, 8.7039e-4, 1.4456e-3, 6.2425e-4, 1.7776e-3, 5.9593e-4, 1.0377e-3,-1.4158e-3, 1.2768e-3,-1.1741e-3, 1.8152e-3,-1.7200e-3,-1.3115e-4, 2.2189e-3, 3.5332e-4;
%!              -1.9392e-3, 4.0833e-4,-2.6143e-4,-3.9448e-5, 1.2223e-3, 1.3511e-3, 1.5531e-3,-1.2310e-3, 1.8993e-3, 1.3822e-3,-1.7147e-3,-1.6706e-3, 2.9104e-4,-1.0591e-3, 1.4427e-3, 2.2162e-3, 5.6570e-4, 1.0014e-4];

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  gctco = GCTCoordinates("togct", [alpha_ref; delta_ref; fndot_ref], "t0", 987654321, "T", 86400, "detector", "L1", "fmax", 0.02, "ptolemaic", false);
%!  assert(all(abs(gctco - gctco_ref) < 1e-4 * abs(gctco_ref)));

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  gctco = GCTCoordinates("togct", [alpha_ref(1:16); delta_ref(1:16); fndot_ref(1:2, 1:16)], "t0", 987654321, "T", 86400, "detector", "L1", "fmax", 0.02, "ptolemaic", false);
%!  assert(all(abs(gctco - gctco_ref([1,2,4,5], 1:16)) < 1e-4 * abs(gctco_ref([1,2,4,5], 1:16))));

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  gctco = GCTCoordinates("togct", [alpha_ref(1:8); delta_ref(1:8); fndot_ref(1:1, 1:8)], "t0", 987654321, "T", 86400, "detector", "L1", "fmax", 0.02, "ptolemaic", false);
%!  assert(all(abs(gctco - gctco_ref([1,4,5], 1:8)) < 1e-3 * abs(gctco_ref([1,4,5], 1:8))));

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  phyco = GCTCoordinates("tophy", gctco_ref, "t0", 987654321, "T", 86400, "detector", "L1", "fmax", 0.02, "sgndelta", delta_ref, "ptolemaic", false);
%!  assert(all(abs(phyco(1, :) - alpha_ref) < 1e-4 * abs(alpha_ref)));
%!  assert(all(abs(phyco(2, :) - delta_ref) < 2e-2 * abs(delta_ref)));
%!  for i = 1:3
%!    assert(all(abs(phyco(2+i, :) - fndot_ref(i, :)) < max(1e-10, 1e-4 * abs(fndot_ref(i, :)))));
%!  endfor

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  phyco = GCTCoordinates("tophy", gctco_ref(:, 1:16), "t0", 987654321, "T", 86400, "detector", "L1", "fmax", 0.02, "sgndelta", delta_ref(1:16), "ptolemaic", false);
%!  assert(all(abs(phyco(1, 1:16) - alpha_ref(1:16)) < 1e-4 * abs(alpha_ref(1:16))));
%!  assert(all(abs(phyco(2, 1:16) - delta_ref(1:16)) < 2e-2 * abs(delta_ref(1:16))));
%!  for i = 1:2
%!    assert(all(abs(phyco(2+i, 1:16) - fndot_ref(i, 1:16)) < max(1e-10, 1e-4 * abs(fndot_ref(i, 1:16)))));
%!  endfor

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  phyco = GCTCoordinates("tophy", gctco_ref(:, 1:8), "t0", 987654321, "T", 86400, "detector", "L1", "fmax", 0.02, "sgndelta", delta_ref(1:8), "ptolemaic", false);
%!  assert(all(abs(phyco(1, 1:8) - alpha_ref(1:8)) < 1e-4 * abs(alpha_ref(1:8))));
%!  assert(all(abs(phyco(2, 1:8) - delta_ref(1:8)) < 2e-2 * abs(delta_ref(1:8))));
%!  for i = 1:1
%!    assert(all(abs(phyco(2+i, 1:8) - fndot_ref(i, 1:8)) < max(1e-10, 1e-4 * abs(fndot_ref(i, 1:8)))));
%!  endfor
