## Copyright (C) 2015 David Keitel
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
## @deftypefn {Function File} {@var{outvalue} =} ConvertLRStransitionScaleParams ( @var{outname}, @var{inname}, @var{invalue}, @var{Nseg} )
##
## function to convert between various parametrisations of the line-robust statistic transition scale
## reference: Keitel, Prix, Papa, Leaci, Siddiq, PRD 89(6):064023 (2014)
##
## outname/inname can be any of:
## "Fstar0" as defined in Eq. (38), not to be confused with the semicoherent Fstar0hat
## "Fstar0hat" as defined in Eq. (57)
## "pFAstar0" as defined in Eq. (67)
## "cstar" as defined in Eq. (11)
## "LVrho" (deprecated) as defined in footnote 1 (p4)
##
## Nseg is optional and will be assumed 1 by default
##
## @end deftypefn

function outvalue = ConvertLRStransitionScaleParams ( outname, inname, invalue, Nseg=1 )

  supported_params = {"Fstar0","Fstar0hat","pFAstar0","cstar","LVrho"};

  if ( !exist("outname","var") || !exist("inname","var") || !exist("invalue","var") )
    error("Need at least three input arguments: outname, inname, invalue. (optional fourth argument: Nseg)");
  endif

  if ( !ischar(outname) || !ischar(inname) )
    error("First two input arguments (name of output/input variable) must be character strings.");
  endif

  if ( !any(strcmp(outname,supported_params)) )
    error("Requested unsupported output parametrisation '%s'. Supported parameters:\n %s", outname, list_in_columns(supported_params));
  endif

  if ( !any(strcmp(inname,supported_params)) )
    error("Requested unsupported input parametrisation '%s'. Supported parameters:\n %s", inname, list_in_columns(supported_params));
  endif

  if ( !isnumeric(invalue) || !isscalar(invalue) || !isreal(invalue) )
    error("Third input argument (input value) must be a real scalar.");
  endif

  if ( !isnumeric(Nseg) || !isscalar(Nseg) || !isreal(Nseg) || mod(Nseg,1) || ( Nseg < 1 ) )
    error("Fourth input argument (Nseg) must be a scalar, positive integer.");
  endif

  if ( strcmp(outname,inname) )

    outvalue = invalue;

  else

    switch inname
      case "Fstar0"
        Fstar0 = invalue;
      case "Fstar0hat"
        Fstar0 = invalue/Nseg;
      case "pFAstar0"
        Fstar0 = invFalseAlarm_chi2(invalue,4*Nseg)/(2*Nseg);
      case "cstar"
        Fstar0 = log(invalue);
      case "LVrho"
        cstar = (invalue^4/70)^(1/Nseg);
        Fstar0 = log(cstar);
    endswitch

    switch outname
      case "Fstar0"
        outvalue = Fstar0;
      case "Fstar0hat"
        outvalue = Nseg*Fstar0;
      case "pFAstar0"
        outvalue = falseAlarm_chi2 ( 2*Nseg*Fstar0, 4*Nseg );
      case "cstar"
        if ( exist("cstar","var") )
          outvalue = cstar;
        else
          outvalue = exp(Fstar0);
        endif
      case "LVrho"
        outvalue = 70^(0.25)*exp(Fstar0*Nseg/4);
    endswitch

  endif

endfunction ## ConvertLRStransitionScaleParams()

%!assert(ConvertLRStransitionScaleParams("Fstar0", "LVrho", 1.23), -3.4204, 1e-3)
