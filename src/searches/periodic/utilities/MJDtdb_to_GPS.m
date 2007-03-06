%% convert MJD (based on TDB) into GPS seconds 
%% translated from LAL-function LALTDBMJDtoGPS() in BinaryPulsarTiming.c
%%
function GPS = MJDtdb_to_GPS ( MJD_tdb )
  
  %% Check not before the start of GPS time (MJD 44222)
  if(MJD_tdb < 44244)
    error("Input time is not in range [earlier than MJD0=44244].\n");
  endif

  Tdiff = MJD_tdb + (2400000.5 - 2451545.0);
  meanAnomaly = 357.53 + 0.98560028 * Tdiff; 	%% mean anomaly in degrees 
  meanAnomaly *= pi/180; 			%% mean anomaly in rads
  
  TDBtoTT = 0.001658 * sin(meanAnomaly) + 0.000014 * sin(2 * meanAnomaly); %% time diff in seconds

  %% convert TDB to TT (TDB-TDBtoTT) and then convert TT to GPS
  %% there is the magical number factor of 32.184 + 19 leap seconds to the start of GPS time
  GPS = ( MJD_tdb - 44244) * 86400 - 51.184 - TDBtoTT;

  return;

endfunction


