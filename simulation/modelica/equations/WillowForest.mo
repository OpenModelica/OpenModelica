// name:     WillowForest
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
//
// Drmodelica: 15.4.2 An Energy Forest Annual Growth Model for Willow Trees (p. 559) Not in the notebook
//
class WillowForest
  parameter Real h = 0.95 "Harvest fraction";
  parameter Real[4] e = {.73,.80,.66,.55} "Radiation efficiency fraction";
  parameter Real[4] a = {.59,.73,.76,.74} "Intercepted radiation fraction";
  parameter Integer[10] growthCycles = {1,2,1,2,3,4,1,2,3,4};
  parameter Integer[10] r = {2097, 2328, 1942, 2359, 2493, 2290, 2008, 2356, 2323, 2540} "Solar radiation(MJ/m2) 1985-1994";
  parameter Real[10] m = {.1, .1, .5, .1, .1, .1, .1, .1, .1, .1} "Mortality fraction 1985-1994";
  parameter Integer[10] mbiomasses = {786, 1091, 539, 980, 1139, 589, 723, 1457, 1004, 845} "Measured biomass 1985-1994";
  Integer t (start = 0) "Years since the forest was planted";
  Integer c "Year in growth cycle";
  Real w(start = 60) "Total standing biomass in forest (g/m2)";
  Real wGrowth, wMort, wHarvest "Biomass for growth, mortality and harvest";
  Real wMortAcc (start = 0) "Accumulated dead biomass by mortality";
  Real wBiomass "Biomass produced during a year";
  Integer mbiomass "Measured biomass for current year";
equation
  when sample(0, 1) then

    t = pre(t)+1;
  mbiomass = mbiomasses[t];
  // Harvest first time after two years, then every fourth year
  c = growthCycles[t];
  w = pre(w)+(wGrowth - wMort - wHarvest);
  wBiomass = wGrowth - wMort;
  wGrowth = e[c] * a[c] * r[t];
  // A fraction m of the forest dies every year
  wMort = if (c == 1 and t > 1) then (1-h) * m[t] * (pre(w) + wGrowth) else m[t] * (pre(w) + wGrowth);
    // A fraction of the forest is removed at harvest
    wHarvest = if (c == 1 and t > 1) then h*pre(w) + pre(wMortAcc) else 0;

      // Dead biomass accumulates by mortality
      wMortAcc = if(c == 1) then wMort else pre(wMortAcc) + wMort;

    end when;
end WillowForest;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class WillowForest
//  parameter Real h = 0.95 "Harvest fraction";
//  parameter Real e[1] = 0.73 "Radiation efficiency fraction";
//  parameter Real e[2] = 0.8 "Radiation efficiency fraction";
//  parameter Real e[3] = 0.66 "Radiation efficiency fraction";
//  parameter Real e[4] = 0.55 "Radiation efficiency fraction";
//  parameter Real a[1] = 0.59 "Intercepted radiation fraction";
//  parameter Real a[2] = 0.73 "Intercepted radiation fraction";
//  parameter Real a[3] = 0.76 "Intercepted radiation fraction";
//  parameter Real a[4] = 0.74 "Intercepted radiation fraction";
//  parameter Integer growthCycles[1] = 1;
//  parameter Integer growthCycles[2] = 2;
//  parameter Integer growthCycles[3] = 1;
//  parameter Integer growthCycles[4] = 2;
//  parameter Integer growthCycles[5] = 3;
//  parameter Integer growthCycles[6] = 4;
//  parameter Integer growthCycles[7] = 1;
//   parameter Integer growthCycles[8] = 2;
//   parameter Integer growthCycles[9] = 3;
//   parameter Integer growthCycles[10] = 4;
//   parameter Integer r[1] = 2097 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[2] = 2328 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[3] = 1942 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[4] = 2359 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[5] = 2493 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[6] = 2290 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[7] = 2008 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[8] = 2356 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[9] = 2323 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Integer r[10] = 2540 "Solar radiation(MJ/m2) 1985-1994";
//   parameter Real m[1] = 0.1 "Mortality fraction 1985-1994";
//   parameter Real m[2] = 0.1 "Mortality fraction 1985-1994";
//   parameter Real m[3] = 0.5 "Mortality fraction 1985-1994";
//   parameter Real m[4] = 0.1 "Mortality fraction 1985-1994";
//   parameter Real m[5] = 0.1 "Mortality fraction 1985-1994";
//   parameter Real m[6] = 0.1 "Mortality fraction 1985-1994";
//  parameter Real m[7] = 0.1 "Mortality fraction 1985-1994";
//   parameter Real m[8] = 0.1 "Mortality fraction 1985-1994";
//  parameter Real m[9] = 0.1 "Mortality fraction 1985-1994";
//  parameter Real m[10] = 0.1 "Mortality fraction 1985-1994";
//  parameter Integer mbiomasses[1] = 786 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[2] = 1091 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[3] = 539 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[4] = 980 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[5] = 1139 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[6] = 589 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[7] = 723 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[8] = 1457 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[9] = 1004 "Measured biomass 1985-1994";
//  parameter Integer mbiomasses[10] = 845 "Measured biomass 1985-1994";
//  Integer t(start = 0) "Years since the forest was planted";
//  Integer c "Year in growth cycle";
//  Real w(start = 60.0) "Total standing biomass in forest (g/m2)";
//  Real wGrowth;
//  Real wMort;
//  Real wHarvest "Biomass for growth, mortality and harvest";
//  Real wMortAcc(start = 0.0) "Accumulated dead biomass by mortality";
//  Real wBiomass "Biomass produced during a year";
//  Integer mbiomass "Measured biomass for current year";
// equation
//  when sample(0,1) then
//    t = 1 + pre(t);
//    mbiomass = mbiomasses[t];
//    c = growthCycles[t];
//     w = pre(w) + wGrowth + -wMort + -wHarvest;
//    wBiomass = wGrowth - wMort;
//    wGrowth = e[c] * a[c] * Real(r[t]);
//    wMort = if c == 1 AND t > 1 then (1.0 - h) * m[t] * (pre(w) + wGrowth) else m[t] * (pre(w) + wGrowth);
//    wHarvest = if c == 1 AND t > 1 then h * pre(w) + pre(wMortAcc) else 0.0;
//    wMortAcc = if c == 1 then wMort else pre(wMortAcc) + wMort;
//  end when;
// end WillowForest;
