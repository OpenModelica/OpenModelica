// name: RedeclareMod12
// keywords:
// status: correct
//

package Types
  type AbsolutePressure = Real;
  type Temperature = Real;
end Types;

partial package PartialMedium
  extends Types;
end PartialMedium;

package Water
  extends PartialMedium;
end Water;

block LumpedVolumeDeclarations
  replaceable package Medium = PartialMedium;
  parameter Medium.AbsolutePressure p_start = 0;
  parameter Medium.Temperature T_start = 0;
end LumpedVolumeDeclarations;

model ComparePower
  package Medium = Water;
  replaceable LumpedVolumeDeclarations mov1;
end ComparePower;

model RedeclareMod12
  extends ComparePower(redeclare LumpedVolumeDeclarations mov1(redeclare final package Medium = Medium));
end RedeclareMod12;

// Result:
// class RedeclareMod12
//   parameter Real mov1.p_start = 0.0;
//   parameter Real mov1.T_start = 0.0;
// end RedeclareMod12;
// endResult
