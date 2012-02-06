function [emitdt, emitte, emitdd, emitR, emitER, emitE, emitS] = ...
    get_barycenter(tGPS, detector, source, efile, sfile)
% function [emitdt, emitte, emitdd, emitR, emitER, emitE, emitS] = ...
%   get_barycenter(tGPS, detector, source, efile, sfile)
%
% This function is a driver for the solar system barycentring codes:
% init_barycentre, barycenter_earth and barycenter. It takes in a detector
% name (for a variety of GW and radio telescopes [mainly consistent with
% TEMPO naming convensions]) - case insensitive:
% Radio telescopes (from TEMPO2 observatories.dat file):
%   GREEN BANK = 'GB'
%   NARRABRI CS08 = 'NA'
%   ARECIBO XYZ (JPL) = 'AO'
%   Hobart, Tasmania = 'HO'
%   DSS 43 XYZ = 'TD'
%   PARKES  XYZ (JER) = 'PK'
%   JODRELL BANK = 'JB'
%   GB 300FT = 'G3'
%   GB 140FT = 'G1RAD' (changed to distinguish it from GEO)
%   VLA XYZ = 'VL'
%   Nancay = 'NC'
%   Effelsberg = 'EF'
% GW telescopes):
%   LIGO Hanford = 'LHO', 'H1', 'H2'
%   LIGO Livingston = 'LLO', 'L1'
%   GEO 600 = 'GEO', 'G1'
%   VIRGO = 'V1', 'VIRGO'
%   TAMA = 'T1', 'TAMA'
%
% It also takes in a vector of GPS times (tGPS). Ephemeris files for the
% Earth (efile) and Sun (sfile) also need to be specified - these should be
% in the format of the ephemeris files given in LAL e.g. earth05-09.dat,
% sun05-09.dat. The source must be specified with:
%   source.alpha = right ascension in rads
%   source.delta = declination in rads
%
% The output will be vectors of time differences between the arrival time
% at the detector and SSB (emitdt), pulse emission time (emitte), and time
% derivatives (emitdd), and the individual elements making up the time
% delay - the Roemer delay (emitR), the Earth rotation delay (emitER), the
% Einstein delay (emitE) and the Shapiro delay (emitS).

% set speed of light in vacuum (m/s)
C_SI = 299792458;

% set the detector x, y and z positions on the Earth surface. For radio
% telescopes use values from the TEMPO2 observatories.dat file, and for GW
% telescopes use values from LAL.
baryinput.site.location = zeros(3,1);

if strcmpi(detector, 'GB') % GREEN BANK
    baryinput.site.location(1) = 882589.65;
    baryinput.site.location(2) = -4924872.32;
    baryinput.site.location(3) = 3943729.348;
elseif strcmpi(detector, 'NA') % NARRABRI
    baryinput.site.location(1) = -4752329.7000;
    baryinput.site.location(2) = 2790505.9340;
    baryinput.site.location(3) = -3200483.7470;
elseif strcmpi(detector, 'AO') % ARECIBO
    baryinput.site.location(1) = 2390490.0;
    baryinput.site.location(2) = -5564764.0;
    baryinput.site.location(3) = 1994727.0;
elseif strcmpi(detector, 'HO') % Hobart
    baryinput.site.location(1) = -3950077.96;
    baryinput.site.location(2) = 2522377.31;
    baryinput.site.location(3) = -4311667.52;
elseif strcmpi(detector, 'TD') % DSS 43
    baryinput.site.location(1) = -4460892.6;
    baryinput.site.location(2) = 2682358.9;
    baryinput.site.location(3) = -3674756.0;
elseif strcmpi(detector, 'PK') % PARKES
    baryinput.site.location(1) = -4554231.5;
    baryinput.site.location(2) = 2816759.1;
    baryinput.site.location(3) = -3454036.3;
elseif strcmpi(detector, 'JB') % JODRELL BANK
    baryinput.site.location(1) = 3822252.643;
    baryinput.site.location(2) = -153995.683;
    baryinput.site.location(3) = 5086051.443;
elseif strcmpi(detector, 'G3') % GB 300FT
    baryinput.site.location(1) = 881856.58;
    baryinput.site.location(2) = -4925311.86;
    baryinput.site.location(3) = 3943459.70;
