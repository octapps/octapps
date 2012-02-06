function emit = barycenter(baryinput, earth)

% function emit = barycenter(baryinput, earth)
%
% This function takes in a structure, baryinput, which contains information
% about the detector and source for which the barycentring is required:
% Detector:
%   baryinput.site.location - a three element vector containing the x, y, z
%       location of a detector position on the Earth's surface
%   baryinput.tgps - a structure containing the GPS time in seconds (s)
%       and nanoseconds (ns) at the detector
% Source:
%   baryinput.alpha - the right ascension of the source in rads
%   baryinput.delta - the declination of the source in rads
%   baryinput.dInv - inverse distance to source (generally set this to zero
%       unless the source is very close)
%
% The function also takes in the earth structure produced by
% barycenter_earth.m.
%
% The function transforms a detector arrival time (ta) to pulse emission
% time (te) in % TDB (plus the constant light-travel-time from source to
% SSB). Also returned is the time derivative dte/dta, and the time
% difference te(ta) - ta. This is contained in the emit structure:
%   emit.te - pulse emission time
%   emit.tDot - time derivative
%   emit.deltaT - time difference
%   emit.roemer - Roemer delay
%   emit.erot - delay due to Earth's rotation
%   emit.einstein - Einstein delay
%   emit.shapiro - Shapiro delay
%
% This function is a Matlab-ified version of Curt Cutler's LAL function
% LALBarycenter.

% ang. vel. of Earth (rad/sec)
OMEGA = 7.29211510e-5;

s = zeros(3,1); % unit vector pointing at source, in J2000 Cartesian coords

tgps = zeros(2,1);

tgps(1) = baryinput.tgps.s;
tgps(2) = baryinput.tgps.ns;

alpha = baryinput.alpha;
delta = baryinput.delta;

% check that alpha and delta are in reasonable range
if abs(alpha) > 2*pi || abs(delta) > 0.5*pi
      disp('Source position is not in reasonable range');
      emit = 0;
      return;
end

sinTheta=sin(pi/2.0-delta);
s(3)=cos(pi/2.0-delta);    % s is vector that points towards source
s(2)=sinTheta*sin(alpha);  % in Cartesian coords based on J2000
s(1)=sinTheta*cos(alpha);  % 0=x,1=y,2=z

rd = sqrt( baryinput.site.location(1)*baryinput.site.location(1) ...
    + baryinput.site.location(2)*baryinput.site.location(2) ...
    + baryinput.site.location(3)*baryinput.site.location(3));

latitude = pi/2 - acos(baryinput.site.location(3)/rd);
longitude = atan2(baryinput.site.location(2), baryinput.site.location(1));

% ********************************************************************
% Calucate Roemer delay for detector at center of Earth.
% We extrapolate from a table produced using JPL DE405 ephemeris.
% ---------------------------------------------------------------------

roemer = 0;
droemer = 0;

for j=1:3
    roemer = roemer + s(j)*earth.posNow(j);
    droemer = droemer + s(j)*earth.velNow(j);
end

% ********************************************************************
% Now including Earth's rotation
% ---------------------------------------------------------------------

% obliquity of ecliptic at JD 245145.0, in radians. NOT! to be confused
% with permittivity of free space; value from Explan. Supp. to Astronom.
% Almanac:
% eps0 = (23 + 26/60 + 21.448/3.6e3)*pi/180;
eps0 = 0.40909280422232891;

cosDeltaSinAlphaMinusZA = sin(alpha + earth.tzeA)*cos(delta);

cosDeltaCosAlphaMinusZA = cos(alpha + earth.tzeA)*cos(earth.thetaA) ...
    *cos(delta) - sin(earth.thetaA)*sin(delta);

sinDelta = cos(alpha + earth.tzeA)*sin(earth.thetaA)*cos(delta) ...
    + cos(earth.thetaA)*sin(delta);

% now taking NdotD, including lunisolar precession, using Eqs. 3.212-2 of
% Explan. Supp. Basic idea for incorporating luni-solar precession is to
% change the (alpha,delta) of source to compensate for Earth's
% time-changing spin axis.

NdotD = sin(latitude)*sinDelta +cos(latitude)*( ...
    cos(earth.gastRad+longitude-earth.zA)*cosDeltaCosAlphaMinusZA ...
    + sin(earth.gastRad+longitude-earth.zA)*cosDeltaSinAlphaMinusZA );

erot = rd*NdotD;

derot = OMEGA*rd*cos(latitude)*( ...
    - sin(earth.gastRad+longitude-earth.zA)*cosDeltaCosAlphaMinusZA ...
    + cos(earth.gastRad+longitude-earth.zA)*cosDeltaSinAlphaMinusZA );


% --------------------------------------------------------------------------
% Now adding approx nutation (= short-period,forced motion, by definition).
% These two dominant terms, with periods 18.6 yrs (big term) and
% 0.500 yrs (small term),resp., give nutation to around 1 arc sec; see
% p. 120 of Explan. Supp. The forced nutation amplitude
%  is around 17 arcsec.
%
% Note the unforced motion or Chandler wobble (called ``polar motion''
% in Explanatory Supp) is not included here. However its amplitude is
% order of (and a somewhat less than) 1 arcsec; see plot on p. 270 of
% Explanatory Supplement to Ast. Alm.
%
% Below correction for nutation from Eq.3.225-2 of Explan. Supp.
% Basic idea is to change the (alpha,delta) of source to
% compensate for Earth's time-changing spin axis.
%--------------------------------------------------------------------------

