%% Calculates the sensitivity constant "Q"
%% Syntax:
%%   Q = SensitivityQ(pd, k, sa, Rsqr)
%%   Q = SensitivityQ(..., "norm", "mR^2")
%% where:
%%   Q      = sensitivity constant
%%   pd     = false dismissal probability / rate
%%   N      = number of segments
%%   k      = statistical degrees of freedom per segment
%%   sa     = false alarm threshold on statistic per segment
%%   Rsqr   = histogram of "R^2" component of the optimal SNR
%%   "norm" = use normal approximation to non-central chi^2 c.d.f
%%   "HoughF" = use Hough-on-Fstat statistic
%%   "mR^2" = use the mean value of "R^2" instead of its distribution
function Q = SensitivityQ(pd, N, k, sa, Rsqr, varargin)

  %% check input
  assert(isHist(Rsqr));

  %% make N, pd, k, and sa common size
  [errcode, N, pd, k, sa] = common_size(N, pd, k, sa);
  if errcode > 0
    error("Input arguments 'N', 'pd', 'k', and 'sa' must be either the same size or scalars");
  endif

  %% get values and weights of Rsqr from histogram
  [Rsqrx, Rsqrdx] = histBinGrids(Rsqr, 1, "xc", "dx");
  Rsqrw = Rsqr.px .* Rsqrdx;

  %% use non-central chi^2 distribution
  FDR = @NonChiSquareFDR;

  %% check for optional arguments
  for i = 1:length(varargin)
    switch varargin{i}
  
      case "norm"
        %% use normal approximation to non-central chi^2 c.d.f
        FDR = @NormalApproxFDR;

      case "HoughF"
        FDR = @HoughFstatFDR;

      case "mR^2"
        %% use the mean value of "R^2" instead of its distribution
        Rsqrx = meanOfHist(Rsqr);
        Rsqrw = 1.0;

      otherwise
        error("Invalid optional argument '%s'", varargin{1});
    endswitch
  endfor
  
  %% flatten to vectors
  siz = size(pd);
  N = N(:);
  pd = pd(:);
  k = k(:);
  sa = sa(:);
  Rsqrx = Rsqrx(:)';
  Rsqrw = Rsqrw(:)';

  %% make grids of k, sa (dim. 1) and Rsqr{x,w} (dim. 2)
  %% Q is computed for each for each k, sa (dim. 1) by summing
  %% c.d.f. over a range of fixed Rsqrx, weighted by Rsqrw (dim. 2)
  ii = ones(length(k), 1);
  jj = ones(length(Rsqrx), 1);
  k  = k (:,jj);
  sa = sa(:,jj);
  Rsqrx = Rsqrx(ii,:);
  Rsqrw = Rsqrw(ii,:);

  %% multiply k, sa, and Rsqrx by N
  k     .*= N(:,jj);
  ##sa    .*= N(:,jj);
  Rsqrx .*= N(:,jj);
  clear N;

  %% initialise some variables
  fdrQsqrm = fdrQsqrM = DfdrDQsqr = fdr = zeros(size(k, 1), 1);

  %% calculate the f.d.r. for Q^2=0; if it's less than 
  %% the target f.d.r, return NaN to indicate the
  %% corresponding values of k and sa are invalid
  %% (f.d.r. always decreases with increasing Q^2)
  ii = true(size(ii));
  Qsqrm = zeros(size(fdr));
  fdrQsqrm(ii) = feval(FDR, ii, jj, k, Qsqrm, Rsqrx, Rsqrw, sa);
  ii0 = (fdrQsqrm >= pd);

  %% try to find the Q^2 where f.d.r becomes less
  %% than the target rate, to bracket the range of Q^2
  QsqrM = ones(size(fdr));
  ii = ii0;
  do

    %% increment upper bound on Q^2 and calculate f.d.r.
    QsqrM(ii) *= 5;
    fdrQsqrM(ii) = feval(FDR, ii, jj, k, QsqrM, Rsqrx, Rsqrw, sa);

    %% deduce which rows to keep looping over
    %% exit when there are none left
    ii = ii & (fdrQsqrM >= pd);
  until !any(ii)

  %% do bifurcation search until the range of Q^2 is small
  Qsqr = NaN(size(fdr));
  ii = ii0;
  do

    %% pick mid-point and calculate f.d.r.
    Qsqr(ii) = (Qsqrm(ii) + QsqrM(ii)) / 2;
    fdr(ii) = feval(FDR, ii, jj, k, Qsqr, Rsqrx, Rsqrw, sa);

    %% change the lower bounds if f.d.r. is on the same side of pd
    iim = (fdrQsqrm >= pd & fdr >= pd);
    Qsqrm(iim) = Qsqr(iim);

    %% change the upper bounds if f.d.r. is on the same side of pd
    iiM = (fdrQsqrM <  pd & fdr <  pd);
    QsqrM(iiM) = Qsqr(iiM);
    
    %% deduce which rows to keep looping over
    %% exit when there are none left
    ii = (QsqrM - Qsqrm > 10);
  until !any(ii)

  %% use Newton-Raphson root-finding to
  %% converge to accurate values of Q^2
  ii = ii0;
  Qsqr(ii) = (Qsqrm(ii) + QsqrM(ii)) / 2;
  dQsqr = zeros(size(Qsqr));
  do

    %% calculate f.d.r. at Q^2 and bounds
    fdrQsqrm(ii) = feval(FDR, ii, jj, k, Qsqrm, Rsqrx, Rsqrw, sa);
    fdr(ii)      = feval(FDR, ii, jj, k, Qsqr,  Rsqrx, Rsqrw, sa);
    fdrQsqrM(ii) = feval(FDR, ii, jj, k, QsqrM, Rsqrx, Rsqrw, sa);

    %% derivative of f.d.r. with respect to Q^2
    DfdrDQsqr(ii) = (fdrQsqrM(ii) - fdrQsqrm(ii)) ./ (QsqrM(ii) - Qsqrm(ii));

    %% adjustment to Q^2 given by Newton-Raphson method
    dQsqr(ii) = (fdr(ii) - pd(ii)) ./ DfdrDQsqr(ii);

    %% absolute error implied by adjustment
    err(ii) = abs(dQsqr(ii) ./ Qsqr(ii));

    %% make adjustment
    Qsqr(ii) -= dQsqr(ii);

    %% use adjustment to make new bounds for computing derivative
    dQsqr(ii) = min(abs(Qsqr(ii) - QsqrM(ii)), abs(Qsqr(ii) - Qsqrm(ii)));
    Qsqrm(ii) = Qsqr(ii) - dQsqr(ii);
    QsqrM(ii) = Qsqr(ii) + dQsqr(ii);

    %% deduce which rows to keep looping over
    %% exit when there are none left
    ii = (isnan(err) | err >= 1e-4);
  until !any(ii)
  
  %% return Q
  Q = sqrt(reshape(Qsqr, siz));
  
