## Copyright (C) 2018 Christoph Dreissigacker
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

function [Depth, pd_Depth] = SensitivityDepthNEW(varargin)

  ## parse options
  parseOptions(varargin,
               {"pd", "real,strictunit,column"},
               {"Nseg", "integer,strictpos,matrix"},
               {"Tdata","real, matrix"},
               {"Rsqr", "a:Hist", []},
               {"misHist","acell:Hist", []},
               {"stat", "cell,vector"},
               {"prog", "logical,scalar", false},
	       {"Bayesian", "logical", false},
               []);
  assert(histDim(Rsqr) == 1, "%s: R^2 must be a 1D histogram", funcName);
  assert(length(stat) > 1 && ischar(stat{1}), "%s: first element of 'stat' must be a string", funcName);
  stat_num =[1:length(stat)](cellfun(@isnumeric, stat));
  compatibleTrialInputs = common_size(pd(:,1),Nseg(:,1),Tdata(:,1),stat{stat_num}(:,1));
  assert(!compatibleTrialInputs,"#trials unclear \n pd,Nseg,Tdata,pFA, threshold must either be scalar or the number of rows must be the #trials");
  
  ## check stages are well defined
  assert(isempty(misHist) || size(Nseg,2) == size(misHist,2),
	 "#stages unclear, #columns in Nsegeg must match #columns in mismatch histograms.\n");

  stages = size(Nseg,2);
  trials = max([size(pd,1),size(Nseg,1),size(Tdata,1),cellfun(@(x) size(x,2),stat(stat_num))]);
  assert(!(Bayesian && stages >1),"Bayesian mode can only handle single stage searches");

  ## ---- Preparations ----
  
  ## Bring all inputs to the proper size
  ## 1. Dimension for different trials
  ## 2. Dimension for different depth
  ## 3. Dimension varying Rsqr
  ## 4. Dimension varying Stat
  ## 5. Dimension varying mismatch
  

  ## Copying index to increase dimension
  TrialCI = ones(length(trials),1);
  
  ## stages are indexed as cell array
  for i = 1:length(stat_num)
    stat{stat_num(i)} = num2cell(stat{stat_num(i)},1);
  endfor
  Tdata = num2cell(Tdata,1);
  Nseg = num2cell(Nseg,1);
  
  ## transform a single mismatch histogram into a cell array
  if isa(misHist,"Hist")
      misHist = {misHist};
  endif
  if isempty(misHist)
    misHist = {createDeltaHist(0)};
  endif
  ## Extract values from misHists
  ## get probabilitiy densities for mismatch
  mism_px = cellfun(@histProbs,misHist,"UniformOutput",false);
  [mism_x, mism_dx] = cellfun(@histBins,misHist, {1}, {"centre"}, {"width"},"UniformOutput",false);

  mism_w = cellfun('times',mism_px,mism_dx,"UniformOutput",false);
  clear mism_px mism_dx;

 
  ## Extract values from Rsqr hist
  Rsqr_px = histProbs(Rsqr);
  [Rsqr_x, Rsqr_dx] = histBins(Rsqr, 1, "centre", "width");
  ## check histogram bins are positive and contain no infinities
  if min(histRange(Rsqr)) < 0
    error("%s: R^2 histogram bins must be positive", funcName);
  endif
  if Rsqr_px(1) > 0 || Rsqr_px(end) > 0
    error("%s: R^2 histogram contains non-zero probability in infinite bins", funcName);
  endif
  ## compute weights
  Rsqr_w = Rsqr_px .* Rsqr_dx;
  clear Rsqr_px Rsqr_dx;


## check for trials with different misHists??

  
  ## logical index to select trial
  TrialSI = true(trials, 1);

  ## resize misHists
  ## chop off infinite bins and resize to vectors in different dimensions
  for i = 1: stages
    mism_x{i} = reshape(mism_x{i}(2:end -1), 1,1,1,1,[]);
    mism_w{i} = reshape(mism_w{i}(2:end -1), 1,1,1,1,[]);
  endfor
  ## chop off infinite bins and resize to row vectors, i.e. the bin values are enumerated by columns
  Rsqr_x = reshape(Rsqr_x(2:end-1), 1,1, []);
  Rsqr_w = reshape(Rsqr_w(2:end-1), 1,1, []);
  
  ## prepare P(stat|h_0, R^2) function according to stat
  stati = stat;
  for i=1:stages
    ## select stage i in stat
    stati{stat_num} = stati{stat_num}{i};
    [calcPdet, calcPDF] = SensitivitySelectStat("Nseg", Nseg{i}, "stat", stati{1:end}, "mism_w", mism_w{i});
  endfor


  ## ---- Calculations ---- 
  pkg load optim
  if Bayesian
    ## implementation of eq. 52 or StackSlide equivalent times integration factor 1/D^2
    pdet = @(D) 1./D.^2.*calcConf(D,calcPdet,calcPDF,TrialSI,Tdata, Rsqr_x, Rsqr_w, mism_x,Bayesian);
    oldnorm = inf;
    maxDepth = 100;
    ## check how far we must integrate for the normalisation factor
    do
      Norm = quadv(pdet,0.1,maxDepth,1e-10)
      norm_err = abs(Norm - oldnorm)./Norm;
      maxDepth *=2;
      oldnorm = Norm;
    until all(norm_err < 1e-5)
    ## integrate depth
    conf = @(D) pd -  quadv(pdet,D, maxDepth./2,1e-10)./Norm;
    ## solve equation 55 for the Depth
    ## currently here is an issue with vfzero only accepting the search interval as square matrices
    [Depth,pd_Depth,info,output] = vfzero(conf,[0.1,10^4].*ones(length(TrialSI),1));
    assert(info == 1, "Root finder failed!")
  else
    ## implementation of eq. 54
    pdet = @(D) pd - calcConf(D,calcPdet,calcPDF,TrialSI, Tdata,Rsqr_x,Rsqr_w,mism_x,Bayesian);
    ## solve equation 54 for the Depth
    [Depth,pd_Depth,info,output] = vfzero(pdet,[0.1,10^4].*ones(length(TrialSI),1));
    assert(info == 1, "Root finder failed!")
  endif
  
endfunction
	      

      

	      



function pdet = calcConf(Depth,calcPdet,calcPDF,TrialSI, Tdata,Rsqr_x,Rsqr_w,mism_x,Bayesian)
 
  ## only calculate something if there is a not yet done trial
  if any(TrialSI)
    stages = length(mism_x);
    ## loop over stages
    for i = 1:stages
      ## calculate effective non centrality
      rhosqr_eff{i}= Rhosqr_eff(Tdata{i},Depth, Rsqr_x, mism_x{i});
    endfor
    if Bayesian
      ## eval calcPDF
      pdf = feval(calcPDF,rhosqr_eff{1});
      ## integrate over R2
      pdet = sum(pdf.*Rsqr_w,3);
    else
      ## eval calcPdet
      pdeti = cell2mat(cellfun(@feval,{calcPdet},rhosqr_eff,"UniformOutput",false));
      ## prod over stages
      pdet_tot = prod(pdeti,2);
      ## integrate over R2
      pdet = sum(pdet_tot.*Rsqr_w,3);
    endif
  else
    pdf = [];
  endif
endfunction
