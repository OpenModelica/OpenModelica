within ;
model ElectricalCircuit1
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-20,-32},{0,-12}})));
  Modelica.Electrical.Analog.Basic.Resistor R(R=1)
    annotation (Placement(transformation(extent={{-56,-22},{-36,-2}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent constantCurrent(I=1)
    annotation (Placement(transformation(extent={{12,-22},{32,-2}})));
  Modelica.Electrical.Analog.Basic.Resistor R1(R=1)
    annotation (Placement(transformation(extent={{-64,28},{-44,48}})));
  Modelica.Electrical.Analog.Basic.Resistor R2(R=1)
    annotation (Placement(transformation(extent={{-36,28},{-16,48}})));
  Modelica.Electrical.Analog.Basic.Capacitor C1(C=1)
    annotation (Placement(transformation(extent={{-50,4},{-30,24}})));
  Modelica.Electrical.Analog.Basic.Resistor R3(R=1)
    annotation (Placement(transformation(extent={{4,28},{24,48}})));
  Modelica.Electrical.Analog.Basic.Resistor R4(R=1)
    annotation (Placement(transformation(extent={{32,28},{52,48}})));
  Modelica.Electrical.Analog.Basic.Capacitor C2(C=1)
    annotation (Placement(transformation(extent={{16,4},{36,24}})));
  Modelica.Electrical.Analog.Basic.Resistor R6(R=1)
    annotation (Placement(transformation(extent={{6,68},{26,88}})));
  Modelica.Electrical.Analog.Basic.Capacitor C3(C=1)
    annotation (Placement(transformation(extent={{-14,42},{2,58}})));
  Modelica.Electrical.Analog.Basic.Resistor R5(R=1)
    annotation (Placement(transformation(extent={{-38,68},{-18,88}})));
equation
  connect(R.n, constantCurrent.p) annotation (Line(
      points={{-36,-12},{12,-12}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, constantCurrent.p) annotation (Line(
      points={{-10,-12},{12,-12}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R.p, R1.p) annotation (Line(
      points={{-56,-12},{-64,-12},{-64,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C1.n, R2.n) annotation (Line(
      points={{-30,14},{-16,14},{-16,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C1.p, R1.p) annotation (Line(
      points={{-50,14},{-64,14},{-64,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R3.n, R4.p) annotation (Line(
      points={{24,38},{32,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C2.n, R4.n) annotation (Line(
      points={{36,14},{52,14},{52,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C2.p, R3.p) annotation (Line(
      points={{16,14},{4,14},{4,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R2.n, R3.p) annotation (Line(
      points={{-16,38},{4,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R4.n, constantCurrent.n) annotation (Line(
      points={{52,38},{52,-12},{32,-12}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R2.p, R1.n) annotation (Line(
      points={{-36,38},{-44,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C3.n, R6.n) annotation (Line(
      points={{2,50},{32,50},{32,78},{26,78}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R4.n, R6.n) annotation (Line(
      points={{52,38},{52,78},{26,78}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R6.p, R5.n) annotation (Line(
      points={{6,78},{-18,78}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C3.p, R5.p) annotation (Line(
      points={{-14,50},{-38,50},{-38,78}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R1.p, R5.p) annotation (Line(
      points={{-64,38},{-64,78},{-38,78}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R.n, ground.p) annotation (Line(
      points={{-36,-12},{-10,-12}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end ElectricalCircuit1;
