## Copyright (C) 2016 Christoph Dreissigacker
## Copyright (C) 2011, 2016 Karl Wette
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
## @deftypefn {Function File} { [ @var{Depth}, @var{pd_Depth} ] =} SensitivityDepth ( @var{opt}, @var{val}, @dots{} )
##
## Calculate sensitivity in terms of the sensitivity depth.
##
## @heading Arguments
##
## @table @var
## @item Depth
## SensitivityDepth
##
## @item pd_Depth
## calculated false dismissal probability
##
## @end table
##
## @heading Options
##
## @table @code
## @item pd
## false dismissal probability
##
## @item Ns
## number of segments
##
## @item Tdata
## total amount of data used in seconds
##
## @item Rsqr
## histogram of SNR "geometric factor" R^2,
## computed using @command{SqrSNRGeometricFactorHist()},
## or scalar giving mean value of R^2
##
## @item stat
## detection statistic, one of:
## @table @asis
## @item @{@code{ChiSqr}, @var{opt}, @var{val}, @dots{}@}
## chi^2 statistic, e.g. the F-statistic, with options:
## @table @var
## @item paNt
## false alarm probability per template
##
## @item sa
## false alarm threshold
##
## @item dof
## degrees of freedom per segment (default: 4)
##
## @item norm
## use normal approximation to chi^2 (default: false)
##
## @end table
##
## @item @{@code{HoughFstat}, @var{opt}, @var{val}, @dots{}@}
## Hough on the F-statistic, with options:
## @table @var
## @item paNt
## false alarm probability per template
##
## @item nth
## number count false alarm threshold
##
## @item Fth
## F-statistic threshold per segment
##
## @item zero
## use zeroth-order approximation (default: false)
##
## @end table
##
## @end table
##
## @item prog
## show progress updates
##
## @item misHist
## mismatch histograms (default: no mismatch)
##
## @end table
##
## @end deftypefn

