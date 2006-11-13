
%% define common units and physical constants

% 1 erg = 1 g cm^2 / s^2 
% 1 Joule = 1e7 ergs
% 1 Tesla = 1e4 Gauss

%
%% the following are taken from LALConstants.h:1.11
%
%% Exact physical constants
%% The following physical constants are defined to have exact values.
%% The values of \f$c\f$ and \f$g\f$ are taken from Barnet (1996),
%% \f$p_\mathrm{atm}\f$ is from Lang (1992), while \f$\epsilon_0\f$ and
%% \f$\mu_0\f$ are computed from \f$c\f$ using exact formulae.  They are given in
%% the SI units shown. 

C_SI 		= 299792458; 					%% Speed of light in vacuo, m s^-1 
EPSILON0_SI	= 8.8541878176203898505365630317107503e-12; 	%% Permittivity of free space, C^2 N^-1 m^-2 
MU0_SI		= 1.2566370614359172953850573533118012e-6; 	%% Permeability of free space, N A^-2 
GEARTH_SI	= 9.80665;					%% Standard gravity, m s^-2
PATM_SI		= 101325; 					%% Standard atmosphere, Pa 


%% Physical constants
%% The following are measured fundamental physical constants, with values
%% given in Barnet (1996).  When not dimensionless, they are given
%% in the SI units shown. */
G_SI		= 6.67259e-11;    	%% Gravitational constant, N m^2 kg^-2 
H_SI		= 6.6260755e-34;  	%% Planck constant, J s 
HBAR_SI		= 1.05457266e-34; 	%% Reduced Planck constant, J s 
MPL_SI		= 2.17671e-8; 		%% Planck mass, kg 
LPL_SI		= 1.61605e-35; 		%% Planck length, m 
TPL_SI		= 5.39056e-44; 		%% Planck time, s 
K_SI		= 1.380658e-23; 	%% Boltzmann constant, J K^-1 */
R_SI		= 8.314511;		%% Ideal gas constant, J K^-1 
MOL		= 6.0221367e23;		%% Avogadro constant, dimensionless 
BWIEN_SI	= 2.897756e-3;    	%% Wien displacement law constant, m K 
SIGMA_SI	= 5.67051e-8; 		%% Stefan-Boltzmann constant, W m^-2 K^-4 
AMU_SI		= 1.6605402e-27; 	%% Atomic mass unit, kg 
MP_SI		= 1.6726231e-27;	%% Proton mass, kg 
ME_SI		= 9.1093897e-31; 	%% Electron mass, kg 
QE_SI		= 1.60217733e-19;	%% Electron charge, C 
ALPHA		= 7.297354677e-3;	%% Fine structure constant, dimensionless 
RE_SI		= 2.81794092e-15; 	%% Classical electron radius, m 
LAMBDAE_SI	= 3.86159323e-13;	%% Electron Compton wavelength, m 
AB_SI		= 5.29177249e-11;	%% Bohr radius, m 
MUB_SI		= 9.27401543e-24;	%% Bohr magneton, J T^-1 
MUN_SI		= 5.05078658e-27;	%% Nuclear magneton, J T^-1 


%% Astrophysical parameters
%% The following parameters are derived from measured properties of the
%% Earth and Sun.  The values are taken from Barnet (1996), except
%% for the obliquity of the ecliptic plane and the eccentricity of
%% Earth's orbit, which are taken from Lang (1992).  All values are
%% given in the SI units shown. */
REARTH_SI	= 6.378140e6;		%% Earth equatorial radius, m 
AWGS84_SI	= 6.378137e6;		%% Semimajor axis of WGS-84 Reference Ellipsoid, m 
BWGS84_SI	= 6.356752314e6;	%% Semiminor axis of WGS-84 Reference Ellipsoid, m 
MEARTH_SI	= 5.97370e24;		%% Earth mass, kg 
IEARTH		= 0.409092804;		%% Earth inclination (2000), radians 
EEARTH		= 0.0167;		%% Earth orbital eccentricity 
RSUN_SI		= 6.960e8;		%% Solar equatorial radius, m 
MSUN_SI		= 1.98892e30;		%% Solar mass, kg 
MRSUN_SI	= 1.47662504e3;		%% Geometrized solar mass, m 
MTSUN_SI	= 4.92549095e-6;	%% Geometrized solar mass, s 
LSUN_SI		= 3.846e26;		%% Solar luminosity, W 
AU_SI		= 1.4959787066e11;	%% Astronomical unit, m 
PC_SI		= 3.0856775807e16;	%% Parsec, m 
YRTROP_SI	= 31556925.2;		%% Tropical year (1994), s 
YRSID_SI	= 31558149.8;		%% Sidereal year (1994), s 
DAYSID_SI	= 86164.09053;		%% Mean sidereal day, s 
LYR_SI		= 9.46052817e15;	%% ``Tropical'' lightyear (1994), m 