delXNut = -(earth.delpsi)*(cos(delta)*sin(alpha)*cos(eps0) ...
    + sin(delta)*sin(eps0));

delYNut = cos(delta)*cos(alpha)*cos(eps0)*(earth.delpsi) ...
    - sin(delta)*(earth.deleps);

delZNut = cos(delta)*cos(alpha)*sin(eps0)*(earth.delpsi) ...
    + cos(delta)*sin(alpha)*(earth.deleps);

NdotDNut = sin(latitude)*delZNut ...
    + cos(latitude)*cos(earth.gastRad+longitude)*delXNut ...
    + cos(latitude)*sin(earth.gastRad+longitude)*delYNut;

erot = erot + rd*NdotDNut;

derot = derot + OMEGA*rd*( ...
    - cos(latitude)*sin(earth.gastRad+longitude)*delXNut ...
    + cos(latitude)*cos(earth.gastRad+longitude)*delYNut );

% Note erot has a periodic piece (P=one day) AND a constant piece,
% since z-component (parallel to North pole) of vector from
% Earth-center to detector is constant

% ********************************************************************
% Now adding Shapiro delay. Note according to J. Taylor review article
% on pulsar timing, max value of Shapiro delay (when rays just graze sun)
% is 120 microsec.
%
% Here we calculate Shapiro delay
% for a detector at the center of the Earth.
% Causes errors of order 10^{-4}sec * 4 * 10^{-5} = 4*10^{-9} sec
% --------------------------------------------------------------------

rsun = 2.322; % radius of sun in sec
seDotN = earth.se(3)*sin(delta)+ (earth.se(1)*cos(alpha) ...
    + earth.se(2)*sin(alpha))*cos(delta);

dseDotN = earth.dse(3)*sin(delta)+(earth.dse(1)*cos(alpha) ...
    + earth.dse(2)*sin(alpha))*cos(delta);

b = sqrt(earth.rse*earth.rse-seDotN*seDotN);
db = (earth.rse*earth.drse-seDotN*dseDotN)/b;

AU_SI = 1.4959787066e11; % AU in m
C_SI = 299792458; % speed of light in vacuum in m/s

if b < rsun && seDotN < 0 % if gw travels thru interior of Sun
    shapiro  = 9.852e-6*log( (AU_SI/C_SI) / ...
        (seDotN + sqrt(rsun*rsun + seDotN*seDotN))) ...
        + 19.704e-6*(1 - b/rsun);
	dshapiro = - 19.704e-6*db/rsun;
else  %else the usual expression
    shapiro  = 9.852e-6*log( (AU_SI/C_SI)/(earth.rse + seDotN));
    dshapiro = -9.852e-6*(earth.drse + dseDotN)/(earth.rse + seDotN);
end

% ********************************************************************
% Now correcting Roemer delay for finite distance to source.
% Timing corrections are order 10 microsec
% for sources closer than about 100 pc = 10^10 sec.
% --------------------------------------------------------------------

r2 = 0.; % squared dist from SSB to center of earth, in sec^2
dr2 = 0.; % time deriv of r2

if baryinput.dInv > 1.0e-11 %implement if corr.  > 1 microsec
    for j=1:3
        r2 = r2 + earth.posNow(j)*earth.posNow(j);
        dr2 = dr2 + 2*earth.posNow(j)*earth.velNow(j);
    end

    finiteDistCorr = -0.5e0*(r2 - roemer*roemer)*baryinput.dInv;
    dfiniteDistCorr = -(0.5e0*dr2 - roemer*droemer)*baryinput.dInv;

else
	finiteDistCorr = 0;
    dfiniteDistCorr = 0;
end

% -----------------------------------------------------------------------
% Now adding it all up.
% emit.te is pulse emission time in TDB coords
% (up to a constant roughly equal to ligh travel time from source to SSB).
% emit->deltaT = emit.te - tgps.
% -----------------------------------------------------------------------

emit.deltaT = roemer + erot + earth.einstein - shapiro + finiteDistCorr;

emit.tDot = 1.e0 + droemer + derot + earth.deinstein ...
    - dshapiro + dfiniteDistCorr;

deltaTint = floor(emit.deltaT);

if 1.e-9*tgps(2) + emit.deltaT - deltaTint >= 1
    emit.te.s = baryinput.tgps.s + deltaTint + 1;
    emit.te.ns = floor(1.e9*(tgps(2)*1.e-9 + emit.deltaT - deltaTint - 1));
else
    emit.te.s = baryinput.tgps.s + deltaTint;
    emit.te.ns = floor(1.e9*(tgps(2)*1.e-9 + emit.deltaT - deltaTint));
end

emit.roemer = roemer;
emit.erot = erot;
emit.einstein = earth.einstein;
emit.shapiro = -shapiro;
