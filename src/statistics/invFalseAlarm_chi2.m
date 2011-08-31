%% thresh = invFalseAlarm_chi2 ( fA, dof )
%%
%% compute the threshold on a central chi^2 distribution with 'dof'
%% degrees of freedom, corresponding to a false-alarm probability
%% of 'fA'
%%

function thresh = invFalseAlarm_chi2 ( fA, dof )

  thresh = chi2inv ( 1 - fA, dof );

endfunction