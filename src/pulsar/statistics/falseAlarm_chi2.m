%% fA = falseAlarm_chi2 ( thresh, dof )
%%
%% compute the false-alarm probability for given threshold 'thresh'
%% for a (central) chi-squared distribution with 'dof' degrees-of-freedom
%%

function fA = falseAlarm_chi2 ( thresh, dof )

  eta = chi2cdf ( thresh, dof );
  fA = 1 - eta;

endfunction