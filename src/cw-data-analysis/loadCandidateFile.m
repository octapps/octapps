## Copyright (C) 2006 Reinhard Prix
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
## @deftypefn {Function File} {} loadCandidateFile ( @var{fname} )
##
## loads a 'candidate-file' from @command{lalapps_ComputeFStatistic_v2 --outputLoudest=cand.file}
## and returns a struct containing the data
##
## @end deftypefn

function ret = loadCandidateFile ( fname )
  source ( fname );     ## uses only local variables!

  ## amplitude params with error-estimates
  ret.phi0    = phi0;
  ret.dphi0   = dphi0;
  ret.psi     = psi;
  ret.dpsi    = dpsi;
  ret.h0      = h0;
  ret.dh0     = dh0;
  ret.cosi    = cosi;
  ret.dcosi   = dcosi;

  ## Doppler params
  ret.Alpha   = Alpha;
  ret.Delta   = Delta;
  ret.refTime = refTime;
  ret.Freq    = Freq;
  ret.f1dot   = f1dot;
  ret.f2dot   = f2dot;
  ret.f3dot   = f3dot;

  ## Antenna-pattern matrix M_mu_nu:
  ret.Ad       =  Ad;
  ret.Bd       =  Bd;
  ret.Cd       =  Cd;
  ret.Sinv_Tsft=  Sinv_Tsft;

  ## Fstat-results
  ret.Fa      = Fa;
  ret.Fb      = Fb;
  ret.twoF    = twoF;

endfunction

%!test
%!  if isempty(file_in_path(getenv("PATH"), "lalapps_ComputeFstatistic_v2"))
%!    disp("skipping test: LALApps programs not available"); return;
%!  endif
%!  output = nthargout(2, @system, "lalapps_ComputeFstatistic_v2 --version");
%!  LALApps_version = versionstr2hex(nthargout(5, @regexp, output, "LALApps: ([0-9.]+)"){1}{1,1});
%!  if LALApps_version <= 0x06210000
%!    disp("cannot run test as version of lalapps_ComputeFstatistic_v2 is too old"); return;
%!  endif
%!  args = struct;
%!  args.Alpha = 1.2;
%!  args.Delta = 3.4;
%!  args.Freq = 100;
%!  args.f1dot = -1e-8;
%!  args.Tsft = 1800;
%!  args.IFOs = "H1";
%!  args.injectSqrtSX = 1.0;
%!  args.timestampsFiles = tempname(tempdir);
%!  args.outputLoudest = tempname(tempdir);
%!  fid = fopen(args.timestampsFiles, "w");
%!  fprintf(fid, "800000000\n800001800\n800003600\n");
%!  fclose(fid);
%!  runCode(args, "lalapps_ComputeFstatistic_v2");
%!  cand_file = loadCandidateFile(args.outputLoudest);
%!  assert(isstruct(cand_file));
