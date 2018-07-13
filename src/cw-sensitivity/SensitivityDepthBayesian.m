## Copyright (C) 2016, 2017 Christoph Dreissigacker
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

## Calculate sensitivity in terms of the sensitivity depth.
## Syntax:
##   Depth = SensitivityDepthBayesian("opt", val, ...)
## where:
##   Depth    = SensitivityDepth
##   pd_Depth = calculated false dismissal probability
## and where options are:
##   "pd"     = false dismissal probability
##   "Ns"     = number of segments
##   "Tdata"  = total amount of data used in seconds
##   "Rsqr"   = histogram of SNR "geometric factor" R^2,
##              computed using SqrSNRGeometricFactorHist(),
##              or scalar giving mean value of R^2
##   "stat"   = detection statistic, one of:
##              * {"ChiSqr", "opt", val, ...}
##                  chi^2 statistic, e.g. the F-statistic, see
##                  SensitivityChiSqrFDP() for options
##              * {"HoughFstat", "opt", val, ...}
##                  Hough on the F-statistic, see
##                  SensitivityHoughFstatFDP() for options
##   "prog"   = show progress updates
##  "misHist" = mismatch histograms (default: no mismatch)
function Depth = SensitivityDepthBayesian(varargin)

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
      [xx, Ns, FDP, fdp_vars, fdp_opts] = SensitivityChiSqrFDPBayes(pd(:,ones(size(Ns,2),1)), Ns, stat(2:end));
%    case "HoughFstat"   ## Hough on F-statistic
%      [xx, Ns, FDP, fdp_vars, fdp_opts] = SensitivityHoughFstatFDP(pd(:,ones(size(Ns,2),1)), Ns, stat(2:end));
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
  ##transform Ns, Tdata and sa into a cell array
  Ns = num2cell(Ns,1);
  Tdata = num2cell(Tdata,1);
  fdp_vars{1} = num2cell(fdp_vars{1},1);
  if length(fdp_vars) > 1
    fdp_vars{2} = num2cell(fdp_vars{2},1);
  endif


  ## get probability densities and bin quantities
  Rsqr_px = histProbs(Rsqr);
  [Rsqr_x, Rsqr_dx] = histBins(Rsqr, 1, "centre", "width");

  ## check histogram bins are positive and contain no infinities                  # add for mismatch
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
  Depth = nan(length(ii), 1);
  pdf_Depth = [];

  ## calculate first pdf
  maxDepth = 1;
  DepthRange = 1;
  linDepth = DepthRange.*ones(size(Depth));
  pdf_Depth(:,1) = callFDP(linDepth,ii,
                              jj,kk,Ns, Tdata,Rsqr_x,Rsqr_w,mism_x, mism_w,
                              FDP,fdp_vars,fdp_opts);
  Norm = 1;
  do
    oldNorm = Norm;
    maxDepth +=1;
    DepthRange = linspace(1,maxDepth,10*(maxDepth-1)+1);
    for d = 1: 10
      linDepth = DepthRange(end-10+d).*ones(size(Depth)); ## depth resolution 0.1
      pdf_Depth(:,end+1) = callFDP(linDepth,ii,
                                      jj,kk,Ns, Tdata,Rsqr_x,Rsqr_w,mism_x, mism_w,
                                      FDP,fdp_vars,fdp_opts);
    endfor

    Norm = sum(pdf_Depth./DepthRange.^2,2);
    if (Norm != 0) && (oldNorm != 0)
      err = abs(Norm./oldNorm) - 1;
    else
      err = 1;
    endif
  until err < 1e-4
  DepthRange = DepthRange(end:-1:1);
  pdf_Depth = pdf_Depth(:,end:-1:1);
  points = length(DepthRange)
  # old implementation
  ## points = 20000;
  ## DepthRange = linspace(1, 2000,points)(end:-1:1);
  ## pdf_Depth = [];

  ## for d = 1:length(DepthRange)
  ##   linDepth = DepthRange(d).*ones(size(Depth));
  ##   pdf_Depth(:,d) = callFDP(linDepth,ii,
  ##          jj,kk,Ns, Tdata,Rsqr_x,Rsqr_w,mism_x, mism_w,
  ##          FDP,fdp_vars,fdp_opts);
  ## endfor
  ## Norm = sum(pdf_Depth./DepthRange.^2,2);

  cumDepth = cumsum(pdf_Depth./DepthRange.^2,2);
  [xx, Depth_i] = min(abs(cumDepth./Norm -(1 -pd)),[],2);
  Depth = DepthRange(:,Depth_i)
  hold off;plot(DepthRange,pdf_Depth(1,:)./DepthRange.^2)
  hold on; line([Depth(1),Depth(1)],ylim(),"color","r")

  ## display progress updates?
  if prog
    printf("%s: done\n", funcName);
    page_screen_output(old_pso);
  endif
endfunction

## call a false dismissal probability calculation equation
function pd_Depth = callFDP(Depth,ii,
                          jj,kk,Ns, Tdata,Rsqr_x,Rsqr_w,mism_x, mism_w,
                          FDP,fdp_vars,fdp_opts)
  if any(ii)
    for i = 1:length(mism_x)
      ##integrating over the mismatch distributions
      pdfs(:,:,i) = sum((feval(FDP,Ns{i}(ii,jj,kk{i}),                       ## lower dimensional arrays are copied to the remaining dimensions
                       (2 / 5 .*sqrt(Tdata{i}(ii,jj,kk{i}) ./Ns{i}(ii,jj,kk{i}))./Depth(ii,jj,kk{i})).^2 .*Rsqr_x(ii,:,kk{i}).*(1 - mism_x{i}(ii,jj,:)), ## might be better to do that before the loop
                       cellfun(@(x) x{i}(ii,jj,kk{i}),fdp_vars,"UniformOutput",false),
                       fdp_opts )) .*mism_w{i}(ii,jj,:),3);
    endfor
    ## product of the mismatch integrals, integration over R^2
    pd_Depth = sum(prod(pdfs,3).* Rsqr_w(ii,:) , 2);
  else
    pd_Depth = [];
  endif
endfunction

%!test
%! Rsqr = SqrSNRGeometricFactorHist;
%! Depth = SensitivityDepthBayesian ( "pd", 0.1, "Ns", 10, "Tdata", 10*86400, "Rsqr", Rsqr, "misHist", createDeltaHist(0.1), "stat", { "ChiSqr", "paNt", 1e-10 } );
