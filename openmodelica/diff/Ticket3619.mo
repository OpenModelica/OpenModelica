within ;
encapsulated package withFolder "Package per EV con modello QuasiStationary"
  import Modelica;
  import EVQSPkg = withFolder;
  import AsmaPkgQSpap;

  encapsulated model EVbasic
    "Simulates an Electric Vehcile based on BASMADrive electric drive model"
    import Modelica;
    import withFolder;
    parameter Modelica.SIunits.Mass vMass = 16000 "Vehicle mass";
    Modelica.Mechanics.Rotational.Components.IdealRollingWheel wheel(radius = 0.5715) annotation(Placement(transformation(extent = {{-8, 0}, {12, 20}})));
    Modelica.Mechanics.Translational.Sensors.SpeedSensor velSens annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {78, -20})));
    Modelica.Mechanics.Translational.Components.Mass mass(m = vMass) annotation(Placement(transformation(extent = {{46, 0}, {66, 20}})));
    Modelica.Mechanics.Translational.Sensors.PowerSensor mP1 annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {28, 10})));
    Modelica.Mechanics.Translational.Sensors.PowerSensor mP2 annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = -90, origin = {104, 0})));
    withFolder.VhDragForce dragF(m = vMass, Cx = 0.65, rho = 1.226, S = 6.0, fc = 0.013) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {104, -40})));
    withFolder.PropDriver driver(k = 1000, CycleFileName = "Sort1.txt", yMax = 100000.0) annotation(Placement(transformation(extent = {{-110, 0}, {-90, 20}})));
    Modelica.Mechanics.Rotational.Sources.Torque torque annotation(Placement(transformation(extent = {{-70, 0}, {-50, 20}})));
    Modelica.Mechanics.Rotational.Components.IdealGear myGear(ratio = 6) annotation(Placement(visible = true, transformation(origin = {-30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  equation
    connect(torque.flange, myGear.flange_a) annotation(Line(points = {{-50, 10}, {-39.1919, 10}, {-39.1919, 10}, {-40, 10}}));
    connect(myGear.flange_b, wheel.flangeR) annotation(Line(points = {{-20, 10}, {-8.48485, 10}, {-8.48485, 10}, {-8, 10}}));
    connect(mP1.flange_a, wheel.flangeT) annotation(Line(points = {{18, 10}, {12, 10}}, color = {0, 127, 0}, smooth = Smooth.None));
    connect(mP2.flange_a, mass.flange_b) annotation(Line(points = {{104, 10}, {66, 10}}, color = {0, 127, 0}, smooth = Smooth.None));
    connect(mass.flange_a, mP1.flange_b) annotation(Line(points = {{46, 10}, {38, 10}}, color = {0, 127, 0}, smooth = Smooth.None));
    connect(velSens.flange, mP2.flange_a) annotation(Line(points = {{78, -10}, {78, 10}, {104, 10}}, color = {0, 127, 0}, smooth = Smooth.None));
    connect(dragF.flange, mP2.flange_b) annotation(Line(points = {{104, -30}, {104, -10}}, color = {0, 127, 0}, smooth = Smooth.None));
    connect(driver.V, velSens.v) annotation(Line(points = {{-100, -1.2}, {-100, -46}, {78, -46}, {78, -31}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(torque.tau, driver.Tref) annotation(Line(points = {{-72, 10}, {-89, 10}}, color = {0, 0, 127}, smooth = Smooth.None));
    annotation(experiment(StopTime = 200, Interval = 0.1), experimentSetupOutput(derivatives = false), Documentation(info = "<html>
             <p>Modello Semplice di veicolo elettrico usato per l&apos;esercitazione di SEB a.a. 2011-12.</p>
             <p><h4>Nota operativa</h4></p>
             <p>Questa versione &egrave; inserita nella libreria EVQSPkg, che &egrave; autocontenuta</p>
              <p>OM 23136 OK </p>
             </html>"), Commands, Diagram(coordinateSystem(extent = {{-120, -60}, {120, 60}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-120, -60}, {120, 60}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})));
  end EVbasic;

  model PropDriver "Simple Proportional controller driver"
    parameter String CycleFileName = "MyCycleName.txt"
      "Drive Cycle Name ex: \"sort1.txt\"";
    parameter Real k "Controller gain";
    parameter Real yMax = 1000000.0 "Max output value (absolute)";
    Modelica.Blocks.Interfaces.RealInput V annotation(Placement(transformation(extent = {{-14, -14}, {14, 14}}, rotation = 90, origin = {0, -114}), iconTransformation(extent = {{-12, -12}, {12, 12}}, rotation = 90, origin = {0, -112})));
    Modelica.Blocks.Interfaces.RealOutput Tref(unit = "N.m") annotation(Placement(transformation(extent = {{100, -10}, {120, 10}}), iconTransformation(extent = {{100, -10}, {120, 10}})));
    Modelica.Blocks.Sources.CombiTimeTable driveCyc(tableOnFile = true, tableName = "Cycle", extrapolation = Modelica.Blocks.Types.Extrapolation.Periodic, fileName = CycleFileName, columns = {2}) annotation(Placement(transformation(extent = {{-86, -10}, {-66, 10}})));
    Modelica.Blocks.Math.UnitConversions.From_kmh from_kmh annotation(Placement(transformation(extent = {{-48, -10}, {-28, 10}})));
    Modelica.Blocks.Math.Feedback feedback annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
    Modelica.Blocks.Math.Gain gain(k = k) annotation(Placement(transformation(extent = {{32, -10}, {52, 10}})));
    Modelica.Blocks.Nonlinear.Limiter limiter(uMax = yMax) annotation(Placement(transformation(extent = {{70, -10}, {90, 10}})));
  equation
    connect(from_kmh.u, driveCyc.y[1]) annotation(Line(points = {{-50, 0}, {-65, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(from_kmh.y, feedback.u1) annotation(Line(points = {{-27, 0}, {-8, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(feedback.u2, V) annotation(Line(points = {{0, -8}, {0, -114}, {1.77636e-015, -114}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(feedback.y, gain.u) annotation(Line(points = {{9, 0}, {30, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(gain.y, limiter.u) annotation(Line(points = {{53, 0}, {68, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(Tref, limiter.y) annotation(Line(points = {{110, 0}, {91, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics), Documentation(info = "<html>
            <p>Modello semplice di pilota.</p>
            <p>Esso contiene al suo interno il ciclo di riferimento, che insegue attraverso un regolatore solo proporzionale.</p>
            </html>"), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2}), graphics={  Rectangle(fillColor = {255, 255, 255},
              fillPattern =                                                                                                    FillPattern.Solid, extent = {{-100, 100}, {100, -100}}), Ellipse(fillColor = {255, 213, 170},
              fillPattern =                                                                                                    FillPattern.Solid, extent = {{-23, 46}, {-12, 20}}, endAngle = 360), Text(origin = {0, 1.81063}, lineColor = {0, 0, 255}, extent = {{-104, 142.189}, {98, 104}}, textString = "%name"), Polygon(fillColor = {215, 215, 215}, pattern = LinePattern.None,
              fillPattern =                                                                                                    FillPattern.Solid, points = {{-22, -36}, {-42, -64}, {-16, -64}, {16, -64}, {-22, -36}}), Polygon(fillColor = {135, 135, 135}, pattern = LinePattern.None,
              fillPattern =                                                                                                    FillPattern.Solid, points = {{-32, 64}, {-62, -28}, {-30, -28}, {-30, -28}, {-32, 64}}, smooth = Smooth.Bezier), Polygon(fillColor = {135, 135, 135}, pattern = LinePattern.None,
              fillPattern =                                                                                                    FillPattern.Solid, points = {{-68, -12}, {-14, -66}, {10, -26}, {0, -26}, {-68, -12}}, smooth = Smooth.Bezier), Polygon(fillColor = {175, 175, 175},
              fillPattern =                                                                                                    FillPattern.Solid, points = {{-22, 34}, {-30, 30}, {-40, -24}, {2, -22}, {2, -10}, {0, 26}, {-22, 34}}, smooth = Smooth.Bezier), Ellipse(fillColor = {255, 213, 170},
              fillPattern =                                                                                                    FillPattern.Solid, extent = {{-30, 68}, {-3, 34}}, endAngle = 360), Polygon(pattern = LinePattern.None,
              fillPattern =                                                                                                    FillPattern.Solid, points = {{-38, 58}, {-16, 74}, {-2, 60}, {4, 60}, {6, 60}, {-38, 58}}, smooth = Smooth.Bezier), Polygon(fillColor = {95, 95, 95},
              fillPattern =                                                                                                    FillPattern.Solid, points = {{30, -20}, {-32, -4}, {-36, -20}, {-24, -34}, {30, -20}}, smooth = Smooth.Bezier), Polygon(
              fillPattern =                                                                                                    FillPattern.Solid, points = {{42, -46}, {36, -60}, {48, -54}, {52, -48}, {50, -44}, {42, -46}}, smooth = Smooth.Bezier), Line(points = {{48, 10}, {26, 24}, {26, 24}}, thickness = 0.5), Line(points = {{20, 14}, {34, 34}, {34, 34}}, thickness = 0.5), Polygon(fillColor = {255, 213, 170},
              fillPattern =                                                                                                    FillPattern.Solid, points = {{28, 28}, {32, 32}, {28, 26}, {34, 30}, {30, 26}, {34, 28}, {30, 24}, {26, 26}, {34, 24}, {26, 24}, {26, 26}, {28, 28}, {28, 28}, {26, 26}, {26, 26}, {26, 26}, {28, 32}, {28, 30}, {28, 28}}, smooth = Smooth.Bezier), Polygon(fillColor = {175, 175, 175},
              fillPattern =                                                                                                    FillPattern.Solid, points = {{-18, 24}, {28, 30}, {26, 22}, {-16, 8}, {-20, 8}, {-24, 18}, {-18, 24}}, smooth = Smooth.Bezier), Polygon(fillColor = {215, 215, 215},
              fillPattern =                                                                                                    FillPattern.Solid, points = {{72, 18}, {48, 18}, {36, -2}, {58, -62}, {72, -62}, {72, 18}}), Polygon(fillColor = {95, 95, 95},
              fillPattern =                                                                                                    FillPattern.Solid, points = {{49, -70}, {17, -16}, {7, -20}, {-1, -26}, {49, -70}}, smooth = Smooth.Bezier), Line(points = {{-7, 55}, {-3, 53}}), Line(points = {{-9, 42}, {-5, 42}}), Line(points = {{-7, 55}, {-3, 55}})}));
  end PropDriver;

  model VhDragForce "Vehicle rolling and aerodinamical drag force"
    import Modelica.Constants.g_n;
    extends
      Modelica.Mechanics.Translational.Interfaces.PartialElementaryOneFlangeAndSupport2;
    extends Modelica.Mechanics.Translational.Interfaces.PartialFriction;
    Modelica.SIunits.Force f "Total drag force";
    Modelica.SIunits.Velocity v "vehicle velocity";
    Modelica.SIunits.Acceleration a "Absolute acceleration of flange";
    Real Sign;
    parameter Modelica.SIunits.Mass m "vehicle mass";
    parameter Modelica.SIunits.Density rho(start = 1.226) "air density";
    parameter Modelica.SIunits.Area S "vehicle cross area";
    parameter Real fc(start = 0.01) "rolling friction coefficient";
    parameter Real Cx "aerodinamic drag coefficient";
  protected
    parameter Real A = fc * m * g_n;
    parameter Real B = 1 / 2 * rho * S * Cx;
    // Constant auxiliary variable
  equation
    //  s = flange.s;
    v = der(s);
    a = der(v);
    // Le seguenti definizioni seguono l'ordine e le ridchieste del modello "PartialFriction" di
    // Modelica.Mechanics.Translational.Interfaces"
    v_relfric = v;
    a_relfric = a;
    f0 = A "forza a velocita'  0 ma con scorrimento";
    f0_max = A "massima forza velocita'  0 e senza scorrimento ";
    free = false "sarebbe true quando la ruota si stacca dalla strada";
    // Ora il calcolo di f, e la sua attribuzione alla flangia:
    flange.f - f = 0;
    // friction force
    if v > 0 then
      Sign = 1;
    else
      Sign = -1;
    end if;
    f - B * v ^ 2 * Sign = if locked then sa * unitForce else f0 * (if startForward then Modelica.Math.tempInterpol1(v, [0, 1], 2) else if startBackward then -Modelica.Math.tempInterpol1(-v, [0, 1], 2) else if pre(mode) == Forward then Modelica.Math.tempInterpol1(v, [0, 1], 2) else -Modelica.Math.tempInterpol1(-v, [0, 1], 2));
    annotation(Documentation(info = "<html>
            <p>This component modesl the total (rolling &egrave;+ aerrodynamic vehicle drag resistance: </p>
            <p>f=mgh+(1/2)*rho*Cx*S*v^2</p>
            <p>It models reliably the stuck phase. based on Modelica-Intrerfaces.PartialFriction model</p>
            </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics={  Polygon(points = {{-98, 10}, {22, 10}, {22, 41}, {92, 0}, {22, -41}, {22, -10}, {-98, -10}, {-98, 10}}, lineColor = {0, 127, 0}, fillColor = {215, 215, 215},
              fillPattern =                                                                                                    FillPattern.Solid), Line(points = {{-42, -50}, {87, -50}}, color = {0, 0, 0}), Polygon(points = {{-72, -50}, {-41, -40}, {-41, -60}, {-72, -50}}, lineColor = {0, 0, 0}, fillColor = {128, 128, 128},
              fillPattern =                                                                                                    FillPattern.Solid), Line(points = {{-90, -90}, {-70, -88}, {-50, -82}, {-30, -72}, {-10, -58}, {10, -40}, {30, -18}, {50, 8}, {70, 38}, {90, 72}, {110, 110}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-82, 90}, {80, 50}}, lineColor = {0, 0, 255}, textString = "%name")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics));
  end VhDragForce;

  package OLD
    model QSDrive
      import PI = Modelica.Constants.pi;
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation(Placement(transformation(extent = {{90, -10}, {110, 10}}), iconTransformation(extent = {{90, -10}, {110, 10}})));
      parameter Integer pp = 2 "pole pairs";
      parameter Real UBase = 230 "Base RMS machine line voltage";
      parameter Real WeBase = 314.15 "Base machine angular frequency";
      parameter Real WeMax = 314.15 "Base machine angular frequency";
      parameter Real Unom = 200
        "DC nominal voltage (only order of magnitude needed)";
      parameter Real R1 = 0.435 "stator's phase resistance" annotation(Dialog(tab = "machine parameters"));
      parameter Real L1 = 0.004 "stator's leakage indctance" annotation(Dialog(tab = "machine parameters"));
      parameter Real Lm = 0.0693 "stator's leakage indctance" annotation(Dialog(tab = "machine parameters"));
      parameter Real R2 = 0.4 "rotor's phase resistance" annotation(Dialog(tab = "machine parameters"));
      parameter Real L2 = 0.002 "rotor's leakage indctance" annotation(Dialog(tab = "machine parameters"));
      parameter Real J = 2.0 "rotor's moment of inertia" annotation(Dialog(tab = "machine parameters"));
    protected
      parameter Real UBase1 = UBase / sqrt(3);
      //base phase voltage
    public
      Modelica.Electrical.Analog.Interfaces.PositivePin pin_p annotation(Placement(transformation(extent = {{-110, 50}, {-90, 70}}), iconTransformation(extent = {{-112, 50}, {-92, 70}})));
      Modelica.Electrical.Analog.Interfaces.NegativePin pin_n annotation(Placement(transformation(extent = {{-110, -70}, {-90, -50}}), iconTransformation(extent = {{-112, -70}, {-92, -50}})));
      DCLConstP DCLoad(T = 0.01, k = 1000 / Unom) annotation(Placement(transformation(extent = {{-100, -10}, {-80, 10}})));
      QSAsma qSAsma annotation(Placement(transformation(extent = {{-4, 38}, {20, 58}})));
      Modelica.Blocks.Sources.RealExpression ComputedU(y = F.y + (UBase1 - F.y) * limWe.y / WeBase) annotation(Placement(transformation(extent = {{-84, 52}, {-40, 68}})));
      Modelica.Blocks.Math.Gain U0(k = R1) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {14, -6})));
      Modelica.Blocks.Interfaces.RealInput dWe annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = 270, origin = {0, 120})));
      Modelica.Mechanics.Rotational.Sensors.SpeedSensor Wm annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {54, 22})));
      Modelica.Blocks.Math.Add add annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {50, -64})));
      Modelica.Blocks.Math.Gain PolePairs(k = pp) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {54, -10})));
      Modelica.Blocks.Math.Gain ToFreq(k = 1 / (2 * PI)) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 180, origin = {-20, -80})));
      Modelica.Blocks.Nonlinear.Limiter limU(uMax = UBase1) annotation(Placement(transformation(extent = {{-36, 50}, {-16, 70}})));
      Modelica.Blocks.Nonlinear.Limiter limWe(uMax = WeMax) annotation(Placement(transformation(extent = {{26, -90}, {6, -70}})));
      Modelica.Blocks.Continuous.FirstOrder F(T = 0.05) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {14, -36})));
      Modelica.Blocks.Nonlinear.Limiter limDWe(uMax = R2 / (L1 + L2), uMin = -R2 / (L1 + L2)) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {40, 70})));
      Modelica.Blocks.Math.Gain LossF_(k = LossFact) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 180, origin = {-22, 16})));
      Modelica.Blocks.Math.Add addPdc annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 180, origin = {-62, 0})));
      parameter Real LossFact = 4 "Inverter loss Factor: W/A" annotation(Dialog(tab = "Other"));
    algorithm
      assert(ComputedU.y < 0.5 * DCLoad.v, "DC voltage too low for current machine operating point");
    equation
      connect(DCLoad.pin_p, pin_p) annotation(Line(points = {{-91, 9.199999999999999}, {-91, 60}, {-100, 60}}, color = {0, 0, 255}, smooth = Smooth.None));
      connect(DCLoad.pin_n, pin_n) annotation(Line(points = {{-91, -9}, {-91, -60}, {-100, -60}}, color = {0, 0, 255}, smooth = Smooth.None));
      connect(qSAsma.Iac, U0.u) annotation(Line(points = {{14, 37}, {14, 6}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(Wm.flange, qSAsma.flange_a) annotation(Line(points = {{54, 32}, {54, 48}, {17.8, 48}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(PolePairs.u, Wm.w) annotation(Line(points = {{54, 2}, {54, 11}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(PolePairs.y, add.u1) annotation(Line(points = {{54, -21}, {56, -21}, {56, -52}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(ToFreq.y, qSAsma.f) annotation(Line(points = {{-31, -80}, {-40, -80}, {-40, 42}, {-4, 42}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limU.u, ComputedU.y) annotation(Line(points = {{-38, 60}, {-37.8, 60}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limU.y, qSAsma.U) annotation(Line(points = {{-15, 60}, {-12, 60}, {-12, 54}, {-4, 54}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limWe.y, ToFreq.u) annotation(Line(points = {{5, -80}, {-8, -80}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limWe.u, add.y) annotation(Line(points = {{28, -80}, {50, -80}, {50, -75}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(F.u, U0.y) annotation(Line(points = {{14, -24}, {14, -17}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limDWe.y, add.u2) annotation(Line(points = {{40, 59}, {40, -52}, {44, -52}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limDWe.u, dWe) annotation(Line(points = {{40, 82}, {40, 92}, {0, 92}, {0, 120}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(flange_a, qSAsma.flange_a) annotation(Line(points = {{100, 0}, {80, 0}, {80, 48}, {17.8, 48}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(addPdc.y, DCLoad.Pref) annotation(Line(points = {{-73, 1.34711e-015}, {-75.5, 1.34711e-015}, {-75.5, 0}, {-81.8, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(qSAsma.Pdc, addPdc.u2) annotation(Line(points = {{1, 37}, {1, 32}, {-50, 32}, {-50, 6}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(LossF_.u, qSAsma.Iac) annotation(Line(points = {{-10, 16}, {14, 16}, {14, 37}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(LossF_.y, addPdc.u1) annotation(Line(points = {{-33, 16}, {-32, 16}, {-32, -6}, {-50, -6}}, color = {0, 0, 127}, smooth = Smooth.None));
      annotation(Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points=  {{-28, 20}, {6, 20}}, color=  {0, 0, 255}, smooth=  Smooth.None), Line(points=  {{-30, 0}, {4, 0}}, color=  {0, 0, 255}, smooth=  Smooth.None), Line(points=  {{-30, -20}, {4, -20}}, color=  {0, 0, 255}, smooth=  Smooth.None), Text(extent=  {{-140, -112}, {148, -138}}, lineColor=  {0, 0, 127}, fillColor=  {95, 95, 95}, fillPattern=  FillPattern.Solid, textString=  "%name"), Line(points=  {{-102, -60}, {-78, -60}, {-78, -28}, {-60, -28}}, color=  {0, 0, 255}, smooth=  Smooth.None), Line(points=  {{-96, 60}, {-78, 60}, {-78, 28}, {-60, 28}}, color=  {0, 0, 255}, smooth=  Smooth.None), Rectangle(extent=  {{-40, 68}, {80, -52}}, lineColor=  {0, 0, 0}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {175, 175, 175}), Rectangle(extent=  {{-40, 68}, {-62, -52}}, lineColor=  {0, 0, 255}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {0, 0, 255}), Polygon(points=  {{-54, -82}, {-44, -82}, {-14, -12}, {36, -12}, {66, -82}, {76, -82}, {76, -92}, {-54, -92}, {-54, -82}}, lineColor=  {0, 0, 0}, fillColor=  {0, 0, 0}, fillPattern=  FillPattern.Solid), Rectangle(extent=  {{80, 12}, {100, -8}}, lineColor=  {0, 0, 0}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {95, 95, 95})}), Documentation(info = "<html>
            <p>This model models an asynchrnous machine - based electric drive, containing U/f control, with stator resistance drop compensation.</p>
            <p>It makes usage of the quasi-stationary asynchornous machine model QSAsma.</p>
            </html>"), experiment(StopTime = 2), __Dymola_experimentSetupOutput);
    end QSDrive;

    model QSDrivePU
      import PI = Modelica.Constants.pi;
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation(Placement(transformation(extent = {{90, -10}, {110, 10}}), iconTransformation(extent = {{90, -10}, {110, 10}})));
      // General parameters
      parameter Real UBase = 400 "Base RMS machine line voltage";
      parameter Real WeBase = 314.15 "Base machine angular frequency";
      parameter Real WeMax = 2 * WeBase "Base machine angular frequency";
      parameter Real UdcNom = 500
        "DC nominal voltage (only order of magnitude needs to be true)";
      // P.U. reference quantities
      parameter Real Unom = 400 "PU reference RMS machine line voltage" annotation(Dialog(group = "p.u. reference quantities"));
      parameter Modelica.SIunits.ApparentPower Snom = 100000.0
        "P.U. reference power"                                                        annotation(Dialog(group = "p.u. reference quantities"));
      parameter Modelica.SIunits.Frequency FNom = 50
        "Reference frequency of p.u."                                              annotation(Dialog(group = "p.u. reference quantities"));
      // Machine parameters
      parameter Real R1u = 0.01 "Stator phase resistance " annotation(Dialog(tab = "Machine", group = "Resistances and inductances per phase"));
      parameter Real X1u = 0.05 "Stator leackage inductance" annotation(Dialog(tab = "Machine", group = "Resistances and inductances per phase"));
      parameter Real R2u = 0.01 "Rotor phase resistance related to primary" annotation(Dialog(tab = "Machine", group = "Resistances and inductances per phase"));
      parameter Real X2u = 0.05 "Rotor leackage inductance" annotation(Dialog(tab = "Machine", group = "Resistances and inductances per phase"));
      parameter Real Xmu = 10 "Magnetic coupling inductance" annotation(Dialog(tab = "Machine", group = "Resistances and inductances per phase"));
      //  parameter Real Rmu=10 "Iron loss equivalent resistance (Zm=Rm//Xm)" annotation(Dialog(tab="Machine",group="Resistances and inductances per phase"));
      parameter Modelica.SIunits.Time Hu = 5 "Inertia constant (s)" annotation(Dialog(tab = "Machine", group = "Other parameters"));
      parameter Integer pp(min = 1) = 1 "number of pole pairs" annotation(Dialog(tab = "Machine", group = "Other parameters"));
      // Other/Inverter
      parameter Modelica.SIunits.Time TInv = 0.01 "Inverter time constant" annotation(Dialog(tab = "Other", group = "Inverter"));
      parameter Real LossFact
        "ratio of inverter losses (W) to machine current (A)";
      // Other/Load
      parameter Real KL = 1 "Inner DCload PI k constant (adimens.)" annotation(Dialog(tab = "Other", group = "DCLoad"));
      parameter Modelica.SIunits.Time TL = 0.001
        "Inner DCload PI time constant"                                          annotation(Dialog(tab = "Other", group = "DCLoad"));
      Real tLim "maximum available torque at given frequency";
    protected
      parameter Real UBase1 = UBase / sqrt(3);
      //single-circuit equivalent of UBase
      parameter Real WeNom = 2 * PI * FNom;
      parameter Real WmNom = WeNom / pp;
      parameter Real Znom = Unom ^ 2 / Snom;
      parameter Modelica.SIunits.Resistance R1 = R1u * Znom;
      parameter Modelica.SIunits.Inductance L1 = X1u * Znom / WeNom;
      parameter Modelica.SIunits.Inductance Lm = Xmu * Znom / WeNom;
      parameter Modelica.SIunits.Resistance R2 = R2u * Znom;
      parameter Modelica.SIunits.Inductance L2 = X2u * Znom / WeNom;
      //  parameter Modelica.SIunits.Resistance Rm=Rmu*Z_nom;
      parameter Modelica.SIunits.MomentOfInertia J = 2 * Hu * Snom / WmNom ^ 2;
      Real WeAux;
    public
      Modelica.Blocks.Math.Add addPdc annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 180, origin = {-58, 30})));
      Modelica.Blocks.Math.Gain LossF_(k = LossFact) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 180, origin = {-18, 20})));
    algorithm
      WeAux := abs(limWe.y);
      if WeAux < 0.1 then
        WeAux := 0.1;
      end if;
      //limite: 0.1 rad/s
      if limWe.y < WeBase then
        tLim := 3 * UBase ^ 2 * pp / (2 * WeBase ^ 2 * (L1 + L2));
      else
        tLim := 3 * limU.y ^ 2 * pp / (2 * WeAux ^ 2 * (L1 + L2));
      end if;
    public
      Modelica.Electrical.Analog.Interfaces.PositivePin pin_p annotation(Placement(transformation(extent = {{-110, 50}, {-90, 70}}), iconTransformation(extent = {{-112, 50}, {-92, 70}})));
      Modelica.Electrical.Analog.Interfaces.NegativePin pin_n annotation(Placement(transformation(extent = {{-110, -70}, {-90, -50}}), iconTransformation(extent = {{-112, -70}, {-92, -50}})));
      DCLConstP DCLoad(k = KL, T = TL) annotation(Placement(transformation(extent = {{-100, -10}, {-80, 10}})));
      QSAsma qSAsma(pp = pp, R1 = R1, L1 = L1, Lm = Lm, R2 = R2, L2 = L2, J = J) annotation(Placement(transformation(extent = {{-2, 44}, {22, 64}})));
      Modelica.Blocks.Sources.RealExpression ComputedU(y = F.y + (UBase1 - F.y) * limWe.y / WeBase) annotation(Placement(transformation(extent = {{-76, 52}, {-52, 68}})));
      Modelica.Blocks.Math.Gain U0(k = R1 / 2) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {16, 2})));
      Modelica.Blocks.Interfaces.RealInput dWe annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = 270, origin = {0, 120})));
      Modelica.Mechanics.Rotational.Sensors.SpeedSensor Wm annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {56, 22})));
      Modelica.Blocks.Math.Add add annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {50, -44})));
      Modelica.Blocks.Math.Gain PolePairs(k = pp) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {56, -10})));
      Modelica.Blocks.Math.Gain ToFreq(k = 1 / (2 * PI)) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 180, origin = {-20, -70})));
      Modelica.Blocks.Nonlinear.Limiter limU(uMax = UBase1) annotation(Placement(transformation(extent = {{-40, 50}, {-20, 70}})));
      Modelica.Blocks.Nonlinear.Limiter limWe(uMax = WeMax) annotation(Placement(transformation(extent = {{26, -80}, {6, -60}})));
      Modelica.Blocks.Continuous.FirstOrder F(T = TInv) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {16, -26})));
      Modelica.Blocks.Nonlinear.Limiter limDWe(uMax = R2 / (L1 + L2), uMin = -R2 / (L1 + L2)) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {40, 70})));
      /*Il seguente assert può essere omesso in quanto la tensione applicata alla macchina è automaticamente limitata

                                                                                                                                                                                                                                                                                                                                                            algorithm 
                                                                                                                                                                                                                                                                                                                                                            assert(ComputedU.y< 0.5*DCLoad.v, "DC voltage: "+ String(DCLoad.v) + "V\n" +
                                                                                                                                                                                                                                                                                                                                                                    "is too low for current machine operating point. Uac:"+String(ComputedU.y) + "Vrms.\n\n");
                                                                                                                                                                                                                                                                                                                                                            */
    equation
      connect(DCLoad.pin_p, pin_p) annotation(Line(points = {{-91, 9.199999999999999}, {-91, 60}, {-100, 60}}, color = {0, 0, 255}, smooth = Smooth.None));
      connect(DCLoad.pin_n, pin_n) annotation(Line(points = {{-91, -9}, {-91, -60}, {-100, -60}}, color = {0, 0, 255}, smooth = Smooth.None));
      connect(qSAsma.Iac, U0.u) annotation(Line(points = {{16, 43}, {16, 28.5}, {16, 14}, {16, 14}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(qSAsma.flange_a, flange_a) annotation(Line(points = {{19.8, 54}, {80, 54}, {80, 0}, {100, 0}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(Wm.flange, qSAsma.flange_a) annotation(Line(points = {{56, 32}, {56, 54}, {19.8, 54}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(PolePairs.u, Wm.w) annotation(Line(points = {{56, 2}, {56, 4}, {58, 4}, {58, 6}, {56, 6}, {56, 11}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(PolePairs.y, add.u1) annotation(Line(points = {{56, -21}, {56, -32}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(ToFreq.y, qSAsma.f) annotation(Line(points = {{-31, -70}, {-40, -70}, {-40, 48}, {-2, 48}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limU.u, ComputedU.y) annotation(Line(points = {{-42, 60}, {-50.8, 60}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limU.y, qSAsma.U) annotation(Line(points = {{-19, 60}, {-2, 60}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limWe.y, ToFreq.u) annotation(Line(points = {{5, -70}, {2, -70}, {2, -72}, {-2, -72}, {-2, -70}, {-8, -70}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limWe.u, add.y) annotation(Line(points = {{28, -70}, {50, -70}, {50, -55}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(F.u, U0.y) annotation(Line(points = {{16, -14}, {16, -8}, {18, -8}, {18, -6}, {16, -6}, {16, -9}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limDWe.y, add.u2) annotation(Line(points = {{40, 59}, {40, -32}, {44, -32}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limDWe.u, dWe) annotation(Line(points = {{40, 82}, {40, 92}, {0, 92}, {0, 120}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(addPdc.y, DCLoad.Pref) annotation(Line(points = {{-69, 30}, {-74.5, 30}, {-74.5, 0}, {-81.8, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(addPdc.u2, qSAsma.Pdc) annotation(Line(points = {{-46, 36}, {3, 36}, {3, 43}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(LossF_.y, addPdc.u1) annotation(Line(points = {{-29, 20}, {-38, 20}, {-38, 24}, {-46, 24}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(LossF_.u, qSAsma.Iac) annotation(Line(points = {{-6, 20}, {16, 20}, {16, 43}}, color = {0, 0, 127}, smooth = Smooth.None));
      annotation(Dialog(tab = "Other", group = "Inverter"), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points=  {{-28, 20}, {6, 20}}, color=  {0, 0, 255}, smooth=  Smooth.None), Line(points=  {{-30, 0}, {4, 0}}, color=  {0, 0, 255}, smooth=  Smooth.None), Line(points=  {{-30, -20}, {4, -20}}, color=  {0, 0, 255}, smooth=  Smooth.None), Text(extent=  {{-140, -112}, {148, -138}}, lineColor=  {0, 0, 127}, fillColor=  {95, 95, 95}, fillPattern=  FillPattern.Solid, textString=  "%name"), Line(points=  {{-102, -60}, {-78, -60}, {-78, -28}, {-60, -28}}, color=  {0, 0, 255}, smooth=  Smooth.None), Line(points=  {{-96, 60}, {-78, 60}, {-78, 28}, {-60, 28}}, color=  {0, 0, 255}, smooth=  Smooth.None), Rectangle(extent=  {{-40, 68}, {80, -52}}, lineColor=  {0, 0, 0}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {175, 175, 175}), Rectangle(extent=  {{-40, 68}, {-62, -52}}, lineColor=  {0, 0, 255}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {0, 0, 255}), Polygon(points=  {{-54, -82}, {-44, -82}, {-14, -12}, {36, -12}, {66, -82}, {76, -82}, {76, -92}, {-54, -92}, {-54, -82}}, lineColor=  {0, 0, 0}, fillColor=  {0, 0, 0}, fillPattern=  FillPattern.Solid), Rectangle(extent=  {{80, 10}, {100, -10}}, lineColor=  {0, 0, 0}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {95, 95, 95}), Text(extent=  {{-34, 18}, {74, -4}}, lineColor=  {0, 0, 255}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {0, 0, 255}, textString=  "P.U.")}), Documentation(info = "<html>
            <p>This model models an asynchrnous machine - based electric drive, containing U/f control, with stator resistance drop compensation.</p>
            <p>It makes usage of the quasi-stationary asynchornous machine model QSAsma.</p>
            </html>"));
    end QSDrivePU;

    model QSAsma
      import PI = Modelica.Constants.pi;
      Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Inductor L1_(L = L1) annotation(Placement(transformation(extent = {{-8, 8}, {12, 28}})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Resistor R1_(R_ref = R1) annotation(Placement(transformation(extent = {{-32, 8}, {-12, 28}})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Inductor L2_(L = L2) annotation(Placement(transformation(extent = {{26, 8}, {46, 28}})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Inductor Lm_(L = Lm) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {18, -2})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Basic.VariableResistor Rmecc annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {90, -2})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Sources.VariableVoltageSource
                                                                                    uTerminals annotation(Placement(transformation(extent = {{-10, 10}, {10, -10}}, rotation = 270, origin = {-72, -2})));
      Modelica.ComplexBlocks.ComplexMath.PolarToComplex ToComplexUin annotation(Placement(transformation(origin = {-70, 84}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Interfaces.RealInput U annotation(Placement(transformation(extent = {{-160, 40}, {-120, 80}}), iconTransformation(extent = {{-140, 40}, {-100, 80}})));
      Modelica.Blocks.Sources.Constant const(k = 0) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 180, origin = {-70, 58})));
      Modelica.Blocks.Interfaces.RealInput f annotation(Placement(transformation(extent = {{-160, -80}, {-120, -40}}), iconTransformation(extent = {{-140, -80}, {-100, -40}})));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation(Placement(transformation(extent = {{108, 68}, {128, 88}}), iconTransformation(extent = {{88, -10}, {108, 10}})));
      Modelica.Mechanics.Rotational.Sources.Torque torque annotation(Placement(transformation(extent = {{14, 68}, {34, 88}})));
      Modelica.Mechanics.Rotational.Sensors.SpeedSensor Wm annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {72, 60})));
      Modelica.Blocks.Nonlinear.Limiter limF(uMin = 1e-006, uMax = 1000000.0) annotation(Placement(transformation(extent = {{-112, -70}, {-92, -50}})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.PowerSensor Pag annotation(Placement(transformation(extent = {{54, 8}, {74, 28}})));
      Modelica.Blocks.Sources.RealExpression WmS1(y = 3 * toPag.re / W0) annotation(Placement(transformation(extent = {{-36, 68}, {-4, 88}})));
      parameter Integer pp = 2 "pole pairs";
      parameter Real R1 = 0.435 "stator's phase resistance";
      parameter Real L1 = 0.004 "stator's leakage indctance";
      parameter Real Lm = 0.0693 "stator's leakage indctance";
      parameter Real R2 = 0.4 "rotor's phase resistance";
      parameter Real L2 = 0.002 "rotor's leakage indctance";
      parameter Real J = 2.0 "rotor's moment of inertia";
      Real W0;
      //velocità meccanica di soncronismo
      Real s;
      //scorrimento
      Modelica.Mechanics.Rotational.Components.Inertia inertia(J = J) annotation(Placement(transformation(extent = {{82, 68}, {102, 88}})));
      Modelica.ComplexBlocks.ComplexMath.ComplexToReal toPag annotation(Placement(transformation(extent = {{-6, -6}, {6, 6}}, rotation = 270, origin = {46, -8})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Basic.Ground ground annotation(Placement(transformation(extent = {{8, -38}, {28, -18}})));
      Modelica.ComplexBlocks.ComplexMath.ComplexToReal toPin annotation(Placement(transformation(extent = {{-6, -6}, {6, 6}}, rotation = 270, origin = {-54, -10})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.PowerSensor Pin annotation(Placement(transformation(extent = {{-56, 8}, {-36, 28}})));
      Modelica.Blocks.Interfaces.RealOutput Pdc annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {-60, -110}), iconTransformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {-70, -110})));
      Modelica.Electrical.QuasiStationary.SinglePhase.Sensors.CurrentSensor currentSensor annotation(Placement(transformation(extent = {{-10, 10}, {10, -10}}, rotation = 180, origin = {-6, -22})));
      Modelica.ComplexBlocks.ComplexMath.ComplexToPolar ToIPolar annotation(Placement(transformation(extent = {{-6, -6}, {6, 6}}, rotation = 270, origin = {56, -76})));
      Modelica.Blocks.Interfaces.RealOutput Iac annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {60, -110})));
      Modelica.Mechanics.Rotational.Sensors.PowerSensor PmGen annotation(Placement(transformation(extent = {{46, 68}, {66, 88}})));
      Modelica.Blocks.Math.Gain toW1(k = 3) annotation(Placement(transformation(extent = {{-8, -8}, {8, 8}}, rotation = -90, origin = {-50, -80})));
    equation
      W0 = limF.y * 2 * PI / pp;
      s = (W0 - Wm.w) / W0;
      Rmecc.R_ref = R2 / s;
      connect(R1_.pin_n, L1_.pin_p) annotation(Line(points = {{-12, 18}, {-8, 18}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(L1_.pin_n, L2_.pin_p) annotation(Line(points = {{12, 18}, {26, 18}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Lm_.pin_p, L1_.pin_n) annotation(Line(points = {{18, 8}, {18, 18}, {12, 18}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Rmecc.pin_n, Lm_.pin_n) annotation(Line(points = {{90, -12}, {90, -22}, {18, -22}, {18, -12}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(ToComplexUin.y, uTerminals.V) annotation(Line(points = {{-59, 84}, {-40, 84}, {-40, 40}, {-100, 40}, {-100, 2}, {-82, 2}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(ToComplexUin.len, U) annotation(Line(points = {{-82, 90}, {-100, 90}, {-100, 60}, {-140, 60}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(const.y, ToComplexUin.phi) annotation(Line(points = {{-81, 58}, {-92, 58}, {-92, 78}, {-82, 78}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(limF.u, f) annotation(Line(points = {{-114, -60}, {-140, -60}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(uTerminals.f, limF.y) annotation(Line(points = {{-82, -6}, {-88, -6}, {-88, -60}, {-91, -60}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(Pag.currentP, L2_.pin_n) annotation(Line(points = {{54, 18}, {46, 18}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Pag.voltageP, Pag.currentP) annotation(Line(points = {{64, 28}, {54, 28}, {54, 18}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Pag.voltageN, Rmecc.pin_n) annotation(Line(points = {{64, 8}, {64, -22}, {90, -22}, {90, -12}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(WmS1.y, torque.tau) annotation(Line(points = {{-2.4, 78}, {12, 78}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(inertia.flange_b, flange_a) annotation(Line(points = {{102, 78}, {118, 78}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(Pag.y, toPag.u) annotation(Line(points = {{56, 7}, {46, 7}, {46, -0.8}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Pag.currentN, Rmecc.pin_p) annotation(Line(points = {{74, 18}, {90, 18}, {90, 8}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(ground.pin, Lm_.pin_n) annotation(Line(points = {{18, -18}, {18, -15}, {18, -12}, {18, -12}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Pin.currentN, R1_.pin_p) annotation(Line(points = {{-36, 18}, {-32, 18}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Pin.currentP, uTerminals.pin_p) annotation(Line(points = {{-56, 18}, {-72, 18}, {-72, 8}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Pin.voltageP, Pin.currentP) annotation(Line(points = {{-46, 28}, {-56, 28}, {-56, 18}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Pin.y, toPin.u) annotation(Line(points = {{-54, 7}, {-54, -2.8}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(Pin.voltageN, uTerminals.pin_n) annotation(Line(points = {{-46, 8}, {-46, 0}, {-26, 0}, {-26, -22}, {-72, -22}, {-72, -12}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(uTerminals.pin_n, currentSensor.pin_n) annotation(Line(points = {{-72, -12}, {-72, -22}, {-16, -22}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(currentSensor.pin_p, Rmecc.pin_n) annotation(Line(points = {{4, -22}, {90, -22}, {90, -12}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(ToIPolar.u, currentSensor.y) annotation(Line(points = {{56, -68.8}, {56, -50}, {-6, -50}, {-6, -33}}, color = {85, 170, 255}, smooth = Smooth.None));
      connect(ToIPolar.len, Iac) annotation(Line(points = {{59.6, -83.2}, {60, -83.2}, {60, -110}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(PmGen.flange_a, torque.flange) annotation(Line(points = {{46, 78}, {34, 78}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(PmGen.flange_b, inertia.flange_a) annotation(Line(points = {{66, 78}, {82, 78}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(Wm.flange, PmGen.flange_b) annotation(Line(points = {{72, 70}, {72, 78}, {66, 78}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(toW1.u, toPin.re) annotation(Line(points = {{-50, -70.40000000000001}, {-50, -17.2}, {-50.4, -17.2}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(Pdc, toW1.y) annotation(Line(points = {{-60, -110}, {-60, -88.8}, {-50, -88.8}}, color = {0, 0, 127}, smooth = Smooth.None));
      annotation(Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-120, -100}, {120, 100}}), graphics = {Rectangle(extent=  {{-80, 34}, {100, -36}}, lineColor=  {255, 0, 0}, pattern=  LinePattern.Dash)}), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-120, -100}, {120, 100}}), graphics = {Line(points=  {{-100, 60}, {-48, 32}}, color=  {0, 0, 127}, smooth=  Smooth.None), Line(points=  {{-100, -60}, {-48, -30}}, color=  {0, 0, 127}, smooth=  Smooth.None), Text(extent=  {{-106, 138}, {106, 112}}, lineColor=  {0, 0, 127}, fillColor=  {95, 95, 95}, fillPattern=  FillPattern.Solid, textString=  "%name"), Rectangle(extent=  {{-42, 66}, {78, -54}}, lineColor=  {0, 0, 0}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {175, 175, 175}), Rectangle(extent=  {{78, 10}, {98, -10}}, lineColor=  {0, 0, 0}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {95, 95, 95}), Rectangle(extent=  {{-42, 66}, {-62, -54}}, lineColor=  {0, 0, 0}, fillPattern=  FillPattern.HorizontalCylinder, fillColor=  {128, 128, 128}), Polygon(points=  {{-54, -84}, {-44, -84}, {-14, -14}, {36, -14}, {66, -84}, {76, -84}, {76, -94}, {-54, -94}, {-54, -84}}, lineColor=  {0, 0, 0}, fillColor=  {0, 0, 0}, fillPattern=  FillPattern.Solid)}), Documentation(info = "<html>
            <p>This model models ans asynchronous machine based on a quasi-stationary approximation: the equivalent single-phase circuit.</p>
            <p>This model is very fast and compact, and gives result with sufficient precision in most vehicular propulsion needs.</p>
            </html>"));
    end QSAsma;
  end OLD;

  annotation(uses(Modelica(version = "3.2.1")));
end withFolder;
