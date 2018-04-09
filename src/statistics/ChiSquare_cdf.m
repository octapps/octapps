## Copyright (C) 2010, 2011 Karl Wette
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
## @deftypefn {Function File} {@var{p} =} ChiSquare_cdf ( @var{x}, @var{k}, @var{lambda} )
##
## Compute the cumulative density function of the
## non-central chi^2 distribution.
##
## @heading Arguments
##
## @table @var
## @item x
## value of the non-central chi^2 variable
##
## @item k
## number of degrees of freedom
##
## @item lambda
## non-centrality parameter
##
## @end table
##
## @end deftypefn

function p = ChiSquare_cdf(x, k, lambda)

  ## check for common size input
  if !exist("lambda")
    lambda = 0;
  endif
  [cserr, x, k, lambda] = common_size(x, k, lambda);
  if cserr > 0
    error("All input arguments must be either of common size or scalars");
  endif

  ## flatten input after saving sizes
  siz = size(x);
  x = x(:)';
  k = k(:)';
  lambda = lambda(:)';

  ## allocate result
  p = zeros(size(x));

  ## for zero lambda, compute the central chi^2 CDF
  ii = (lambda > 0);
  if any(!ii)
    p(!ii) = gsl_chi2cdf(x(!ii), k(!ii));
  endif

  ## otherwise compute the non-central chi^2 PDF
  if any(ii)

    ## series summation error
    err = 1e-6;

    ## half quantities
    hx = hk = hlambda = zeros(size(x));
    hx(ii) = 0.5 .* x(ii);
    hk(ii) = 0.5 .* k(ii);
    hlambda(ii) = 0.5 .* lambda(ii);

    ## starting indexes for summation
    j0 = jp = jm = zeros(size(x));
    j0(ii) = jp(ii) = jm(ii) = round(hlambda(ii));

    ## initial values of Poisson term in series sum
    Pp = Pm = zeros(size(x));
    Pp(ii) = Pm(ii) = real_poisspdf(j0(ii), hlambda(ii));

    ## initial values of chi^2 term in series sum
    Xp = Xm = zeros(size(x));
    Xp(ii) = Xm(ii) = gsl_chi2cdf(x(ii), k(ii) + 2.*j0(ii));

    ## initial values of Poisson adjustments to chi^2 terms
    XPm = XPp = zeros(size(x));
    XPp(ii) = real_poisspdf(hk(ii) + j0(ii), hx(ii));
    XPm(ii) = XPp(ii) .* (hk(ii) + j0(ii)) ./ hx(ii);

    ## initial series value
    p(ii) = Pp(ii) .* Xp(ii);

    ## add up series expansion of non-central chi^2 distribution
    pnew = zeros(size(p));
    do

      ## adjust positive-index Poisson term
      Pp(ii) .*= hlambda(ii) ./ ( jp(ii) + 1 );

      ## adjust positive-index chi^2 term
      Xp(ii) -= XPp(ii);

      ## adjust Poisson adjustment to positive-index chi^2 term
      XPp(ii) .*= hx(ii) ./ ( hk(ii) + jp(ii) + 1 );

      ## new series term (positive indices)
      pnew(ii) = Pp(ii) .* Xp(ii);
      jp(ii) += 1;

      ## if there are negative indices to sum
      iim = ii & jm > 0;
      if any(iim)

        ## adjust negative-index Poisson term
        Pm(iim) .*= jm(iim) ./ hlambda(iim);

        ## adjust negative-index chi^2 term
        Xm(iim) += XPm(iim);

        ## adjust Poisson adjustment to negative-index chi^2 term
        XPm(iim) .*= (hk(iim) + jm(iim) - 1) ./ hx(iim);

        ## add to new series term (negative indices)
        pnew(iim) += Pm(iim) .* Xm(iim);
        jm(iim) -= 1;

      endif

      ## add new series terms to result
      p(ii) += pnew(ii);

      ## determine which series to continue summing
      ii = ii & (abs(pnew) > err .* abs(p));

      ## continue until no series are left
    until !any(ii)

  endif

  ## reshape result to original size of input
  p = reshape(p, siz);

