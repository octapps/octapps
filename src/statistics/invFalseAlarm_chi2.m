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