function [Depth, pd_Depth] = SensitivityDepth(varargin)

  ## parse options
  parseOptions(varargin,
               {"pd", "real,strictunit,column"},
               {"Ns", "integer,strictpos,matrix"},
               {"Tdata","real, matrix"},
               {"Rsqr", "a:Hist", []},
               {"misHist","acell:Hist", []},
               {"stat", "cell,vector"},
               {"prog", "logical,scalar", false},
               []);
  assert(histDim(Rsqr) == 1, "%s: R^2 must be a 1D histogram", funcName);                 #add for mismatch
  assert(length(stat) > 1 && ischar(stat{1}), "%s: first element of 'stat' must be a string", funcName);
  assert(isempty(misHist) || size(Ns,2) == length(misHist),"#stages unclear, #columns in Nseg must match #mismatch histograms.\n");

  ## detect number of stages
  stages = size(Ns,2);

  ## select a detection statistic, we don't want to change the vector pd because here the columns are still the different stages
  ## but there is only one overall pd for all stages
  switch stat{1}
    case "ChiSqr"   ## chi^2 statistic
      [xx, Ns, FDP, fdp_vars, fdp_opts] = SensitivityChiSqrFDP(pd(:,ones(size(Ns,2),1)), Ns, stat(2:end));
    case "HoughFstat"   ## Hough on F-statistic
      [xx, Ns, FDP, fdp_vars, fdp_opts] = SensitivityHoughFstatFDP(pd(:,ones(size(Ns,2),1)), Ns, stat(2:end));
    otherwise
      error("%s: invalid detection statistic '%s'", funcName, stat{1});
  endswitch

  ## bring Tdata to the same size as Ns
  try
    [cserr,Tdata,Ns] = common_size(Tdata,Ns);
    assert(cserr == 0);
  catch
    if size(Ns,1) == size(Tdata,1)
      Tdata = Tdata(:,ones(size(Ns,2),1));
    elseif size(Ns,2) == size(Tdata,2)
      Tdata = Tdata(ones(size(Ns,1),1),:);
    else
      error("Sizes of Tdata and Ns are not compatible\n");
    endif
  end_try_catch
  ## transform Ns, Tdata and sa into a cell array
  Ns = num2cell(Ns,1);
  Tdata = num2cell(Tdata,1);
  fdp_vars{1} = num2cell(fdp_vars{1},1);
  if length(fdp_vars) > 1
    fdp_vars{2} = num2cell(fdp_vars{2},1);
  endif

  ## get probability densities and bin quantities
  Rsqr_px = histProbs(Rsqr);
  [Rsqr_x, Rsqr_dx] = histBins(Rsqr, 1, "centre", "width");

  ## check histogram bins are positive and contain no infinities                  ## add for mismatch
  if min(histRange(Rsqr)) < 0
    error("%s: R^2 histogram bins must be positive", funcName);
  endif
  if Rsqr_px(1) > 0 || Rsqr_px(end) > 0
    error("%s: R^2 histogram contains non-zero probability in infinite bins", funcName);
  endif

  ## chop off infinite bins and resize to row vectors, i.e. the bin values are enumerated by columns
  Rsqr_px = reshape(Rsqr_px(2:end-1), 1, []);
  Rsqr_x = reshape(Rsqr_x(2:end-1), 1, []);
  Rsqr_dx = reshape(Rsqr_dx(2:end-1), 1, []);

  ## compute weights
  Rsqr_w = Rsqr_px .* Rsqr_dx;
  clear Rsqr_px Rsqr_dx;

  ## make row indexes logical, to select rows
  ii = true(size(Ns{1}), 1);
  ## make column indexes ones, to duplicate columns
  jj = ones(length(Rsqr_x), 1);

  if isempty(misHist)

    ## assume no mismatch
    mism_x = {};
    mism_w = {};
    mism_x(1:stages) = 0;
    mism_w(1:stages) = 1;

    kk = {};
    kk(1:stages) = 1;
    for i = 1:length(mism_x)
      ## copy values along trials dimension,  ii + 0 converts logical into double       ## copying in higher dimensions happens later
      mism_x{i} = mism_x{i}(ii + 0,:,:);
      mism_w{i} = mism_w{i}(ii + 0,:,:);
    endfor

  else
    ## transform a single mismatch histogram into a cell array
    if isa(misHist,"Hist")
      misHist = {misHist};
    endif
    ## get probabilitiy densities for mismatch
    mism_px = cellfun(@histProbs,misHist,"UniformOutput",false);
    [mism_x, mism_dx] = cellfun(@histBins,misHist, {1}, {"centre"}, {"width"},"UniformOutput",false);

    ## chop off infinite bins and resize to vectors in different dimensions
    for i = 1: length(mism_x)
      mism_px{i} = reshape(mism_px{i}(2:end -1), 1,1,[]);
      mism_x{i} = reshape(mism_x{i}(2:end -1), 1,1,[]);
      mism_dx{i} = reshape(mism_dx{i}(2:end -1), 1,1,[]);

      ## copy values along trials dimension,  ii + 0 converts logical into double       ## copying in higher dimensions happens later
      mism_px{i} = mism_px{i}(ii + 0,:,:);
      mism_x{i} = mism_x{i}(ii + 0,:,:);
      mism_dx{i} = mism_dx{i}(ii + 0,:,:);

    endfor

    ## make indices for every remaining dimension ones, to duplicate them
    kk = cellfun(@size,mism_x,{3},"UniformOutput",false);
    kk = cellfun(@ones,kk,{1},"UniformOutput",false);

    mism_w = cellfun('times',mism_px,mism_dx,"UniformOutput",false);
    clear mism_px mism_dx;
  endif

  ## if pd should be constant along different trials copy it for each trial
  if isscalar(pd)
    pd = pd(ii + 0);
  endif

  ## show progress updates?
  if prog
    old_pso = page_screen_output(0);
    printf("%s: starting\n", funcName);
  endif

  ## Depth is computed for each pd and Ns (dim. 1) by summing
  ## false dismissal probability for fixed Rsqr_x, weighted
  ## by Rsqr_w (dim. 2)
  ## copy values along trials dimension
  Rsqr_x = Rsqr_x(ii + 0, :);
  Rsqr_w = Rsqr_w(ii + 0, :);

  ## initialise variables
  pd_Depth = Depth = nan(length(ii), 1);
  pd_Depth_min = pd_Depth_max = zeros(size(Depth));

  ## calculate the false dismissal probability for Depth=1,
  ## only proceed if it's less than the target false dismissal
  ## probability
  Depth_min = ones(size(Depth));
  pd_Depth_min(ii) = callFDP(Depth_min,ii,
                             jj,kk,pd,Ns, Tdata,Rsqr_x,Rsqr_w,mism_x, mism_w,
                             FDP,fdp_vars,fdp_opts);
  ii0 = (pd_Depth_min <= pd);

  ## find Depth_max where the false dismissal probability becomes
  ## less than the target false dismissal probability, to bracket
  ## the range of Depth
  Depth_max = 5.*ones(size(Depth));
  ii = ii0;
  sumii = 0;
  do

    ## display progress updates?
    if prog && sum(ii) != sumii
      sumii = sum(ii);
      printf("%s: finding Depth_max (%i left)\n", funcName, sumii);
    endif

    ## increment upper bound on Depth
    Depth_max(ii) *= 2;

    ## calculate false dismissal probability
    pd_Depth_max(ii) = callFDP(Depth_max,ii,
                               jj,kk,pd,Ns, Tdata,Rsqr_x,Rsqr_w, mism_x, mism_w,
                               FDP,fdp_vars,fdp_opts);

    ## determine which Depth to keep calculating for
    ## exit when there are none left
    ii = (pd_Depth_max <= pd);
  until !any(ii)

  ## find Depth using a bifurcation search
  err1 = inf(size(Depth));
  err2 = inf(size(Depth));
  ii = ii0;
  sumii = 0;
  do

    ## display progress updates?
    if prog && sum(ii) != sumii
      sumii = sum(ii);
      printf("%s: bifurcation search (%i left)\n", funcName, sumii);
    endif

    ## pick random point within range as new Depth
    u = rand(size(Depth));
    Depth(ii) = Depth_min(ii) .* u(ii) + Depth_max(ii) .* (1-u(ii));

    ## calculate new false dismissal probability
    pd_Depth(ii) = callFDP(Depth,ii,
                           jj,kk,pd,Ns, Tdata,Rsqr_x,Rsqr_w, mism_x, mism_w,
                           FDP,fdp_vars,fdp_opts);

    ## replace bounds with mid-point as required
    iimin = ii & (pd_Depth_min < pd & pd_Depth < pd);
    iimax = ii & (pd_Depth_max > pd & pd_Depth > pd);
    Depth_min(iimin) = Depth(iimin);
    pd_Depth_min(iimin) = pd_Depth(iimin);
    Depth_max(iimax) = Depth(iimax);
    pd_Depth_max(iimax) = pd_Depth(iimax);

    ## fractional error in false dismissal rate
    err1(ii) = abs(pd_Depth(ii) - pd(ii)) ./ pd(ii);

    ## fractional range of Depth
    err2(ii) = (Depth_max(ii) - Depth_min(ii)) ./ Depth(ii);

    ## determine which Depth to keep calculating for
    ## exit when there are none left
    ii = (isfinite(err1) & err1 > 1e-5) & (isfinite(err2) & err2 > 1e-10);
  until !any(ii)

  ## display progress updates?
  if prog
    printf("%s: done\n", funcName);
    page_screen_output(old_pso);
  endif