endfunction

## compute the Poisson distribution extended
## to a real-valued number of events
function p = real_poisspdf(x, lambda)
  p = exp( x.*log(lambda) - lambda - gammaln(x + 1) );
endfunction

## try to use first GSL to compute the central chi^2 CDF:
## it's a bit slower than the Octave function, but it
## works for large values of x,k > 2000, where the Octave
## function fails. fall back to the Octave function if
## the GSL module is unavailable.
function p = gsl_chi2cdf(x, k)
  try
    gsl;
    p = gsl_sf_gamma_inc_P(k/2, x/2);
  catch
    p = chi2cdf(x, k);
  end_try_catch
endfunction

## Test value x against reference value x0
%!function __test_cdf(x, x0)
%!  assert(abs(x - x0) < 1e-9 * abs(x0) | abs(x0) < 1e-110)

## Tests ChiSquare_cdf against values computed in Mathematica v8.0.1.0 using
## the following script. Results agree to <= 1e-6, except for even-k values
## computed with NIntegrate[PDF[..., due to numerical bugs in Mathematica (!).
##
## In[1]:= ClearAll[MyCDF]
## MyCDF[NoncentralChiSquareDistribution[\[Nu]_, \[Lambda]_]][x_] /;
##   And @@ (NumericQ /@ {\[Nu], \[Lambda], x}) :=
##  Module[{j0, jp, jm, Pp, Pm, Xp, Xm, XPp, XPm, p, pn},
##   If[\[Lambda] == 0 || x == 0,
##    Return[CDF[NoncentralChiSquareDistribution[\[Nu], \[Lambda]]][x]];
##    ];
##   j0 = jp = jm = Round[\[Lambda]/2];
##   Pp = Pm = PDF[PoissonDistribution[\[Lambda]/2]][j0];
##   Xp = Xm = CDF[ChiSquareDistribution[\[Nu] + 2*j0]][x];
##   XPp = PDF[PoissonDistribution[x/2]][\[Nu]/2 + j0];
##   XPm = XPp*(\[Nu]/2 + j0)/(x/2);
##   p = Pp*Xp;
##   pn = \[Infinity];
##   While[Abs[pn] > 10^-6*Abs[p],
##    Pp = Pp*(\[Lambda]/2)/(jp + 1);
##    Xp = Xp - XPp;
##    XPp = XPp*(x/2)/(\[Nu]/2 + jp + 1);
##    jp = jp + 1;
##    pn = Pp*Xp;
##    If[jm > 0,
##     Pm = Pm*jm/(\[Lambda]/2);
##     Xm = Xm + XPm;
##     XPm = XPm*(\[Nu]/2 + jm - 1)/(x/2);
##     jm = jm - 1;
##     pn = pn + Pm*Xm;
##     ];
##    p = p + pn;
##    ];
##   p
##   ]
##
## In[3]:= x = SetPrecision[{5, 10, 40, 80, 200}, 100];
## k = SetPrecision[{1, 2, 4, 5, 10, 15, 20, 75, 150, 500}, 100];
## \[Lambda] = SetPrecision[{0, 15, 50, 120, 400}, 100];
##
## In[6]:= test1 =
##   Outer[N@MyCDF[NoncentralChiSquareDistribution[#2, #3]][#1] &, x,
##    k, \[Lambda]];
##
## In[7]:= test2 =
##   Outer[N@CDF[NoncentralChiSquareDistribution[#2, #3]][#1] &, x,
##    k, \[Lambda]];
##
## In[8]:= test3 =
##   Outer[N@NIntegrate[
##       PDF[NoncentralChiSquareDistribution[#2, #3]][y], {y, 0, #1},
##       WorkingPrecision -> 100, AccuracyGoal -> 10^-5,
##       MaxRecursion -> 200] &, x, k, \[Lambda]];
##
## In[9]:= Take[Reverse@Sort@Flatten@Abs[(test2 - test1)/test1], 5]
##
## Out[9]= {1.204*10^-6, 1.15515*10^-6, 1.11116*10^-6, 1.05853*10^-6,
##  1.01098*10^-6}
##
## In[10]:= Take[Reverse@Sort@Flatten@Abs[(test3 - test1)/test1], 5]
##
## Out[10]= {0.0575652, 0.0363756, 0.0257139, 0.0128743, 0.00932531}
##
## In[11]:= keven = Pick[Range[1, Length@k], EvenQ@Round@k];
## Take[Reverse@
##   Sort@Flatten@
##     Abs[(test1[[All, keven, All]] - test3[[All, keven, All]])/
##       test3[[All, keven, All]]], 5]
##
## Out[12]= {1.15515*10^-6, 1.05852*10^-6, 9.9013*10^-7, 9.71368*10^-7,
##  8.56613*10^-7}
##
## In[13]:= StringJoin@Flatten@Table[
##    ToString@
##     StringForm["%!test __test_cdf(ChiSquare_cdf(``,``,``),``)\n",
##      CForm@N@x[[i]], CForm@N@k[[j]], CForm@N@\[Lambda][[l]],
##      CForm@N@test1[[i, j, l]]],
##    {i, 1, Length[x]}, {j, 1, Length[k]}, {l, 1, Length[\[Lambda]]}]
##
## which generates the following tests:

