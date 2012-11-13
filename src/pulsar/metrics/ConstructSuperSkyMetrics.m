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
##   M = ConstructSuperSkyMetrics(sometric, coordIDs, skycoordsys)
## where:
##   sometric = spin-orbit metric, created e.g. with CreatePhaseMetric()
##   coordIDs = DOPPLERCOORD_... coordinate IDs of spin-orbit metric
##   skycoordsys = super-sky coordinate system: "equatorial" or "ecliptic"
## and M is a struct with the following fields:
##   ssmetric = super-sky metric, reconstructed from spin-orbit metric
##   rssmetric = reduced super-sky metric
##   skyoff = sky offset (row) vectors for reduced super-sky metric
##   arssmetric = aligned reduced super-sky metric
##   alignsky = sky alignment rotation matrix
##   skyoff = sky offset (row) vectors for aligned reduced super-sky metric

function M = ConstructSuperSkyMetrics(sometric, coordIDs, skycoordsys)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## check input
  assert(issymmetric(sometric));
  assert(isvector(coordIDs));
  assert(length(unique(coordIDs)) == length(coordIDs));
  assert(ischar(skycoordsys));

  ## get coordinates of spin, orbital, frequency and spindown coordinates
  insx = find(coordIDs == DOPPLERCOORD_NSX_EQU);
  insy = find(coordIDs == DOPPLERCOORD_NSY_EQU);
  inoX = find(coordIDs == DOPPLERCOORD_NOX_ECL);
  inoY = find(coordIDs == DOPPLERCOORD_NOY_ECL);
  ifs = [find(coordIDs == DOPPLERCOORD_FREQ_SI), ...
         find(coordIDs == DOPPLERCOORD_F1DOT_SI), ...
         find(coordIDs == DOPPLERCOORD_F2DOT_SI), ...
         find(coordIDs == DOPPLERCOORD_F3DOT_SI)];

  ## diagonally normalise spin-orbit metric
  [nsometric, dsometric, idsometric] = DiagonalNormaliseMetric(sometric);

  ## find least-squares linear fit to orbital X and Y by frequency and spindowns
  fitted = [inoX, inoY];
  fitting = ifs;
  fitA = nsometric(:, fitting);
  fity = nsometric(:, fitted);
  fitcoeffs = (fitA' * fitA) \ (fitA' * fity);

  ## subtract linear fit from orbital X and Y, creating residual coordinates
  subtractfit = eye(size(sometric));
  subtractfit(fitting, fitted) = -fitcoeffs;
  residual = dsometric * subtractfit * idsometric;

  ## reconstruct super-sky metric from spin and orbital metric, in requested coordinates
  switch skycoordsys
    case "equatorial"
      skyreconstruct = [1, 0, 0;
                        0, 1, 0;
                        1, 0, 0;
                        0, LAL_COSIEARTH, LAL_SINIEARTH];
    case "ecliptic"
      skyreconstruct = [1, 0, 0;
                        0, LAL_COSIEARTH, -LAL_SINIEARTH;
                        1, 0, 0;
                        0, 1, 0];
    otherwise
      error("%s: unknown coordinate system '%s'", funcName, skycoordsys);
  endswitch
  [inx, iny, inz, idel] = deal(num2cell(sort([insx, insy, inoX, inoY])){:});
  reconstruct = eye(size(sometric));
  reconstruct([insx, insy, inoX, inoY], [inx, iny, inz]) = skyreconstruct;
  reconstruct(:, idel) = [];

  ## reconstruct super-sky metric
  M.ssmetric = reconstruct' * sometric * reconstruct;

  ## construct residual super-sky metric
  residual = dsometric * subtractfit * idsometric * reconstruct;
  M.rssmetric = residual' * sometric * residual;

  ## extract sky offset vectors
  M.skyoff = -residual(fitting, [inx, iny, inz]);

  ## eigendecompose residual super-sky metric
  skyrssmetric = M.rssmetric([inx, iny, inz], [inx, iny, inz]);
  [skyeigvec, skyeigval] = eig(skyrssmetric);

  ## order eigenvectors in descending order of eigenvalues
  [skyeigval, iidescend] = sort(diag(skyeigval), "descend");
  skyeigval = diag(skyeigval);
  skyeigvec = skyeigvec(:, iidescend);

  ## align third sky dimension with smallest eigenvector
  M.alignsky = skyeigvec';
  aligned = eye(size(M.rssmetric));
  aligned([inx, iny, inz], [inx, iny, inz]) = skyeigvec;

  ## construct aligned residual super-sky metric
  M.arssmetric = aligned' * M.rssmetric * aligned;

  ## compute aligned sky offset vectors
  M.askyoff = M.skyoff * M.alignsky';

  ## ensure metrics are exactly symmetric
  M.ssmetric = 0.5*(M.ssmetric' + M.ssmetric);
  M.rssmetric = 0.5*(M.rssmetric' + M.rssmetric);
  M.arssmetric = 0.5*(M.arssmetric' + M.arssmetric);

endfunction
