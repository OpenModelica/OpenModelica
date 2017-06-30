within ;
package FMIExercise
  model TestPIControl
    extends Modelica.Icons.Example;
    parameter Real k = 0.1 "Gain of PI controller";
    parameter Real Ti = 0.0145 "Time constant of PI controller";
    Components.DCPMMotor dCPMMotor annotation(
      Placement(transformation(extent = {{8, 10}, {28, 30}})));
    Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage annotation(
      Placement(transformation(extent = {{28, 38}, {8, 58}}, rotation = 0)));
    Modelica.Electrical.Analog.Basic.Ground ground annotation(
      Placement(transformation(origin = {-2, 48}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    Modelica.Mechanics.Rotational.Sensors.SpeedSensor speed annotation(
      Placement(transformation(extent = {{-10, -10}, {6, 6}}, rotation = -90, origin = {38, 10})));
    Modelica.Blocks.Continuous.PI PI(initType = Modelica.Blocks.Types.Init.InitialState, T = Ti, k = k) annotation(
      Placement(transformation(extent = {{-34, 52}, {-14, 72}})));
    Modelica.Blocks.Math.Feedback feedback annotation(
      Placement(transformation(extent = {{-62, 52}, {-42, 72}})));
    Modelica.Blocks.Sources.Step step(startTime = 0.1, height = 130) annotation(
      Placement(transformation(extent = {{-94, 52}, {-74, 72}})));
  equation
    connect(signalVoltage.n, ground.p) annotation(
      Line(points = {{8, 48}, {8, 48}}, color = {0, 0, 255}, smooth = Smooth.None));
    connect(dCPMMotor.pin_an, ground.p) annotation(
      Line(points = {{11.2, 31}, {2, 31}, {2, 48}, {8, 48}}, color = {0, 0, 255}));
    connect(dCPMMotor.pin_ap, signalVoltage.p) annotation(
      Line(points = {{23.2, 31}, {32, 31}, {32, 48}, {28, 48}}, color = {0, 0, 255}));
    connect(speed.flange, dCPMMotor.flange) annotation(
      Line(points = {{36, 20}, {36, 20}, {28, 20}}, color = {0, 0, 0}));
    connect(speed.w, feedback.u2) annotation(
      Line(points = {{36, 3.2}, {36, -2}, {-52, -2}, {-52, 54}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(feedback.y, PI.u) annotation(
      Line(points = {{-43, 62}, {-36, 62}}, color = {0, 0, 127}));
    connect(PI.y, signalVoltage.v) annotation(
      Line(points = {{-13, 62}, {-13, 62}, {18, 62}, {18, 55}}, color = {0, 0, 127}));
    connect(step.y, feedback.u1) annotation(
      Line(points = {{-73, 62}, {-60, 62}}, color = {0, 0, 127}));
    annotation(
      Icon(coordinateSystem(preserveAspectRatio = false)),
      Diagram(coordinateSystem(preserveAspectRatio = false)),
      Documentation(info = "In order to simulate the model:
First, export SimpleServoSystem.Components.PI as FMU,
second, import through FMI->Import FMU
third, drag and drop block and connect it"));
  end TestPIControl;


  model TestPIFMU
    extends Modelica.Icons.Example;
    parameter Real k = 0.1 "Gain of PI controller";
    parameter Real Ti = 0.0145 "Time constant of PI controller";
    Components.DCPMMotor dCPMMotor annotation(
      Placement(transformation(extent = {{8, 10}, {28, 30}})));
    Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage annotation(
      Placement(transformation(extent = {{28, 38}, {8, 58}}, rotation = 0)));
    Modelica.Electrical.Analog.Basic.Ground ground annotation(
      Placement(transformation(origin = {-2, 48}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    Modelica.Mechanics.Rotational.Sensors.SpeedSensor speed annotation(
      Placement(transformation(extent = {{-10, -10}, {6, 6}}, rotation = -90, origin = {38, 10})));
    Modelica.Blocks.Continuous.PI PI(initType = Modelica.Blocks.Types.Init.InitialState, T = Ti, k = k) annotation(
      Placement(transformation(extent = {{-34, 52}, {-14, 72}})));
    Modelica.Blocks.Math.Feedback feedback annotation(
      Placement(transformation(extent = {{-62, 52}, {-42, 72}})));
    Modelica.Blocks.Sources.Step step(startTime = 0.1, height = 130) annotation(
      Placement(transformation(extent = {{-94, 52}, {-74, 72}})));
  FMIExercise_Components_PI_me_FMU fMIExercise_Components_PI_me_FMU1(T = Ti, k = 0.1)  annotation(
      Placement(visible = true, transformation(origin = {-26, 22}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
    connect(fMIExercise_Components_PI_me_FMU1.u, feedback.y) annotation(
      Line(points = {{-38, 30}, {-42, 30}, {-42, 62}, {-42, 62}}, color = {0, 0, 127}));
    connect(PI.y, signalVoltage.v) annotation(
      Line(points = {{-12, 62}, {6, 62}, {6, 68}, {18, 68}, {18, 56}, {18, 56}}, color = {0, 0, 127}));
    connect(signalVoltage.n, ground.p) annotation(
      Line(points = {{8, 48}, {8, 48}}, color = {0, 0, 255}, smooth = Smooth.None));
    connect(dCPMMotor.pin_an, ground.p) annotation(
      Line(points = {{11.2, 31}, {2, 31}, {2, 48}, {8, 48}}, color = {0, 0, 255}));
    connect(dCPMMotor.pin_ap, signalVoltage.p) annotation(
      Line(points = {{23.2, 31}, {32, 31}, {32, 48}, {28, 48}}, color = {0, 0, 255}));
    connect(speed.flange, dCPMMotor.flange) annotation(
      Line(points = {{36, 20}, {36, 20}, {28, 20}}, color = {0, 0, 0}));
    connect(speed.w, feedback.u2) annotation(
      Line(points = {{36, 3.2}, {36, -2}, {-52, -2}, {-52, 54}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(feedback.y, PI.u) annotation(
      Line(points = {{-43, 62}, {-36, 62}}, color = {0, 0, 127}));
    connect(step.y, feedback.u1) annotation(
      Line(points = {{-73, 62}, {-60, 62}}, color = {0, 0, 127}));
    annotation(
      Icon(coordinateSystem(preserveAspectRatio = false)),
      Diagram(coordinateSystem(preserveAspectRatio = false)),
      Documentation(info = "In order to simulate the model:
First, export SimpleServoSystem.Components.PI as FMU,
second, import through FMI->Import FMU
third, drag and drop block and connect it"));
  end TestPIFMU;










  package Components
    model DCPMMotor
      import SI = Modelica.SIunits;
      parameter SI.Resistance ra = 7.38 "Armature resistance";
      parameter SI.Inductance la = 4.64e-3 "Armature inductance";
      parameter SI.Inertia Ja(min = 0) = 1.9e-6 "Armature moment of inertia";
      parameter SI.ElectricalTorqueConstant ka = 3.11e-2 "Transformation coefficient";
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange "Shaft" annotation(
        Placement(transformation(extent = {{90, -10}, {110, 10}}, rotation = 0), iconTransformation(extent = {{90, -10}, {110, 10}})));
      Modelica.Electrical.Analog.Interfaces.PositivePin pin_ap "Positive armature pin" annotation(
        Placement(transformation(extent = {{50, 110}, {70, 90}}, rotation = 0), iconTransformation(extent = {{42, 120}, {62, 100}})));
      Modelica.Electrical.Analog.Interfaces.NegativePin pin_an "Negative armature pin" annotation(
        Placement(transformation(extent = {{-70, 110}, {-50, 90}}, rotation = 0), iconTransformation(extent = {{-78, 120}, {-58, 100}})));
      Modelica.Electrical.Analog.Basic.EMF emf(useSupport = false, k = ka) annotation(
        Placement(transformation(extent = {{10, -10}, {30, 10}})));
      Modelica.Electrical.Analog.Basic.Resistor resistor(R = ra) annotation(
        Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 270, origin = {20, 64})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia(J = Ja, phi(fixed = true, start = 0), w(fixed = true, start = 0)) annotation(
        Placement(transformation(extent = {{54, -10}, {74, 10}}, rotation = 0)));
      Modelica.Electrical.Analog.Basic.Inductor inductor(L = la, i(fixed = true)) annotation(
        Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {20, 36})));
    equation
      connect(pin_ap, resistor.p) annotation(
        Line(points = {{60, 100}, {60, 74}, {20, 74}}, color = {0, 0, 255}, smooth = Smooth.None));
      connect(emf.n, pin_an) annotation(
        Line(points = {{20, -10}, {20, -20}, {-60, -20}, {-60, 100}}, color = {0, 0, 255}, smooth = Smooth.None));
      connect(emf.flange, inertia.flange_a) annotation(
        Line(points = {{30, 0}, {54, 0}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(inertia.flange_b, flange) annotation(
        Line(points = {{74, 0}, {100, 0}}, color = {0, 0, 0}, smooth = Smooth.None));
      connect(resistor.n, inductor.n) annotation(
        Line(points = {{20, 54}, {20, 46}}, color = {0, 0, 255}, smooth = Smooth.None));
      connect(inductor.p, emf.p) annotation(
        Line(points = {{20, 26}, {20, 10}}, color = {0, 0, 255}, smooth = Smooth.None));
      annotation(
        Icon(graphics = {Rectangle(extent = {{-40, 60}, {80, -60}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {0, 128, 255}), Rectangle(extent = {{-40, 60}, {-60, -60}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {128, 128, 128}), Rectangle(extent = {{80, 10}, {100, -10}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {95, 95, 95}), Rectangle(extent = {{-40, 70}, {40, 50}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Polygon(points = {{-50, -90}, {-40, -90}, {-10, -20}, {40, -20}, {70, -90}, {80, -90}, {80, -100}, {-50, -100}, {-50, -90}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-146, -100}, {154, -140}}, textString = "%name", lineColor = {0, 0, 255})}));
    end DCPMMotor;

    block PI "Proportional-Integral controller"
      extends Modelica.Blocks.Interfaces.SISO;
      import SI = Modelica.SIunits;
      parameter Real k(unit = "1") = 0.1 "Gain";
      parameter SI.Time T(start = 1, min = Modelica.Constants.small) = 0.0145 "Time Constant (T>0 required)";
      output Real x(start = 0, fixed = true) "State of block";
    equation
      der(x) = u / T;
      y = k * (x + u);
      annotation(
        defaultComponentName = "PI",
        Documentation(info = "<html>
<p>
This blocks defines the transfer function between the input u and
the output y (element-wise) as <i>PI</i> system:
</p>
<pre>
                 1
   y = k * (1 + ---) * u
                T*s
           T*s + 1
     = k * ------- * u
             T*s
</pre>
<p>
If you would like to be able to change easily between different
transfer functions (FirstOrder, SecondOrder, ... ) by changing
parameters, use the general model class <b>TransferFunction</b>
instead and model a PI SISO system with parameters<br>
b = {k*T, k}, a = {T, 0}.
</p>
<pre>
Example:

   parameter: k = 0.3,  T = 0.4

   results in:
               0.4 s + 1
      y = 0.3 ----------- * u
                 0.4 s
</pre>
</html>"),
        Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 78}, {-80, -90}}, color = {192, 192, 192}), Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-90, -80}, {82, -80}}, color = {192, 192, 192}), Polygon(points = {{90, -80}, {68, -72}, {68, -88}, {90, -80}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80.0, -80.0}, {-80.0, -20.0}, {60.0, 80.0}}, color = {0, 0, 127}), Text(extent = {{0, 6}, {60, -56}}, lineColor = {192, 192, 192}, textString = "PI"), Text(extent = {{-150, -150}, {150, -110}}, lineColor = {0, 0, 0}, textString = "T=%T")}),
        Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-60, 60}, {60, -60}}, lineColor = {0, 0, 255}), Text(extent = {{-68, 24}, {-24, -18}}, lineColor = {0, 0, 0}, textString = "k"), Text(extent = {{-32, 48}, {60, 0}}, lineColor = {0, 0, 0}, textString = "T s + 1"), Text(extent = {{-30, -8}, {52, -40}}, lineColor = {0, 0, 0}, textString = "T s"), Line(points = {{-24, 0}, {54, 0}}, color = {0, 0, 0}), Line(points = {{-100, 0}, {-60, 0}}, color = {0, 0, 255}), Line(points = {{62, 0}, {100, 0}}, color = {0, 0, 255})}));
    end PI;


  end Components;
  annotation(
    uses(Modelica(version = "3.2.2"), Modelica_Synchronous(version = "0.92.1")));
end FMIExercise;
