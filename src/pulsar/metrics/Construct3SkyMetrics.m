## Copyright (C) 2012 Karl Wette
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

## Construct various 3-sky metrics.
## Usage:
##   [metric3, coordIDs3, skyoff, alignsky] = ConstructSuperSkyMetrics(metric2p3, coordIDs2p3, ...)
## where:
##   metric2p3 = 2+3-sky metric, computed by CreatePhaseMetric()
##   coordIDs2p3 = DOPPLERCOORD_... coordinate IDs of 2+3-sky metric
## Options are:
##   "sky_coords": 3-sky coordinate system (default: equatorial)
##   "residual_sky": use residual 3-sky coordinates (default: false)
##   "decouple_sky: use decoupled 3-sky coordinates (default: false, true implies "residual_sky")
##   "aligned_sky": use aligned 3-sky coordinates (default: false, true implies "decouple_sky")
## Outputs are:
##   metric3 = 3-sky metric
##   skyoff = sky offset (row) vectors for residual (and decoupled) 3-sky coordinates
##   alignsky = alignment rotation matrix for aligned 3-sky coordinates
##   coordIDs3 = DOPPLERCOORD_... coordinate IDs of 3-sky metric

function [metric3, skyoff, alignsky, coordIDs3] = ConstructSuperSkyMetrics(metric2p3, coordIDs2p3, varargin)

  ## parse options
  parseOptions(varargin,
               {"sky_coords", "char", "equatorial"},
               {"residual_sky", "logical,scalar", false},
               {"decouple_sky", "logical,scalar", false},
               {"aligned_sky", "logical,scalar", false},
               []);

  ## check input
  assert(issymmetric(metric2p3));
  assert(isvector(coordIDs2p3));
  assert(length(unique(coordIDs2p3)) == length(coordIDs2p3));
  if aligned_sky
    decouple_sky = true;
  endif
  if decouple_sky
    residual_sky = true;
  endif

  ## load LAL libraries
  lal;
  lalpulsar;

  ## get coordinates of spin, orbital, frequency and spindown coordinates
  insx = find(coordIDs2p3 == DOPPLERCOORD_N3SX_EQU);
  assert(length(insx) > 0);
  insy = find(coordIDs2p3 == DOPPLERCOORD_N3SY_EQU);
  assert(length(insy) > 0);
  inoX = find(coordIDs2p3 == DOPPLERCOORD_N3OX_ECL);
  assert(length(inoX) > 0);
  inoY = find(coordIDs2p3 == DOPPLERCOORD_N3OY_ECL);
  assert(length(inoY) > 0);
  inoZ = find(coordIDs2p3 == DOPPLERCOORD_N3OZ_ECL);
  assert(length(inoZ) > 0);
  ifs = [find(coordIDs2p3 == DOPPLERCOORD_FREQ), ...
         find(coordIDs2p3 == DOPPLERCOORD_F1DOT), ...
         find(coordIDs2p3 == DOPPLERCOORD_F2DOT), ...
         find(coordIDs2p3 == DOPPLERCOORD_F3DOT)];
  assert(length(ifs) > 0);

  ## reconstruct 3-sky metric from spin and orbital metric, in requested coordinates
  ## adjust coordinate IDs and coordinate indices appropriately
  inx = insx;
  iny = insy;
  inz = inoX;
  idel = [inoY, inoZ];
  coordIDs3 = coordIDs2p3;
  switch sky_coords
    case "equatorial"
      skyreconstruct = [1, 0, 0;
                        0, 1, 0;
                        1, 0, 0;
                        0, LAL_COSIEARTH, LAL_SINIEARTH,
                        0, -LAL_SINIEARTH, LAL_COSIEARTH];
      coordIDs3([inx, iny, inz]) = [DOPPLERCOORD_N3X_EQU,
                                     DOPPLERCOORD_N3Y_EQU,
                                     DOPPLERCOORD_N3Z_EQU];
    case "ecliptic"
      skyreconstruct = [1, 0, 0;
                        0, LAL_COSIEARTH, -LAL_SINIEARTH;
                        1, 0, 0;
                        0, 1, 0,
                        0, 0, 1];
      coordIDs3([inx, iny, inz]) = [DOPPLERCOORD_N3X_ECL,
                                     DOPPLERCOORD_N3Y_ECL,
                                     DOPPLERCOORD_N3Z_ECL];
    otherwise
      error("%s: unknown coordinate system '%s'", funcName, sky_coords);
  endswitch
  coordIDs3(idel) = [];
  reconstruct = eye(size(metric2p3));
  reconstruct([insx, insy, inoX, inoY, inoZ], [inx, iny, inz]) = skyreconstruct;
  reconstruct(:, idel) = [];
  ss_inn = [inx, iny, inz];
  ss_iff = ifs;
  ss_iff(ss_iff > inz) -= 2;

  ## reconstruct 3-sky metric
  metric3 = reconstruct' * metric2p3 * reconstruct;
  skyoff = zeros(length(ifs), 3);
  alignsky = eye(3);

  if residual_sky

    ## diagonally normalise 2+3-sky metric
    ## use "tolerant" since orbital Z may be zero, for Ptolemaic ephemerides
    [nmetric2p3, dmetric2p3, idmetric2p3] = DiagonalNormaliseMetric(metric2p3, "tolerant");

    ## find least-squares linear fit to orbital X and Y by frequency and spindowns
    fitted = [inoX, inoY];
    fitting = ifs;
    fitA = nmetric2p3(:, fitting);
    fity = nmetric2p3(:, fitted);
    fitcoeffs = (fitA' * fitA) \ (fitA' * fity);

    ## subtract linear fit from orbital X and Y, creating residual coordinates
    subtractfit = eye(size(metric2p3));
    subtractfit(fitting, fitted) = -fitcoeffs;

    ## construct residual 3-sky metric
    residual = dmetric2p3 * subtractfit * idmetric2p3 * reconstruct;
    metric3 = residual' * metric2p3 * residual;

    ## extract sky offset vectors
    skyoff = skyoff - residual(fitting, ss_inn);

    if decouple_sky

      ## extract sky-sky, sky-frequency, and frequency-frequency blocks
      rss_ss = metric3(ss_inn, ss_inn);
      rss_sf = metric3(ss_inn, ss_iff);
      rss_ff = metric3(ss_iff, ss_iff);

      ## calculate additional sky offset and sky metric adjustment to
      ## zero the sky-frequency block of the residual 3-sky metric
      decoupleoff = rss_ff \ rss_sf';
      decouple_ss = -rss_sf * decoupleoff;

      ## decouple residual 3-sky metric and sky offset vectors
      metric3(ss_inn, ss_inn) += decouple_ss;
      metric3(ss_inn, ss_iff) = 0;
      metric3(ss_iff, ss_inn) = 0;
      skyoff = skyoff + decoupleoff;

      if aligned_sky

        ## eigendecompose residual 3-sky metric sky-sky block
        rss_ss = metric3(ss_inn, ss_inn);
        [rss_ss_evec, rss_ss_eval] = eig(rss_ss);

        ## order eigenvectors in descending order of eigenvalues
        [rss_ss_eval, iidescend] = sort(diag(rss_ss_eval), "descend");
        rss_ss_eval = diag(rss_ss_eval);
        rss_ss_evec = rss_ss_evec(:, iidescend);

        ## align third sky dimension with smallest eigenvector
        alignsky = rss_ss_evec' * alignsky;
        aligned = eye(size(metric3));
        aligned(ss_inn, ss_inn) = rss_ss_evec;

        ## align residual 3-sky metric and sky offset vectors
        metric3 = aligned' * metric3 * aligned;
        skyoff = skyoff * alignsky';

      endif

    endif

  endif

  ## ensure metric is exactly symmetric
  metric3 = 0.5*(metric3' + metric3);

endfunction
