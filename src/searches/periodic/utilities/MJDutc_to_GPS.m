%% convert MJD (based on UTC) into GPS seconds 
%% translated from lalapps-CVS/src/pulsar/TDS_isolated/TargetedPulsars.c
%% This conversion corresponds to what lalapps_tconvert does, but
%% is NOT the right thing for pulsar timing, as pulsar-epochs are typically 
%% given in MJD(TDB) ! ==> use MJDtdb_to_GPS.m for that purpose!

function GPS = MJDutc_to_GPS ( MJDutc )

  REF_GPS_SECS=793130413.0; 
  REF_MJD=53423.75; 
  
  GPS = (-REF_MJD + MJDutc) * 86400.0 + REF_GPS_SECS;

  return;

endfunction
