within ;
model ElectricalCircuit4
  Modelica.Electrical.Analog.Sources.ConstantCurrent constantcurrent1(I = -40) annotation(Placement(visible = true, transformation(origin={-51.9702,
            -15.7854},                                                                                                  extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Ground ground1 annotation(Placement(visible = true, transformation(origin={48.9508,
            -27.9285},                                                                                                    extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor C1(C=4.0)         annotation(Placement(visible = true, transformation(origin={-81.912,
            63.1363},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor C2(C=4.0)         annotation(Placement(visible = true, transformation(origin={-53.244,
            69.1363},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor C3(C=4.0)         annotation(Placement(visible = true, transformation(origin={-32.464,
            61.8447},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor C4(C=4.0)         annotation(Placement(visible = true, transformation(origin={1.248,
            62.0808},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor C5(C=4.0)         annotation(Placement(visible = true, transformation(origin={35.916,
            62.1197},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor C6(C=4.0)         annotation(Placement(visible = true, transformation(origin={63.285,
            62.0502},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R1(R=0.0004)         annotation(Placement(visible = true, transformation(origin={-80.334,
            50.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Resistor R2(R=0.0004)         annotation(Placement(visible = true, transformation(origin={-80.334,
            34.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R3(R=0.0004)         annotation(Placement(visible = true, transformation(origin={-66.334,
            82.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R4(R=0.0004)         annotation(Placement(visible = true, transformation(origin={-34.334,
            82.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R5(R=0.0004)         annotation(Placement(visible = true, transformation(origin={-32.334,
            50.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R6(R=0.0004)         annotation(Placement(visible = true, transformation(origin={-32.334,
            34.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R7(R=0.0004)         annotation(Placement(visible = true, transformation(origin={1.666,
            50.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R8(R=0.0004)         annotation(Placement(visible = true, transformation(origin={1.666,
            34.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R9(R=0.0004)         annotation(Placement(visible = true, transformation(origin={17.666,
            82.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R10(R=0.0004)        annotation(Placement(visible = true, transformation(origin={51.666,
            82.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R11(R=0.0004)        annotation(Placement(visible = true, transformation(origin={61.666,
            48.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor R12(R=0.0004)        annotation(Placement(visible = true, transformation(origin={63.666,
            30.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
equation
  connect(constantcurrent1.n,ground1.p) annotation(Line(points={{-39.9702,
          -15.7854},{35.0501,-15.7854},{35.0501,-15.9285},{48.9508,-15.9285}}));
  connect(C6.p, C5.n)            annotation(Line(points={{55.0888,62.0502},{
          44.1122,62.0502},{44.1122,62.1197}}));
  connect(C5.p, C4.n)            annotation(Line(points={{27.7198,62.1197},{
          21.377,62.1197},{21.377,62.0808},{9.44416,62.0808}}));
  connect(C3.n, C4.p)            annotation(Line(points={{-24.2678,61.8447},{
          16.375,61.8447},{16.375,62.0808},{-6.94816,62.0808}}));
  connect(C2.n, C3.p)            annotation(Line(points={{-45.0478,69.1363},{
          -44,69.1363},{-44,70},{-42,70},{-42,61.8447},{-40.6602,61.8447}}));
  connect(C1.n, C2.p)            annotation(Line(points={{-73.7158,63.1363},{
          -73.7158,69.1363},{-61.4402,69.1363}}));
  connect(R1.n, R2.p)               annotation (Line(
      points={{-72.1378,50.069},{-68,50.069},{-68,42},{-92,42},{-92,34},{-90,34},
          {-90,34.069},{-88.5302,34.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R3.n, R4.p)               annotation (Line(
      points={{-58.1378,82.069},{-58.1378,82},{-64.138,82},{-64.138,82.069},{
          -42.5302,82.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R5.n, R6.p)               annotation (Line(
      points={{-24.1378,50.069},{-24.1378,44},{-44,44},{-44,34.069},{-40.5302,
          34.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R7.n, R8.p)               annotation (Line(
      points={{9.86216,50.069},{9.86216,44},{-10,44},{-10,34.069},{-6.53016,
          34.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R9.n, R10.p)              annotation (Line(
      points={{25.8622,82.069},{25.8622,82},{44,82},{44,82.069},{43.4698,82.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R11.n, R12.p)             annotation (Line(
      points={{69.8622,48.069},{69.8622,38},{50,38},{50,30},{54,30},{54,30.069},
          {55.4698,30.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C1.p, R1.p)              annotation (Line(
      points={{-90.1082,63.1363},{-90.1082,64},{-90,64},{-90,50.069},{-88.5302,
          50.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R2.n, C1.n)              annotation (Line(
      points={{-72.1378,34.069},{-70,34.069},{-70,34},{-66,34},{-66,63.1363},{
          -73.7158,63.1363}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C2.p, R3.p)              annotation (Line(
      points={{-61.4402,69.1363},{-61.4402,71.5682},{-74.5302,71.5682},{
          -74.5302,82.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R4.n, C2.n)              annotation (Line(
      points={{-26.1378,82.069},{-26.1378,72.0345},{-45.0478,72.0345},{-45.0478,
          69.1363}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C3.p, R5.p)              annotation (Line(
      points={{-40.6602,61.8447},{-40.6602,62},{-42,62},{-42,52},{-40.5302,52},
          {-40.5302,50.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C3.n, R6.n)              annotation (Line(
      points={{-24.2678,61.8447},{-20,61.8447},{-20,62},{-16,62},{-16,34.069},{
          -24.1378,34.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C4.p, R7.p)              annotation (Line(
      points={{-6.94816,62.0808},{-6.94816,62},{-6,62},{-6,56},{-6.53016,56},{
          -6.53016,50.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C4.n, R8.n)              annotation (Line(
      points={{9.44416,62.0808},{12,62.0808},{12,62},{14,62},{14,34.069},{
          9.86216,34.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C5.p, R9.p)              annotation (Line(
      points={{27.7198,62.1197},{22,62.1197},{22,72},{8,72},{8,82.069},{9.46984,
          82.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C5.n, R10.n)             annotation (Line(
      points={{44.1122,62.1197},{48,62.1197},{48,62},{44,62},{44,74},{62,74},{
          62,82.069},{59.8622,82.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C6.p, R11.p)             annotation (Line(
      points={{55.0888,62.0502},{54,62.0502},{54,62},{52,62},{52,48.069},{
          53.4698,48.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C6.n, R12.n)             annotation (Line(
      points={{71.4812,62.0502},{72,62.0502},{72,62},{74,62},{74,30.069},{
          71.8622,30.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C6.n, ground1.p) annotation (Line(
      points={{71.4812,62.0502},{72,62.0502},{72,62},{94,62},{94,-16},{48.9508,
          -16},{48.9508,-15.9285}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(constantcurrent1.p, C1.p) annotation (Line(
      points={{-63.9702,-15.7854},{-63.9702,-16},{-96,-16},{-96,62},{-90.1082,
          62},{-90.1082,63.1363}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation(experiment(StartTime = 0.0, StopTime = 2000.0, Tolerance = 0.000001),
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
            100,100}}), graphics));
end ElectricalCircuit4;
