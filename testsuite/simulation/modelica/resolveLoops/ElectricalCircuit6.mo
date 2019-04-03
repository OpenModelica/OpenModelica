within ;
model ElectricalCircuit6
  Modelica.Electrical.Analog.Basic.Ground ground1 annotation(Placement(visible = true, transformation(origin={22.9508,
            -101.929},                                                                                                    extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r(R=0.0004)    annotation(Placement(visible = true, transformation(origin={-71.106,
            10.2981},                                                                                                    extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor c1(C=4.0)         annotation(Placement(visible = true, transformation(origin={-45.9118,
            89.136},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor c2(C=4.0)         annotation(Placement(visible = true, transformation(origin={-19.2435,
            87.136},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor c3(C=4.0)         annotation(Placement(visible = true, transformation(origin={13.2847,
            88.05},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r1a(R=0.0004)        annotation(Placement(visible = true, transformation(origin={-50.334,
            70.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Resistor r1b(R=0.0004)        annotation(Placement(visible = true, transformation(origin={-52.334,
            54.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r2a(R=0.0004)        annotation(Placement(visible = true, transformation(origin={-20.334,
            72.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r2b(R=0.0004)        annotation(Placement(visible = true, transformation(origin={-16.334,
            56.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r3a(R=0.0004)        annotation(Placement(visible = true, transformation(origin={11.666,
            74.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r3b(R=0.0004)        annotation(Placement(visible = true, transformation(origin={13.666,
            56.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r7(R=0.0004)   annotation(Placement(visible = true, transformation(origin={36.894,
            10.2981},                                                                                                    extent = {{-12,-12},{12,12}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor c4(C=4.0)         annotation(Placement(visible = true, transformation(origin={62.0882,
            89.136},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor c5(C=4.0)         annotation(Placement(visible = true, transformation(origin={88.757,
            87.136},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Capacitor c6(C=4.0)         annotation(Placement(visible = true, transformation(origin={121.285,
            88.05},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r4a(R=0.0004)        annotation(Placement(visible = true, transformation(origin={57.666,
            70.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Resistor r4b(R=0.0004)        annotation(Placement(visible = true, transformation(origin={55.666,
            54.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r5a(R=0.0004)        annotation(Placement(visible = true, transformation(origin={87.666,
            72.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r5b(R=0.0004)        annotation(Placement(visible = true, transformation(origin={91.666,
            56.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r6a(R=0.0004)        annotation(Placement(visible = true, transformation(origin={119.666,
            74.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor r6b(R=0.0004)        annotation(Placement(visible = true, transformation(origin={121.666,
            56.069},                                                                                                    extent = {{-8.19616,-8.19616},{8.19616,8.19616}}, rotation = 0)));
  Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage
    annotation (Placement(transformation(extent={{-40,-36},{-20,-16}})));
equation
  connect(c1.n, c2.p)            annotation(Line(points={{-37.7156,89.136},{
          -37.7156,87.136},{-27.4397,87.136}}));
  connect(r1a.n, r1b.p)             annotation (Line(
      points={{-42.1378,70.069},{-38,70.069},{-38,62},{-62,62},{-62,54},{-60,54},
          {-60,54.069},{-60.5302,54.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r2a.n, r2b.p)             annotation (Line(
      points={{-12.1378,72.069},{-12.1378,66},{-30.1378,66},{-30.1378,56.069},{
          -24.5302,56.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r3a.n, r3b.p)             annotation (Line(
      points={{19.8622,74.069},{19.8622,64},{0,64},{0,56},{4,56},{4,56.069},{
          5.46984,56.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c1.p, r1a.p)             annotation (Line(
      points={{-54.108,89.136},{-54.108,84},{-62,84},{-62,70.069},{-58.5302,
          70.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r1b.n, c1.n)             annotation (Line(
      points={{-44.1378,54.069},{-40,54.069},{-40,54},{-36,54},{-36,89.136},{
          -37.7156,89.136}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c2.p, r2a.p)             annotation (Line(
      points={{-27.4397,87.136},{-27.4397,83.568},{-28.5302,83.568},{-28.5302,
          72.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r2b.n, c2.n)             annotation (Line(
      points={{-8.13784,56.069},{-8.13784,84.034},{-11.0473,84.034},{-11.0473,
          87.136}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c3.p, r3a.p)             annotation (Line(
      points={{5.08854,88.05},{4,88.05},{4,88},{2,88},{2,74.069},{3.46984,
          74.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c3.n, r3b.n)             annotation (Line(
      points={{21.4809,88.05},{22,88.05},{22,88},{24,88},{24,56.069},{21.8622,
          56.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c3.p, c2.n)             annotation (Line(
      points={{5.08854,88.05},{4,88.05},{4,88},{-4,88},{-4,87.136},{-11.0473,
          87.136}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r.n, c1.p)        annotation (Line(
      points={{-59.106,10.2981},{-59.106,24},{-60,24},{-60,38},{-76,38},{-76,88},
          {-54.108,88},{-54.108,89.136}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c4.n, c5.p)            annotation(Line(points={{70.2844,89.136},{
          70.2844,87.136},{80.5608,87.136}}));
  connect(r4a.n, r4b.p)             annotation (Line(
      points={{65.8622,70.069},{70,70.069},{70,62},{46,62},{46,54},{48,54},{48,
          54.069},{47.4698,54.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r5a.n, r5b.p)             annotation (Line(
      points={{95.8622,72.069},{95.8622,66},{77.8622,66},{77.8622,56.069},{
          83.4698,56.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r6a.n, r6b.p)             annotation (Line(
      points={{127.862,74.069},{127.862,64},{108,64},{108,56},{112,56},{112,
          56.069},{113.47,56.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c4.p, r4a.p)             annotation (Line(
      points={{53.892,89.136},{53.892,84},{46,84},{46,70.069},{49.4698,70.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r4b.n, c4.n)             annotation (Line(
      points={{63.8622,54.069},{68,54.069},{68,54},{72,54},{72,89.136},{70.2844,
          89.136}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c5.p, r5a.p)             annotation (Line(
      points={{80.5608,87.136},{80.5608,83.568},{79.4698,83.568},{79.4698,
          72.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r5b.n, c5.n)             annotation (Line(
      points={{99.8622,56.069},{99.8622,84.034},{96.9532,84.034},{96.9532,
          87.136}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c6.p, r6a.p)             annotation (Line(
      points={{113.089,88.05},{112,88.05},{112,88},{110,88},{110,74.069},{
          111.47,74.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c6.n, r6b.n)             annotation (Line(
      points={{129.481,88.05},{130,88.05},{130,88},{132,88},{132,56.069},{
          129.862,56.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(c6.p, c5.n)             annotation (Line(
      points={{113.089,88.05},{112,88.05},{112,88},{104,88},{104,87.136},{
          96.9532,87.136}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r7.n, c4.p)        annotation (Line(
      points={{48.894,10.2981},{48.894,24},{48,24},{48,38},{32,38},{32,88},{
          53.892,88},{53.892,89.136}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(r7.p, r3b.n)        annotation (Line(
      points={{24.894,10.2981},{24.894,88},{24,88},{24,56.069},{21.8622,56.069}},
      color={0,0,255},
      smooth=Smooth.None));

  connect(sineVoltage.n, r6b.n) annotation (Line(
      points={{-20,-26},{56,-26},{56,56.069},{129.862,56.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground1.p, r6b.n) annotation (Line(
      points={{22.9508,-89.929},{22.9508,-26},{56,-26},{56,56.069},{129.862,
          56.069}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(sineVoltage.p, r.p) annotation (Line(
      points={{-40,-26},{-62,-26},{-62,10.2981},{-83.106,10.2981}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end ElectricalCircuit6;
