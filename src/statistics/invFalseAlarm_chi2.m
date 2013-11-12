%% Copyright (C) 2011 Reinhard Prix
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with with program; see the file COPYING. If not, write to the
%% Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%% MA  02111-1307  USA

%% thresh = invFalseAlarm_chi2 ( fA, dof )
%%
%% compute the threshold on a central chi^2 distribution with 'dof'
%% degrees of freedom, corresponding to a false-alarm probability
%% of 'fA'
%%

function thresh = invFalseAlarm_chi2 ( fA, dof )

  if ( dof < 1000 )
    thresh = chi2inv ( 1 - fA, dof );
  else	%% large N case better handled by asymptotic expression
    thresh = invFalseAlarm_chi2_asym(fA, dof);
  endif

endfunction