%!test __test_cdf(ChiSquare_cdf(5.,1.,0.),0.9746526813225317)
%!test __test_cdf(ChiSquare_cdf(5.,1.,15.),0.05082407661122478)
%!test __test_cdf(ChiSquare_cdf(5.,1.,50.),6.657287303504153e-7)
%!test __test_cdf(ChiSquare_cdf(5.,1.,120.),1.4110126206735404e-18)
%!test __test_cdf(ChiSquare_cdf(5.,1.,400.),6.723764458613879e-71)
%!test __test_cdf(ChiSquare_cdf(5.,2.,0.),0.9179150013761012)
%!test __test_cdf(ChiSquare_cdf(5.,2.,15.),0.035274973677445996)
%!test __test_cdf(ChiSquare_cdf(5.,2.,50.),3.6075830520886244e-7)
%!test __test_cdf(ChiSquare_cdf(5.,2.,120.),6.245502413027231e-19)
%!test __test_cdf(ChiSquare_cdf(5.,2.,400.),2.2261879840234022e-71)
%!test __test_cdf(ChiSquare_cdf(5.,4.,0.),0.7127025048163542)
%!test __test_cdf(ChiSquare_cdf(5.,4.,15.),0.015699244906430973)
%!test __test_cdf(ChiSquare_cdf(5.,4.,50.),1.0105355110594111e-7)
%!test __test_cdf(ChiSquare_cdf(5.,4.,120.),1.1864322190083836e-19)
%!test __test_cdf(ChiSquare_cdf(5.,4.,400.),2.399493834640724e-72)
%!test __test_cdf(ChiSquare_cdf(5.,5.,0.),0.5841198130044921)
%!test __test_cdf(ChiSquare_cdf(5.,5.,15.),0.010067878000172156)
%!test __test_cdf(ChiSquare_cdf(5.,5.,50.),5.223967166300288e-8)
%!test __test_cdf(ChiSquare_cdf(5.,5.,120.),5.092051169436395e-20)
%!test __test_cdf(ChiSquare_cdf(5.,5.,400.),7.811418775266269e-73)
%!test __test_cdf(ChiSquare_cdf(5.,10.,0.),0.10882198108584876)
%!test __test_cdf(ChiSquare_cdf(5.,10.,15.),0.0007444674329556936)
%!test __test_cdf(ChiSquare_cdf(5.,10.,50.),1.5289064311270403e-9)
%!test __test_cdf(ChiSquare_cdf(5.,10.,120.),6.362909862598009e-22)
%!test __test_cdf(ChiSquare_cdf(5.,10.,400.),2.625194772380971e-75)
%!test __test_cdf(ChiSquare_cdf(5.,15.,0.),0.00787358865548099)
%!test __test_cdf(ChiSquare_cdf(5.,15.,15.),0.000030417577943957835)
%!test __test_cdf(ChiSquare_cdf(5.,15.,50.),3.072871790632915e-11)
%!test __test_cdf(ChiSquare_cdf(5.,15.,120.),6.180989168105524e-24)
%!test __test_cdf(ChiSquare_cdf(5.,15.,400.),7.670165040531566e-78)
%!test __test_cdf(ChiSquare_cdf(5.,20.,0.),0.00027735209462083604)
%!test __test_cdf(ChiSquare_cdf(5.,20.,15.),7.376350350905591e-7)
%!test __test_cdf(ChiSquare_cdf(5.,20.,50.),4.328674422926527e-13)
%!test __test_cdf(ChiSquare_cdf(5.,20.,120.),4.697583974727663e-26)
%!test __test_cdf(ChiSquare_cdf(5.,20.,400.),1.9504867119479666e-80)
%!test __test_cdf(ChiSquare_cdf(5.,75.,0.),8.687995532981777e-31)
%!test __test_cdf(ChiSquare_cdf(5.,75.,15.),7.790657048345175e-34)
%!test __test_cdf(ChiSquare_cdf(5.,75.,50.),5.911195493831345e-41)
%!test __test_cdf(ChiSquare_cdf(5.,75.,120.),3.1369134862515624e-55)
%!test __test_cdf(ChiSquare_cdf(5.,75.,400.),1.1031013505048285e-112)
%!test __test_cdf(ChiSquare_cdf(5.,150.,0.),2.397024434306258e-81)
%!test __test_cdf(ChiSquare_cdf(5.,150.,15.),1.695863883652722e-84)
%!test __test_cdf(ChiSquare_cdf(5.,150.,50.),7.540937655658166e-92)
%!test __test_cdf(ChiSquare_cdf(5.,150.,120.),1.4728975173762546e-106)
%!test __test_cdf(ChiSquare_cdf(5.,150.,400.),1.8481736281231183e-165)
%!test __test_cdf(ChiSquare_cdf(10.,1.,0.),0.9984345977419975)
%!test __test_cdf(ChiSquare_cdf(10.,1.,15.),0.23863331620026396)
%!test __test_cdf(ChiSquare_cdf(10.,1.,50.),0.00004637974654275896)
%!test __test_cdf(ChiSquare_cdf(10.,1.,120.),3.2933101607651022e-15)
%!test __test_cdf(ChiSquare_cdf(10.,1.,400.),6.455562432599703e-64)
%!test __test_cdf(ChiSquare_cdf(10.,2.,0.),0.9932620530009145)
%!test __test_cdf(ChiSquare_cdf(10.,2.,15.),0.1961602845055895)
%!test __test_cdf(ChiSquare_cdf(10.,2.,50.),0.00003003007057771663)
%!test __test_cdf(ChiSquare_cdf(10.,2.,120.),1.740552205805621e-15)
%!test __test_cdf(ChiSquare_cdf(10.,2.,400.),2.5479624134214947e-64)
%!test __test_cdf(ChiSquare_cdf(10.,4.,0.),0.9595723180054871)
%!test __test_cdf(ChiSquare_cdf(10.,4.,15.),0.12613158885805104)
%!test __test_cdf(ChiSquare_cdf(10.,4.,50.),0.000012185135531341695)
%!test __test_cdf(ChiSquare_cdf(10.,4.,120.),4.757752226564309e-16)
%!test __test_cdf(ChiSquare_cdf(10.,4.,400.),3.922278003570363e-65)
%!test __test_cdf(ChiSquare_cdf(10.,5.,0.),0.9247647538534878)
%!test __test_cdf(ChiSquare_cdf(10.,5.,15.),0.09861700275293107)
%!test __test_cdf(ChiSquare_cdf(10.,5.,50.),7.636195942050238e-6)
%!test __test_cdf(ChiSquare_cdf(10.,5.,120.),2.460736104915279e-16)
%!test __test_cdf(ChiSquare_cdf(10.,5.,400.),1.5297672553890388e-65)
%!test __test_cdf(ChiSquare_cdf(10.,10.,0.),0.5595067149347875)
%!test __test_cdf(ChiSquare_cdf(10.,10.,15.),0.02228745971194175)
%!test __test_cdf(ChiSquare_cdf(10.,10.,50.),6.273033706842392e-7)
%!test __test_cdf(ChiSquare_cdf(10.,10.,120.),8.176344196630852e-18)
%!test __test_cdf(ChiSquare_cdf(10.,10.,400.),1.3008467424472597e-67)
%!test __test_cdf(ChiSquare_cdf(10.,15.,0.),0.18026008049639852)
%!test __test_cdf(ChiSquare_cdf(10.,15.,15.),0.0032987295474881614)
%!test __test_cdf(ChiSquare_cdf(10.,15.,50.),3.9423227311557225e-8)
%!test __test_cdf(ChiSquare_cdf(10.,15.,120.),2.2724333054725816e-19)
%!test __test_cdf(ChiSquare_cdf(10.,15.,400.),1.0019686200941388e-69)
%!test __test_cdf(ChiSquare_cdf(10.,20.,0.),0.03182805730620481)
%!test __test_cdf(ChiSquare_cdf(10.,20.,15.),0.0003266754196765963)
%!test __test_cdf(ChiSquare_cdf(10.,20.,50.),1.9085645385578783e-9)
%!test __test_cdf(ChiSquare_cdf(10.,20.,120.),5.294471960509474e-21)
%!test __test_cdf(ChiSquare_cdf(10.,20.,400.),6.99323575438422e-72)
%!test __test_cdf(ChiSquare_cdf(10.,75.,0.),1.4889409659910924e-20)
%!test __test_cdf(ChiSquare_cdf(10.,75.,15.),2.1484593136052944e-23)
%!test __test_cdf(ChiSquare_cdf(10.,75.,50.),4.661239659247958e-30)
%!test __test_cdf(ChiSquare_cdf(10.,75.,120.),1.6610027008352304e-43)
%!test __test_cdf(ChiSquare_cdf(10.,75.,400.),2.5532058718880974e-98)
%!test __test_cdf(ChiSquare_cdf(10.,150.,0.),7.694733240471517e-60)
%!test __test_cdf(ChiSquare_cdf(10.,150.,15.),6.956668946547875e-63)
%!test __test_cdf(ChiSquare_cdf(10.,150.,50.),5.43356566835553e-70)
%!test __test_cdf(ChiSquare_cdf(10.,150.,120.),3.1637181251476596e-84)
%!test __test_cdf(ChiSquare_cdf(10.,150.,400.),2.1579590973338844e-141)
%!test __test_cdf(ChiSquare_cdf(40.,1.,0.),0.9999999997460371)
%!test __test_cdf(ChiSquare_cdf(40.,1.,15.),0.9928881045457334)
%!test __test_cdf(ChiSquare_cdf(40.,1.,50.),0.2276789034093147)
%!test __test_cdf(ChiSquare_cdf(40.,1.,120.),1.829248455734514e-6)
%!test __test_cdf(ChiSquare_cdf(40.,1.,400.),7.1167223123620356e-43)
%!test __test_cdf(ChiSquare_cdf(40.,2.,0.),0.9999999979388464)
%!test __test_cdf(ChiSquare_cdf(40.,2.,15.),0.9906358763323195)
%!test __test_cdf(ChiSquare_cdf(40.,2.,50.),0.20567309558410937)
%!test __test_cdf(ChiSquare_cdf(40.,2.,120.),1.3702395894645452e-6)
%!test __test_cdf(ChiSquare_cdf(40.,2.,400.),3.9829955867683435e-43)
%!test __test_cdf(ChiSquare_cdf(40.,4.,0.),0.9999999567157739)
%!test __test_cdf(ChiSquare_cdf(40.,4.,15.),0.98421692505162)
%!test __test_cdf(ChiSquare_cdf(40.,4.,50.),0.1656323325479984)
%!test __test_cdf(ChiSquare_cdf(40.,4.,120.),7.608191384654475e-7)
%!test __test_cdf(ChiSquare_cdf(40.,4.,400.),1.240217236556717e-43)
%!test __test_cdf(ChiSquare_cdf(40.,5.,0.),0.99999985066321)
%!test __test_cdf(ChiSquare_cdf(40.,5.,15.),0.97979407097194)
%!test __test_cdf(ChiSquare_cdf(40.,5.,50.),0.14764362994984598)
%!test __test_cdf(ChiSquare_cdf(40.,5.,120.),5.639505612463199e-7)
%!test __test_cdf(ChiSquare_cdf(40.,5.,400.),6.90010641744312e-44)
%!test __test_cdf(ChiSquare_cdf(40.,10.,0.),0.9999830552560699)
%!test __test_cdf(ChiSquare_cdf(40.,10.,15.),0.9394158853888496)
%!test __test_cdf(ChiSquare_cdf(40.,10.,50.),0.0775662772656693)
%!test __test_cdf(ChiSquare_cdf(40.,10.,120.),1.1972546615644404e-7)
%!test __test_cdf(ChiSquare_cdf(40.,10.,400.),3.57099573827949e-45)
%!test __test_cdf(ChiSquare_cdf(40.,15.,0.),0.9995465018648978)
%!test __test_cdf(ChiSquare_cdf(40.,15.,15.),0.8542083443373368)
%!test __test_cdf(ChiSquare_cdf(40.,15.,50.),0.03622130399511793)
%!test __test_cdf(ChiSquare_cdf(40.,15.,120.),2.3282286133716798e-8)
%!test __test_cdf(ChiSquare_cdf(40.,15.,400.),1.7591537203233557e-46)
%!test __test_cdf(ChiSquare_cdf(40.,20.,0.),0.9950045876916924)
%!test __test_cdf(ChiSquare_cdf(40.,20.,15.),0.7139045640824745)
%!test __test_cdf(ChiSquare_cdf(40.,20.,50.),0.014989144847017681)
%!test __test_cdf(ChiSquare_cdf(40.,20.,120.),4.147473013071116e-9)
%!test __test_cdf(ChiSquare_cdf(40.,20.,400.),8.249316210739692e-48)
%!test __test_cdf(ChiSquare_cdf(40.,75.,0.),0.0003039198942431696)
%!test __test_cdf(ChiSquare_cdf(40.,75.,15.),6.4559416906393935e-6)
%!test __test_cdf(ChiSquare_cdf(40.,75.,50.),3.2642924125441744e-10)
%!test __test_cdf(ChiSquare_cdf(40.,75.,120.),8.386525331629643e-20)
%!test __test_cdf(ChiSquare_cdf(40.,75.,400.),7.939825303427623e-64)
%!test __test_cdf(ChiSquare_cdf(40.,150.,0.),4.252751341829973e-21)
%!test __test_cdf(ChiSquare_cdf(40.,150.,15.),1.6379295606637303e-23)
%!test __test_cdf(ChiSquare_cdf(40.,150.,50.),3.215969081520923e-29)
%!test __test_cdf(ChiSquare_cdf(40.,150.,120.),6.965372096189379e-41)
%!test __test_cdf(ChiSquare_cdf(40.,150.,400.),1.2393294919177327e-89)
%!test __test_cdf(ChiSquare_cdf(80.,1.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(80.,1.,15.),0.9999994303292139)
%!test __test_cdf(ChiSquare_cdf(80.,1.,50.),0.9694795550967868)
%!test __test_cdf(ChiSquare_cdf(80.,1.,120.),0.022206105181483828)
%!test __test_cdf(ChiSquare_cdf(80.,1.,400.),1.0283059632588248e-28)
%!test __test_cdf(ChiSquare_cdf(80.,2.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(80.,2.,15.),0.999999324301444)
%!test __test_cdf(ChiSquare_cdf(80.,2.,50.),0.9648762570308186)
%!test __test_cdf(ChiSquare_cdf(80.,2.,120.),0.019666113257821593)
%!test __test_cdf(ChiSquare_cdf(80.,2.,400.),6.847145063803949e-29)
%!test __test_cdf(ChiSquare_cdf(80.,4.,0.),0.9999999999999998)
%!test __test_cdf(ChiSquare_cdf(80.,4.,15.),0.9999989234984757)
%!test __test_cdf(ChiSquare_cdf(80.,4.,50.),0.9539641241549137)
%!test __test_cdf(ChiSquare_cdf(80.,4.,120.),0.015319281395466426)
%!test __test_cdf(ChiSquare_cdf(80.,4.,400.),3.0232379184333603e-29)
%!test __test_cdf(ChiSquare_cdf(80.,5.,0.),0.9999999999999991)
%!test __test_cdf(ChiSquare_cdf(80.,5.,15.),0.9999985653558089)
%!test __test_cdf(ChiSquare_cdf(80.,5.,50.),0.9475676092834168)
%!test __test_cdf(ChiSquare_cdf(80.,5.,120.),0.01347429993785082)
%!test __test_cdf(ChiSquare_cdf(80.,5.,400.),2.004692479907839e-29)
%!test __test_cdf(ChiSquare_cdf(80.,10.,0.),0.999999999999498)
%!test __test_cdf(ChiSquare_cdf(80.,10.,15.),0.999992149514936)
%!test __test_cdf(ChiSquare_cdf(80.,10.,50.),0.9045084903176945)
%!test __test_cdf(ChiSquare_cdf(80.,10.,120.),0.00685200255974378)
%!test __test_cdf(ChiSquare_cdf(80.,10.,400.),2.5169014976137993e-30)
%!test __test_cdf(ChiSquare_cdf(80.,15.,0.),0.9999999999301534)
%!test __test_cdf(ChiSquare_cdf(80.,15.,15.),0.999955445224877)
%!test __test_cdf(ChiSquare_cdf(80.,15.,50.),0.8399140310698817)
%!test __test_cdf(ChiSquare_cdf(80.,15.,120.),0.0032875413783638656)
%!test __test_cdf(ChiSquare_cdf(80.,15.,400.),3.0520247670744765e-31)
%!test __test_cdf(ChiSquare_cdf(80.,20.,0.),0.9999999960740678)
%!test __test_cdf(ChiSquare_cdf(80.,20.,15.),0.9997798725831025)
%!test __test_cdf(ChiSquare_cdf(80.,20.,50.),0.7521022416849387)
%!test __test_cdf(ChiSquare_cdf(80.,20.,120.),0.0014874117233941227)
%!test __test_cdf(ChiSquare_cdf(80.,20.,400.),3.5745202710349446e-32)
%!test __test_cdf(ChiSquare_cdf(80.,75.,0.),0.674972394517258)
%!test __test_cdf(ChiSquare_cdf(80.,75.,15.),0.25349572059136516)
%!test __test_cdf(ChiSquare_cdf(80.,75.,50.),0.0035288826831882223)
%!test __test_cdf(ChiSquare_cdf(80.,75.,120.),4.788392506417521e-9)
%!test __test_cdf(ChiSquare_cdf(80.,75.,400.),2.0719507718439235e-43)
%!test __test_cdf(ChiSquare_cdf(80.,150.,0.),5.084340996560126e-7)
%!test __test_cdf(ChiSquare_cdf(80.,150.,15.),1.2638268739653603e-8)
%!test __test_cdf(ChiSquare_cdf(80.,150.,50.),1.2719279206475188e-12)
%!test __test_cdf(ChiSquare_cdf(80.,150.,120.),2.249233500962962e-21)
%!test __test_cdf(ChiSquare_cdf(80.,150.,400.),1.3286588734176838e-61)
%!test __test_cdf(ChiSquare_cdf(200.,1.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,1.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,1.,50.),0.9999992635516508)
%!test __test_cdf(ChiSquare_cdf(200.,1.,120.),0.9992817121570922)
%!test __test_cdf(ChiSquare_cdf(200.,1.,400.),2.344284469336039e-9)
%!test __test_cdf(ChiSquare_cdf(200.,2.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,2.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,2.,50.),0.9999992635514168)
%!test __test_cdf(ChiSquare_cdf(200.,2.,120.),0.9991757062827389)
%!test __test_cdf(ChiSquare_cdf(200.,2.,400.),1.9608257827334055e-9)
%!test __test_cdf(ChiSquare_cdf(200.,4.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,4.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,4.,50.),0.9999992635505939)
%!test __test_cdf(ChiSquare_cdf(200.,4.,120.),0.9989192237549719)
%!test __test_cdf(ChiSquare_cdf(200.,4.,400.),1.368269306194939e-9)
%!test __test_cdf(ChiSquare_cdf(200.,5.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,5.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,5.,50.),0.999999263549899)
%!test __test_cdf(ChiSquare_cdf(200.,5.,120.),0.9987651851564103)
%!test __test_cdf(ChiSquare_cdf(200.,5.,400.),1.1414978228958086e-9)
%!test __test_cdf(ChiSquare_cdf(200.,10.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,10.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,10.,50.),0.9999992635387218)
%!test __test_cdf(ChiSquare_cdf(200.,10.,120.),0.9976488607628722)
%!test __test_cdf(ChiSquare_cdf(200.,10.,400.),4.553687181261618e-10)
%!test __test_cdf(ChiSquare_cdf(200.,15.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,15.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,15.,50.),0.9999992634788594)
%!test __test_cdf(ChiSquare_cdf(200.,15.,120.),0.9956857954122629)
%!test __test_cdf(ChiSquare_cdf(200.,15.,400.),1.7777175812905283e-10)
%!test __test_cdf(ChiSquare_cdf(200.,20.,0.),1.)
%!test __test_cdf(ChiSquare_cdf(200.,20.,15.),0.999999625021075)
%!test __test_cdf(ChiSquare_cdf(200.,20.,50.),0.9999992631832745)
%!test __test_cdf(ChiSquare_cdf(200.,20.,120.),0.9923722520637899)
%!test __test_cdf(ChiSquare_cdf(200.,20.,400.),6.791518109396686e-11)
%!test __test_cdf(ChiSquare_cdf(200.,75.,0.),0.9999999999997424)
%!test __test_cdf(ChiSquare_cdf(200.,75.,15.),0.9999996217383442)
%!test __test_cdf(ChiSquare_cdf(200.,75.,50.),0.9997616465991253)
%!test __test_cdf(ChiSquare_cdf(200.,75.,120.),0.5926154682261144)
%!test __test_cdf(ChiSquare_cdf(200.,75.,400.),4.1134655784977865e-16)
%!test __test_cdf(ChiSquare_cdf(200.,150.,0.),0.9960268140291784)
%!test __test_cdf(ChiSquare_cdf(200.,150.,15.),0.9613423985376754)
%!test __test_cdf(ChiSquare_cdf(200.,150.,50.),0.5142785557024798)
%!test __test_cdf(ChiSquare_cdf(200.,150.,120.),0.003418539794364018)
%!test __test_cdf(ChiSquare_cdf(200.,150.,400.),4.701174535943039e-25)
