%% Return parameters of various gravitational wave interferometers.
%% Syntax:
%%   [slat, long, gamm, zeta] = DetectorInfo("name")
%% where:
%%   "name" = name of a gravitational wave interferometer
%%   slat   = sin of latitude of interferometer location (in rad. North)
%%   long   = longitude of interferometer location (in rad. East)
%%   gamm   = angle from local East to interferometer arms bisector (in rad.)
%%   zeta   = angle between interferometer arms
function [slat, long, gamm, zeta] = DetectorInfo(name)

  %% references:
  %%   Bruce Allen, "Gravitational Wave Detector Sites", arXiv:gr-qc/9607075v1

  switch name

    %% the limit of a large number of interferometers
    %% distributed uniformly over the Earth,
    %% with uniformly distributed orientations
    case "avg"
      slat = [-1, 1];
      long = [0, 2*pi];
      gamm = [0, 2*pi];
      zeta = pi/2;

    %% LIGO Hanford (source: Allen)
    case "LHO"
      slat = sin( 46.45 * pi/180);
      long =    -119.41 * pi/180;   % Allen gives longitude in deg. West
      arm1 =      36.8  * pi/180;
      arm2 =     126.8  * pi/180;

      gamm = pi/2 + (arm1 + arm2)/2;
      zeta = arm2 - arm1;

    %% LIGO Livingston (source: Allen)
    case "LLO"
      slat = sin( 30.56 * pi/180);
      long =     -90.77 * pi/180;   % Allen gives longitude in deg. West
      arm1 =     108.0  * pi/180;
      arm2 =     198.0  * pi/180;

      gamm = pi/2 + (arm1 + arm2)/2;
      zeta = arm2 - arm1;

    %% VIRGO (source: Allen)
    case "VIRGO"
      slat = sin( 43.63       * pi/180);
      long =      10.5        * pi/180;   % Allen gives longitude in deg. West
      arm1 =    (341.5 - 360) * pi/180;   % Reverse order of arms, since when measuring gamma from
      arm2 =      71.5        * pi/180;   % local East, it is Allen's "arm 2" that comes first

      gamm = pi/2 + (arm1 + arm2)/2;
      zeta = arm2 - arm1;

    otherwise
      error(["Unknown interferometer '" name "'!"]);

  endswitch

endfunction
