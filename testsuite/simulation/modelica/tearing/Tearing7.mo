model Tearing7
  Modelica.Electrical.Analog.Basic.Ground G;
  Modelica.Electrical.Analog.Basic.Resistor R1;
  Modelica.Electrical.Analog.Basic.Resistor R2;
  Modelica.Electrical.Analog.Basic.Resistor R3;
  Modelica.Electrical.Analog.Basic.Resistor R4;
  Modelica.Electrical.Analog.Basic.Resistor R5;
  Modelica.Electrical.Analog.Basic.Resistor R6;
  Modelica.Electrical.Analog.Basic.Resistor R7;
  Modelica.Electrical.Analog.Basic.Resistor R8;
  Modelica.Electrical.Analog.Sources.SineVoltage S;
equation
  connect(R1.n,R3.p);
  connect(R1.n,R4.p);
  connect(R1.p,R2.p);
  connect(R2.n,R3.n);
  connect(R2.n,R5.p);
  connect(R4.n,R6.p);
  connect(R4.n,R7.p);
  connect(R5.n,R6.n);
  connect(R5.n,R8.p);
  connect(R7.n,R8.n);
  connect(R7.n,G.p);
  connect(S.p,R1.p);
  connect(S.n,R7.n);
end Tearing7;
