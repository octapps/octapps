function [ephemE, ephemS] = init_barycenter(efile, sfile)

% function [ephemE, ephemS] = init_barycenter(efile, sfile)
%
% This function takes in the filenames of a file containing the Earth
% ephemeris (efile) and Sun ephemeris (sfile) in the format of those within
% LAL e.g. earth05-09.dat, sun05-09.dat. It outputs that data in a format
% usuable by the barycentring codes - positions, velocities and
% acceleration:
%   ephem.pos - vector of x, y and z positions (light seconds)
%   ephem.vel - vector of x, y and z velocities (light seconds/second)
%   ephem.acc - vector of x, y and z accelerations (light seconds/second^2)
%
%   ephem.gps - vector of GPS times of the entries
%   ephem.nentries - number of entries in file
%   ephem.dttable - times difference between entries (seconds)
%
% This function is copied from the LAL function LALInitBarycenter.

% open earth file
fp1 = fopen(efile);

% check that we could open the file
if fp1 == -1
    error('Error, could not open Earth ephemeris file');
end

% read first line
line1 = fgetl(fp1);
line1vals = sscanf(line1, '%f%f%f');

% check that it's read in the right number of values
if length(line1vals) ~= 3
    error('Error readin first line of Earth file');
end

ephemE.dttable = line1vals(2);
ephemE.nentries = line1vals(3);

% allocate memory for ephemeris info
ephemE.pos = zeros(ephemE.nentries,3);
ephemE.vel = zeros(ephemE.nentries,3);
ephemE.acc = zeros(ephemE.nentries,3);

ephemE.gps = zeros(ephemE.nentries,1);

% first column in earth.dat or sun.dat is gps time--one long integer
% giving the number of secs that have ticked since start of GPS epoch
% +  on 1980 Jan. 6 00:00:00 UTC

% read the remaining lines
ret = fscanf(fp1, '%le %le %le %le %le %le %le %le %le %le', ...
    [10 ephemE.nentries]);

ephemE.gps = ret(1,:)';
ephemE.pos = ret(2:4, :)';
ephemE.vel = ret(5:7, :)';
ephemE.acc = ret(8:10, :)';

fclose(fp1);

clear line1 line1vals;

% open sun file
fp1 = fopen(sfile);

% check that we could open the file
if fp1 == -1
    error('Error, could not open Sun ephemeris file');
end

% read first line
line1 = fgetl(fp1);
line1vals = sscanf(line1, '%f%f%f');

% check that it's read in the right number of values
if length(line1vals) ~= 3
    error('Error readin first line of Earth file');
end

ephemS.dttable = line1vals(2);
ephemS.nentries = line1vals(3);

% allocate memory for ephemeris info
ephemS.pos = zeros(ephemS.nentries,3);
ephemS.vel = zeros(ephemS.nentries,3);
ephemS.acc = zeros(ephemS.nentries,3);

ephemS.gps = zeros(ephemS.nentries,1);

% first column in earth.dat or sun.dat is gps time--one long integer
% giving the number of secs that have ticked since start of GPS epoch
% +  on 1980 Jan. 6 00:00:00 UTC


% read the remaining lines
ret = fscanf(fp1, '%le %le %le %le %le %le %le %le %le %le', ...
    [10 ephemS.nentries]);

ephemS.gps = ret(1,:)';
ephemS.pos = ret(2:4, :)';
ephemS.vel = ret(5:7, :)';
ephemS.acc = ret(8:10, :)';

fclose(fp1);
