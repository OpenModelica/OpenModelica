// name:     DisturbedResistance2
// keywords: modification
// status:   incorrect
//
// A parameter may not be redeclared as variable.
//

model Resistor
  Real u, i;
  parameter Real R = 1.0;
equation
  u = R*i;
end Resistor;

model DisturbedResistance2
  extends Resistor(redeclare Real R = 1.0 + 0.1*sin(time));
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end DisturbedResistance2;
