// name:     BranchingDynamicPipes.mo
// keywords: chained redeclares
// status:   correct
//

connector FluidPort
  replaceable package Medium = PartialMedium;

  Real[Medium.nXi] Xi_outflow;
  flow Real[Medium.nXi] f;
end FluidPort;

model PartialSource
  replaceable package Medium = PartialMedium;
  Medium.BaseProperties medium;
  FluidPort port(redeclare package Medium = Medium);
equation
  port.Xi_outflow = medium.Xi;
end PartialSource;

partial package PartialMedium
  constant String names[:] = {"medium"};
  final constant Integer nS = size(names, 1);
  constant Integer nXi = nS - 1;

  model BaseProperties
    Real[nXi] Xi;
  end BaseProperties;
end PartialMedium;

package MoistAir
  extends PartialMedium(names = {"water", "air"});
end MoistAir;

model BranchingDynamicPipes
  replaceable package Medium = MoistAir;
  PartialSource source(redeclare package Medium = Medium);
end BranchingDynamicPipes;

// Result:
// class BranchingDynamicPipes
//   Real source.medium.Xi[1];
//   Real source.port.Xi_outflow[1];
//   Real source.port.f[1];
// equation
//   source.port.Xi_outflow[1] = source.medium.Xi[1];
//   source.port.f[1] = 0.0;
// end BranchingDynamicPipes;
// endResult