elseif strcmpi(detector, 'G1RAD') % GB 140FT
    baryinput.site.location(1) = 882872.57;
    baryinput.site.location(2) = -4924552.73;
    baryinput.site.location(3) = 3944154.92;
elseif strcmpi(detector, 'VL') % VLA
    baryinput.site.location(1) = -1601192.0;
    baryinput.site.location(2) = -5041981.4;
    baryinput.site.location(3) = 3554871.4;
elseif strcmpi(detector, 'NC') % NANCAY
    baryinput.site.location(1) = 4324165.81;
    baryinput.site.location(2) = 165927.11;
    baryinput.site.location(3) = 4670132.83;
elseif strcmpi(detector, 'EF') % Effelsberg
    baryinput.site.location(1) = 4033949.5;
    baryinput.site.location(2) = 486989.4;
    baryinput.site.location(3) = 4900430.8;
elseif strcmpi(detector, 'H1') || strcmpi(detector, 'H2') || ...
        strcmpi(detector, 'LHO') % LIGO Hanford
    baryinput.site.location(1) = -2161414.92636;
    baryinput.site.location(2) = -3834695.17889;
    baryinput.site.location(3) = 4600350.22664;
elseif strcmpi(detector, 'LLO') || strcmpi(detector, 'L1')% LIGO Livingston
    baryinput.site.location(1) = -74276.04472380;
    baryinput.site.location(2) = -5496283.71971000;
    baryinput.site.location(3) = 3224257.01744000;
elseif strcmpi(detector, 'GEO') || strcmpi(detector, 'G1') % GEO600
    baryinput.site.location(1) = 3856309.94926000;
    baryinput.site.location(2) = 666598.95631700;
    baryinput.site.location(3) = 5019641.41725000;
elseif strcmpi(detector, 'V1') || strcmpi(detector, 'VIRGO') % Virgo
    baryinput.site.location(1) = 4546374.09900000;
    baryinput.site.location(2) = 842989.69762600;
    baryinput.site.location(3) = 4378576.96241000;
elseif strcmpi(detector, 'TAMA') || strcmpi(detector, 'T1') % TAMA300
    baryinput.site.location(1) = -3946408.99111000;
    baryinput.site.location(2) = 3366259.02802000;
    baryinput.site.location(3) = 3699150.69233000;
end

% set positions in light seconds
baryinput.site.location(1) = baryinput.site.location(1)/C_SI;
baryinput.site.location(2) = baryinput.site.location(2)/C_SI;
baryinput.site.location(3) = baryinput.site.location(3)/C_SI;

% set source information
baryinput.alpha = source.alpha; % right ascension in radians
baryinput.delta = source.delta; % declination in radians
baryinput.dInv = 0; % inverse distance (assumption is that source is very distant)

% read in ephemeris files
[ephemE, ephemS] = init_barycenter(efile, sfile);

% check this has been read correctly
if ~isstruct(ephemE) || ~isstruct(ephemS)
    if ephemE == 0 || ephemS == 0
        error('Error reading in one of the ephemeris files');
    end
end

% length of time vector
len = length(tGPS);

emitdt = zeros(len,1);
emitte = zeros(len,1);
emitdd = zeros(len,1);
emitR = zeros(len,1);
emitER = zeros(len,1);
emitE = zeros(len,1);
emitS = zeros(len,1);

for i=1:len
    % split time into seconds and nanoseconds
    tt.s = floor(tGPS(i));
    tt.ns = (tGPS(i)-tt.s)*1e9;

    % perform Earth barycentring
    earth = barycenter_earth(ephemE, ephemS, tt);

    baryinput.tgps.s = tt.s;
    baryinput.tgps.ns = tt.ns;

    % perform barycentring
    emit = barycenter(baryinput, earth);

    emitdt(i) = emit.deltaT;
    emitte(i) = emit.te.s + emit.te.ns*1e-9;
    emitdd(i) = emit.tDot;
    emitR(i) = emit.roemer;
    emitER(i) = emit.erot;
    emitE(i) = emit.einstein;
    emitS(i) = emit.shapiro;
end