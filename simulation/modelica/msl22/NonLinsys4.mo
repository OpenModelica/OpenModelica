model NonLinSys4
  parameter Real ResidenceTime=50;
  parameter Real h_water=4 "Height of water-oil interface at end of separator";
  parameter Real h_max=2 "Height of separation plate";
  parameter Real H0=5 "Initial height of dispersion";
  parameter Real phi0=0.001 "Initial size of drops";
  parameter Real epsp=0.65 "Holdup fraction in oil-emulsion";
  parameter Real tau0=24 "Coalescence time  ";
  parameter Real g=9.81;
  parameter Real muc=1.15 "Viscosity of continuous phase";
  parameter Real rhoc=920 "Density of continuous phase";
  parameter Real deltarho=200 "Density differance";
  Real ti "time for inflection point";
  Real eps0 "Initial holdup";
  Real psii;
  Real V;
  Real deltahi;
  Real v0;
  Real delta;

equation
  eps0=1.0 - h_water/H0 "Initial holdup";
  psii=(epsp*(2*H0*(1 - eps0) - v0*ti))/((1 - epsp)*(3*tau0 + ti));
  V=H0/ti - v0/2 - ((1 - epsp)*psii)/2/epsp;
  deltahi=(1 - eps0)/(1 - epsp)*H0 - (v0*ti)/(2*(1 - epsp)) - (psii*ti)/(2*epsp);
  v0=(12*muc)/(0.53*rhoc*phi0)*(-1 + sqrt(1 + (0.53*rhoc*deltarho*g*phi0^3*(1 - eps0))/(108*muc^2*(1 + 4.56*eps0^0.73))));
  (1 - eps0)/(1 - epsp)*H0 - (epsp*v0*ti)/(2*(1 - epsp)) - (psii*ti)/2=H0 - V*ti - (psii*ti)/log(1 - psii/V);
  delta=H0 - V*time + (V*deltahi)/psii*(1 - exp(-(psii*time)/deltahi));
end NonLinSys4;

