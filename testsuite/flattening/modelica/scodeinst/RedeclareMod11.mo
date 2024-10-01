// name: RedeclareMod11
// keywords:
// status: correct
//

partial package PartialMedium
  type MassFraction = Real;
end PartialMedium;

package StandardWater
  extends PartialMedium;
end StandardWater;

connector FluidPort
  replaceable package Medium = PartialMedium;
  flow Real Q;
  Medium.MassFraction P;
end FluidPort;

connector Outlet
  extends FluidPort(redeclare package Medium = StandardWater);
end Outlet;

model FluidSource
  replaceable FluidPort p;
end FluidSource;

model RedeclareMod11
  extends FluidSource(redeclare Outlet p);
end RedeclareMod11;

// Result:
// class RedeclareMod11
//   Real p.Q;
//   Real p.P;
// equation
//   p.Q = 0.0;
// end RedeclareMod11;
// endResult