endfunction

## call a false dismissal probability calculation equation
function pd_Depth = callFDP(Depth,ii,
                            jj,kk,pd,Ns, Tdata,Rsqr_x,Rsqr_w,mism_x, mism_w,
                            FDP,fdp_vars,fdp_opts)
  if any(ii)
    for i = 1:length(mism_x)
      ## integrating over the mismatch distributions
      cdfs(:,:,i) = sum((1 -  feval(FDP,pd(ii,jj,kk{i}), Ns{i}(ii,jj,kk{i}),                       ## lower dimensional arrays are copied to the remaining dimensions
                                    (2 / 5 .*sqrt(Tdata{i}(ii,jj,kk{i}) ./Ns{i}(ii,jj,kk{i}))./Depth(ii,jj,kk{i})).^2 .*Rsqr_x(ii,:,kk{i}).*(1 - mism_x{i}(ii,jj,:)), ## might be better to do that before the loop
                                    cellfun(@(x) x{i}(ii,jj,kk{i}),fdp_vars,"UniformOutput",false),
                                    fdp_opts )) .*mism_w{i}(ii,jj,:),3);
    endfor
    ## product of the mismatch integrals, integration over R^2
    pd_Depth = 1 - sum(prod(cdfs,3).* Rsqr_w(ii,:) , 2);
  else
    pd_Depth = [];
  endif
endfunction

## calculate Rsqr for isotropic signal population
%!shared Rsqr
%!  Rsqr = SqrSNRGeometricFactorHist;

