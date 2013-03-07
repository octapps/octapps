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

## Construct various super-sky metrics.
## Usage:
##   [ssmetric, sscoordIDs, skyoff, alignsky] = ConstructSuperSkyMetrics(sometric, socoordIDs, ...)
## where:
##   sometric = spin-orbit metric, created e.g. with CreatePhaseMetric()
##   socoordIDs = DOPPLERCOORD_... coordinate IDs of spin-orbit metric
## Options are:
##   "sky_coord_sys": super-sky coordinate system (default: equatorial)
##   "residual_sky": use residual super-sky coordinates (default: false)
##   "decouple_sky: use decoupled super-sky coordinates (default: false, true implies "residual_sky")
##   "aligned_sky": use aligned super-sky coordinates (default: false, true implies "decouple_sky")
## Outputs are:
##   ssmetric = super-sky metric
##   skyoff = sky offset (row) vectors for residual super-sky coordinates
##   alignsky = alignment rotation matrix for aligned super-sky coordinates
##   sscoordIDs = DOPPLERCOORD_... coordinate IDs of super-sky metric

function [ssmetric, skyoff, alignsky, sscoordIDs] = ConstructSuperSkyMetrics(sometric, socoordIDs, varargin)

  ## parse options
  parseOptions(varargin,
               {"sky_coord_sys", "char", "equatorial"},
               {"residual_sky", "logical,scalar", false},
               {"decouple_sky", "logical,scalar", false},
               {"aligned_sky", "logical,scalar", false},
               []);

  ## check input
  assert(issymmetric(sometric));
  assert(isvector(socoordIDs));
  assert(length(unique(socoordIDs)) == length(socoordIDs));
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
  insx = find(socoordIDs == DOPPLERCOORD_N3SX_EQU);
  assert(length(insx) > 0);
  insy = find(socoordIDs == DOPPLERCOORD_N3SY_EQU);
  assert(length(insy) > 0);
  inoX = find(socoordIDs == DOPPLERCOORD_N3OX_ECL);
  assert(length(inoX) > 0);
  inoY = find(socoordIDs == DOPPLERCOORD_N3OY_ECL);
  assert(length(inoY) > 0);
  inoZ = find(socoordIDs == DOPPLERCOORD_N3OZ_ECL);
  assert(length(inoZ) > 0);
  ifs = [find(socoordIDs == DOPPLERCOORD_FREQ), ...
         find(socoordIDs == DOPPLERCOORD_F1DOT), ...
         find(socoordIDs == DOPPLERCOORD_F2DOT), ...
         find(socoordIDs == DOPPLERCOORD_F3DOT)];
  assert(length(ifs) > 0);

  ## reconstruct super-sky metric from spin and orbital metric, in requested coordinates
  ## adjust coordinate IDs and coordinate indices appropriately
  inx = insx;
  iny = insy;
  inz = inoX;
  idel = [inoY, inoZ];
  sscoordIDs = socoordIDs;
  switch sky_coord_sys
    case "equatorial"
      skyreconstruct = [1, 0, 0;
                        0, 1, 0;
                        1, 0, 0;
                        0, LAL_COSIEARTH, LAL_SINIEARTH,
                        0, -LAL_SINIEARTH, LAL_COSIEARTH];
      sscoordIDs([inx, iny, inz]) = [DOPPLERCOORD_N3X_EQU,
                                     DOPPLERCOORD_N3Y_EQU,
                                     DOPPLERCOORD_N3Z_EQU];
    case "ecliptic"
      skyreconstruct = [1, 0, 0;
                        0, LAL_COSIEARTH, -LAL_SINIEARTH;
                        1, 0, 0;
                        0, 1, 0,
                        0, 0, 1];
      sscoordIDs([inx, iny, inz]) = [DOPPLERCOORD_N3X_ECL,
                                     DOPPLERCOORD_N3Y_ECL,
                                     DOPPLERCOORD_N3Z_ECL];
    otherwise
      error("%s: unknown coordinate system '%s'", funcName, sky_coord_sys);
  endswitch
  sscoordIDs(idel) = [];
  reconstruct = eye(size(sometric));
  reconstruct([insx, insy, inoX, inoY, inoZ], [inx, iny, inz]) = skyreconstruct;
  reconstruct(:, idel) = [];
  ss_inn = [inx, iny, inz];
  ss_iff = ifs;
  ss_iff(ss_iff > inz) -= 2;

  ## reconstruct super-sky metric
  ssmetric = reconstruct' * sometric * reconstruct;
  skyoff = zeros(length(ifs), 3);
  alignsky = eye(3);

  if residual_sky

    ## diagonally normalise spin-orbit metric
    ## use "tolerant" since orbital Z may be zero, for Ptolemaic ephemerides
    [nsometric, dsometric, idsometric] = DiagonalNormaliseMetric(sometric, "tolerant");

    ## find least-squares linear fit to orbital X and Y by frequency and spindowns
    fitted = [inoX, inoY];
    fitting = ifs;
    fitA = nsometric(:, fitting);
    fity = nsometric(:, fitted);
    fitcoeffs = (fitA' * fitA) \ (fitA' * fity);

    ## subtract linear fit from orbital X and Y, creating residual coordinates
    subtractfit = eye(size(sometric));
    subtractfit(fitting, fitted) = -fitcoeffs;

    ## construct residual super-sky metric
    residual = dsometric * subtractfit * idsometric * reconstruct;
    ssmetric = residual' * sometric * residual;

    ## extract sky offset vectors
    skyoff = skyoff - residual(fitting, ss_inn);

    if decouple_sky

      ## extract sky-sky, sky-frequency, and frequency-frequency blocks
      rss_ss = ssmetric(ss_inn, ss_inn);
      rss_sf = ssmetric(ss_inn, ss_iff);
      rss_ff = ssmetric(ss_iff, ss_iff);

      ## calculate additional sky offset and sky metric adjustment to
      ## zero the sky-frequency block of the residual super-sky metric
      decoupleoff = rss_ff \ rss_sf';
      decouple_ss = -rss_sf * decoupleoff;

      ## decouple residual super-sky metric and sky offset vectors
      ssmetric(ss_inn, ss_inn) += decouple_ss;
      ssmetric(ss_inn, ss_iff) = 0;
      ssmetric(ss_iff, ss_inn) = 0;
      skyoff = skyoff + decoupleoff;

      if aligned_sky

        ## eigendecompose residual super-sky metric sky-sky block
        rss_ss = ssmetric(ss_inn, ss_inn);
        [rss_ss_evec, rss_ss_eval] = eig(rss_ss);

        ## order eigenvectors in descending order of eigenvalues
        [rss_ss_eval, iidescend] = sort(diag(rss_ss_eval), "descend");
        rss_ss_eval = diag(rss_ss_eval);
        rss_ss_evec = rss_ss_evec(:, iidescend);

        ## align third sky dimension with smallest eigenvector
        alignsky = rss_ss_evec' * alignsky;
        aligned = eye(size(ssmetric));
        aligned(ss_inn, ss_inn) = rss_ss_evec;

        ## align residual super-sky metric and sky offset vectors
        ssmetric = aligned' * ssmetric * aligned;
        skyoff = skyoff * alignsky';

      endif

    endif

  endif

  ## ensure metric is exactly symmetric
  ssmetric = 0.5*(ssmetric' + ssmetric);

endfunction
