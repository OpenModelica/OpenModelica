model Tearing6
  Modelica.Electrical.Analog.Basic.Ground G;
  Modelica.Electrical.Analog.Basic.Resistor R1;
  Modelica.Electrical.Analog.Basic.Resistor R2;
  Modelica.Electrical.Analog.Basic.Resistor R3;
  Modelica.Electrical.Analog.Basic.Resistor R4;
  Modelica.Electrical.Analog.Basic.Resistor R5;
  Modelica.Electrical.Analog.Sources.SineVoltage S;
equation
  connect(R1.n,R3.p);
  connect(R1.n,R4.p);
  connect(R1.p,R2.p);
  connect(R2.n,R3.n);
  connect(R2.n,R5.p);
  connect(R4.n,R5.n);
  connect(R4.n,G.p);
  connect(S.p,R1.p);
  connect(S.n,R4.n);
end Tearing6;