## Test sensitivity calculated for chi^2 statistic
## against values calculated by Mathematica implementation
##  - test SNR depth against reference value depth0
%!function __test_sens_chisqr(Rsqr,paNt,pd,nu,Ns,depth0)
%!  depth = SensitivityDepth("Tdata",86400*Ns,"pd",pd,"Ns",Ns,"Rsqr",Rsqr,"stat",{"ChiSqr","paNt",paNt,"dof",nu});
%!  assert(abs(depth - depth0) < 1e-2 * abs(depth0));
## - tests
%!test __test_sens_chisqr(Rsqr,0.01,0.05,2,1,17.9751)
%!test __test_sens_chisqr(Rsqr,0.01,0.05,2,100,80.4602)
%!test __test_sens_chisqr(Rsqr,0.01,0.05,2,10000,269.687)
%!test __test_sens_chisqr(Rsqr,0.01,0.05,4,1,16.429)
%!test __test_sens_chisqr(Rsqr,0.01,0.05,4,100,68.8944)
%!test __test_sens_chisqr(Rsqr,0.01,0.05,4,10000,227.24)
%!test __test_sens_chisqr(Rsqr,0.01,0.1,2,1,20.5666)
%!test __test_sens_chisqr(Rsqr,0.01,0.1,2,100,89.3568)
%!test __test_sens_chisqr(Rsqr,0.01,0.1,2,10000,297.123)
%!test __test_sens_chisqr(Rsqr,0.01,0.1,4,1,18.6925)
%!test __test_sens_chisqr(Rsqr,0.01,0.1,4,100,76.3345)
%!test __test_sens_chisqr(Rsqr,0.01,0.1,4,10000,250.28)
%!test __test_sens_chisqr(Rsqr,1e-07,0.05,2,1,10.5687)
%!test __test_sens_chisqr(Rsqr,1e-07,0.05,2,100,55.9013)
%!test __test_sens_chisqr(Rsqr,1e-07,0.05,2,10000,193.411)
%!test __test_sens_chisqr(Rsqr,1e-07,0.05,4,1,10.0133)
%!test __test_sens_chisqr(Rsqr,1e-07,0.05,4,100,48.3342)
%!test __test_sens_chisqr(Rsqr,1e-07,0.05,4,10000,163.153)
%!test __test_sens_chisqr(Rsqr,1e-07,0.1,2,1,11.589)
%!test __test_sens_chisqr(Rsqr,1e-07,0.1,2,100,60.1536)
%!test __test_sens_chisqr(Rsqr,1e-07,0.1,2,10000,206.551)
%!test __test_sens_chisqr(Rsqr,1e-07,0.1,4,1,10.9521)
%!test __test_sens_chisqr(Rsqr,1e-07,0.1,4,100,51.9024)
%!test __test_sens_chisqr(Rsqr,1e-07,0.1,4,10000,174.182)
%!test __test_sens_chisqr(Rsqr,1e-12,0.05,2,1,8.29336)
%!test __test_sens_chisqr(Rsqr,1e-12,0.05,2,100,47.5524)
%!test __test_sens_chisqr(Rsqr,1e-12,0.05,2,10000,168.007)
%!test __test_sens_chisqr(Rsqr,1e-12,0.05,4,1,7.96925)
%!test __test_sens_chisqr(Rsqr,1e-12,0.05,4,100,41.3759)
%!test __test_sens_chisqr(Rsqr,1e-12,0.05,4,10000,141.831)
%!test __test_sens_chisqr(Rsqr,1e-12,0.1,2,1,8.97247)
%!test __test_sens_chisqr(Rsqr,1e-12,0.1,2,100,50.7244)
%!test __test_sens_chisqr(Rsqr,1e-12,0.1,2,10000,177.979)
%!test __test_sens_chisqr(Rsqr,1e-12,0.1,4,1,8.60838)
%!test __test_sens_chisqr(Rsqr,1e-12,0.1,4,100,44.0545)
%!test __test_sens_chisqr(Rsqr,1e-12,0.1,4,10000,150.205)

## Test sensitivity calculated for Hough Fstat statistic
## - test SNR depth against reference value depth0
%!function __test_sens_houghfstat(Rsqr,paNt,pd,Fth,Ns,depth0)
%!  depth = SensitivityDepth("Tdata",86400*Ns,"pd",pd,"Ns",Ns,"Rsqr",Rsqr,"stat",{"HoughFstat","paNt",paNt,"Fth",Fth});
%!  assert(abs(depth - depth0) < 1e-2 * abs(depth0));
## - tests
%!test __test_sens_houghfstat(Rsqr,0.01,0.05,5.2,100,53.352)
%!test __test_sens_houghfstat(Rsqr,1e-07,0.05,5.2,100,39.125)
%!test __test_sens_houghfstat(Rsqr,1e-12,0.1,5.2,100,36.324)