endfunction

%% calculate the false dismissal rate using the
%% exact non-central chi-squared distribution
function fdr = NonChiSquareFDR(ii, jj, k, Qsqr, Rsqrx, Rsqrw, sa)
  cdf = ChiSquare_cdf(sa(ii,:), k(ii,:), Qsqr(ii,jj).*Rsqrx(ii,:));
  fdr = sum(cdf .* Rsqrw(ii,:), 2);
endfunction

%% calculate the false dismissal rate using a
%% normal distribution approximation
function fdr = NormalApproxFDR(ii, jj, k, Qsqr, Rsqrx, Rsqrw, sa)
  mean = k(ii,:) + Qsqr(ii,jj).*Rsqrx(ii,:);
  stdv = sqrt(2.*(k(ii,:) + 2.*Qsqr(ii,jj).*Rsqrx(ii,:)));
  cdf = normcdf(sa(ii,:), mean, stdv);
  fdr = sum(cdf .* Rsqrw(ii,:), 2);
endfunction

%% calculate the false dismissal probability using the
%% exact distribution for the Hough-on-Fstat statistic
function fd = HoughFstatFDR (ii, jj, k, Qsqr, Rsqrx, Rsqrw, sa )

  Fth = 5.2/2;	%% fixed Fstat-threshold
  Nseg = k(1) / 4;	%% FIXME: hardcoded dof for now

  fct = @(rho2) falseDismissal_HoughF ( sa(1), Nseg, Fth, rho2 );

  SNR0sq = Qsqr(ii,jj).*Rsqrx(ii,:) / Nseg;
  cdf = arrayfun ( fct, SNR0sq );

  fd = sum(cdf .* Rsqrw(ii,:), 2);
endfunction
