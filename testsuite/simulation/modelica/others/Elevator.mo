within ;

package Elevator "Test for ticket #3656 provided by Christian Kral"
  model Elevator
    extends Modelica.Icons.Example;
    parameter Integer nPas = 2 "Number of passengers";
    parameter Modelica.SIunits.Mass mPas = 80 "Mass of one passenger";
    parameter Modelica.SIunits.Mass mCab = 250 "Mass of cabin";
    parameter Modelica.SIunits.Mass mCou = 410 "Mass of counterweight";
    parameter Modelica.SIunits.Length DP = 0.8 "Diameter of drive pulley";
    parameter Modelica.SIunits.Inertia JP = 15 "Inertia of drive pulley";
    parameter Real EtaP = 0.96 "Efficiency of drive pulley";
    parameter Real iG = 55 "Ratio of gearbox";
    parameter Real EtaG = 0.80 "Efficiency of gearbox";
    parameter Modelica.SIunits.Inertia JMG = 0.03 "Inertia of gearbox + motor";
    parameter Modelica.SIunits.Velocity vMax = 2 "Max. speed of cabin";
    final parameter Modelica.SIunits.Length R2T=(DP/2)/iG
      "Transmission rotational -> translational";
    parameter Modelica.SIunits.Length s0 = 0 "Initial position of cabin";
    parameter Modelica.SIunits.Velocity v0 = 0 "Initial velocity of cabin";
    Modelica.Blocks.Sources.Trapezoid trapezoid(
      rising=2.5,
      width=5,
      falling=2.5,
      period=10,
      nperiod=1,
      offset=0,
      startTime=0.5,
      amplitude=vMax/R2T)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-60,50})));
    Modelica.Mechanics.Rotational.Sources.Speed speed(exact = true) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation=0,   origin={-30,50})));
    Modelica.Mechanics.Rotational.Components.IdealGear gearBox(ratio=iG,
        useSupport=false)
      annotation (Placement(transformation(extent={{-10,40},{10,60}})));
    IdealDrivePulley drivePulley(useTranslationalSupport=false, radius=DP/2)
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={30,50})));
    MassGravitation cabin(
      s(start=s0),
      v(start=v0),
      m=mCab + nPas*mPas)
      annotation (Placement(transformation(extent={{10,0},{30,20}})));
    MassGravitation counterweight(m=mCou)
      annotation (Placement(transformation(extent={{30,0},{50,20}})));
  equation
    connect(drivePulley.flange_a, cabin.flange) annotation(Line(points={{20,40},
            {20,20}},                                                                         color = {0, 127, 0}));
    connect(drivePulley.flange_b, counterweight.flange) annotation(Line(points={{40,40},
            {40,20}},                                                                                               color = {0, 127, 0}));
    connect(speed.flange, gearBox.flange_a)
      annotation (Line(points={{-20,50},{-14,50},{-10,50}}, color={0,0,0}));
    connect(gearBox.flange_b, drivePulley.flange)
      annotation (Line(points={{10,50},{15,50},{20,50}}, color={0,0,0}));
    connect(trapezoid.y, speed.w_ref)
      annotation (Line(points={{-49,50},{-42,50}}, color={0,0,127}));
    annotation(Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})), experiment(StopTime=12, Interval=0.01),
      Documentation(info="<html>
<p>
This example of an elevator demonstrates the usage of a <a href=\"modelica://ModelicaAdditions/Mechanics/Rotational/Components/GearConstantEfficiency\">gearbox with constant efficiency</a> and
a <a href=\"modelica:/ModelicaAdditions/Mechanics.Rotational/Components/DrivePulleyConstantEfficiency\">drive pulley with constant efficiency</a>.
</p>
<p>
The flange_a of the gearbox is driven by a prescribed speed, flange_b of the gearbox drives the rotational flange of the drive pulley.
At the two ends of a rope through translational flanges flange_a and flange_b of the drive pulley the cabin (with passengers) and a counterweight are hanging.
</p>
<p>
Speed rises linearly between 0 and 2.5 seconds from to 2 m/s, then remains constant for 4.5 seconds and during the following 2.5 seconds speed is reduced linearly to 0.
This results in lifting the cabin by 14 m and in turn lowering the counterweight by 14 m.
</p>
</html>"),
      __Dymola_experimentSetupOutput);
  end Elevator;

  model IdealDrivePulley "1-dim. model of ideal drive pulley"
    import Modelica.Constants.eps;
    parameter Modelica.SIunits.Distance radius(final min = eps) "Wheel radius";
    parameter Boolean useTranslationalSupport = false
      "= true, if Translational support flange enabled, otherwise implicitly grounded"
      annotation(Evaluate = true, HideResult = true, choices(checkBox = true));
    Modelica.SIunits.Torque tau "Torque at rotational flange";
    Modelica.SIunits.Force f_a "Force at translational flange a";
    Modelica.SIunits.Force f_b "Force at translational flange b";
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange "Flange of shaft" annotation(Placement(transformation(extent = {{-10, -110}, {10, -90}}, rotation = 0)));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a annotation(Placement(transformation(extent = {{90, -110}, {110, -90}}), iconTransformation(extent = {{90, -110}, {110, -90}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_b flange_b annotation(Placement(transformation(extent = {{90, 110}, {110, 90}}), iconTransformation(extent = {{90, 90}, {110, 110}})));
    Modelica.Mechanics.Translational.Interfaces.Support translationalSupport(s = s_support, f = -(f_a + f_b)) if useTranslationalSupport
      "Translational support  of component"                                                                                                     annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
  protected
    Modelica.SIunits.Angle phi "Angle of rotational flange";
    Modelica.SIunits.Position s_a
      "Relative position of translational flange a w.r.t. support";
    Modelica.SIunits.Position s_b
      "Relative position of translational flange b w.r.t. support";
    Modelica.SIunits.Position s_support
      "Absolute position of translational support flange";
  equation
    if not useTranslationalSupport then
      s_support = 0;
    end if;
    phi = flange.phi;
    tau = flange.tau;
    s_a = flange_a.s - s_support;
    s_b = flange_b.s - s_support;
    f_a = flange_a.f;
    f_b = flange_b.f;
    s_a + s_b = 0;
    phi * radius = s_a;
    tau + (f_a - f_b) * radius = 0;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics={
      Rectangle(extent={{-100,-12},{-10,-16}}, lineColor={0,0,0}, fillColor={95,95,95},
              fillPattern =                                                                          FillPattern.Solid),
      Polygon(points = {{57, -85}, {37, -85}, {-57, 85}, {-37, 85}, {57, -85}}, lineColor = {95, 95, 95}, fillColor = {175, 175, 175},
              fillPattern =                                                                                                   FillPattern.Forward, origin={5,
                53},                                                                                                    rotation = 90),
      Rectangle(lineColor = {64, 64, 64}, fillColor = {192, 192, 192},
              fillPattern =                                                          FillPattern.HorizontalCylinder, extent = {{-27, -10}, {27, 10}}, origin = {0, -72}, rotation = 90),
      Ellipse(lineColor = {64, 64, 64}, fillColor = {255, 255, 255},
              fillPattern =                                                        FillPattern.HorizontalCylinder, extent = {{-30, -80}, {30, 80}}, origin = {0, -18}, rotation = 90),
      Rectangle(lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, pattern = LinePattern.None,
              fillPattern =                                                                                       FillPattern.HorizontalCylinder, extent = {{-16, -80}, {16, 80}}, origin = {0, -4}, rotation = 90),
      Ellipse(lineColor = {64, 64, 64}, fillColor = {128, 128, 128},
              fillPattern =                                                        FillPattern.Solid, extent = {{-30, -80}, {30, 80}}, origin = {0, 14}, rotation = 90),
      Ellipse(lineColor = {64, 64, 64}, fillColor = {192, 192, 192},
              fillPattern =                                                        FillPattern.HorizontalCylinder, extent = {{-4, -10}, {4, 10}}, origin = {0, 14}, rotation = 90),
      Text(lineColor={0,0,255}, extent = {{-100, 120}, {100, 140}}, textString = "%name"),
      Polygon(points = {{-57, -85}, {-37, -85}, {57, 85}, {37, 85}, {-57, -85}}, lineColor = {95, 95, 95}, fillColor = {175, 175, 175},
              fillPattern =                                                                                                   FillPattern.Backward, origin = {5, -53}, rotation = 90),
      Line(visible = not useTranslationalSupport, points = {{-10, -10}, {10, 10}}, color = {0, 0, 0}, origin = {-110, -20}, rotation = 270),
      Line(visible = not useTranslationalSupport, points = {{-10, -10}, {10, 10}}, color = {0, 0, 0}, origin = {-110, 0}, rotation = 270),
      Line(visible = not useTranslationalSupport, points = {{-10, -10}, {10, 10}}, color = {0, 0, 0}, origin = {-110, 20}, rotation = 270),
      Line(visible = not useTranslationalSupport, points = {{-10, -10}, {10, 10}}, color = {0, 0, 0}, origin = {-110, 40}, rotation = 270),
      Line(visible = not useTranslationalSupport, points = {{-30, 0}, {30, 0}}, color = {0, 0, 0}, origin = {-100, 0}, rotation = 270),
      Rectangle(extent={{-100,16},{-10,12}}, lineColor={0,0,0}, fillColor={95,95,95},
              fillPattern =                                                                         FillPattern.Solid)}),
      Documentation(info = "<html>
<p>
This is a simple model of a drive pulley without losses and without inertia.<br>
It is assumed that the two rotational flanges flange_a and flange_b are connected by a rope.
The rope moving into flange_a moves out from flange b.<br>
The relationship between the rotational flange and the two translational flanges flange_a and flange_b is defined by:
</p>
<pre>
  flange_a.s + flange_b.s = 0;
  flange.phi*radius = flange_a.s;
  flange.tau + (flange_a.f - flange_b.f)*radius = 0;
</pre>
<p>
Note, there is a balance between torque and the difference of forces * radius, a rotational support is not present.<br>
The sum of the two forces appears at the optional translational support.
</p>
</html>"));
  end IdealDrivePulley;

  model MassGravitation "Mass with gravitational force"
    parameter Modelica.SIunits.Mass m(final min = 0) "Mass";
    parameter Modelica.SIunits.Acceleration g = Modelica.Constants.g_n
      "Gravitation";
    Modelica.SIunits.Position s(start = 0) "Position of flange";
    Modelica.SIunits.Velocity v(start = 0) "Velocity of flange";
    Modelica.SIunits.Acceleration a(start = 0) "Acceleration of flange";
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange annotation(Placement(transformation(extent = {{-10, 110}, {10, 90}})));
  equation
    s = flange.s;
    v = der(s);
    a = der(v);
    m * a = flange.f - m * g;
    annotation(Icon(coordinateSystem(preserveAspectRatio = false), graphics={
    Rectangle(extent = {{-55, -30}, {55, 30}}, lineColor = {0, 0, 0},
              fillPattern =                                                         FillPattern.Sphere, fillColor = {255, 255, 255}, origin = {0, 25}, rotation = 90),
    Line(points = {{2.62459e-031, -4.28629e-015}, {20, 0}}, color = {0, 127, 0}, origin = {0, 80}, rotation = 90),
    Text(extent = {{-100, 20}, {100, -20}}, lineColor={0,0,255},        origin = {-80, 0}, rotation = 90, textString = "%name"),
    Text(extent = {{-100, 10}, {100, -10}}, lineColor={0,0,255},        origin = {90, 0}, rotation = 90, textString = "m=%m"),
    Line(points = {{-70, -7.71773e-015}, {60, 0}}, color = {0, 0, 0}, origin = {60, -10}, rotation = 90),
    Polygon(points = {{15, 0}, {-15, 10}, {-15, -10}, {15, 0}}, lineColor = {0, 0, 0}, fillColor = {128, 128, 128},
              fillPattern =                                                                                                   FillPattern.Solid, origin = {60, 65}, rotation = 90),
    Polygon(points = {{-10, -30}, {10, -30}, {10, -60}, {20, -60}, {0, -80}, {-20, -60}, {-10, -60}, {-10, -30}}, lineColor = {0, 127, 0}, fillColor = {0, 127, 0},
              fillPattern =                                                                                                   FillPattern.Solid)}),
    Diagram(coordinateSystem(preserveAspectRatio = false)), Documentation(info = "<html>
<p>
This is a simple model of a mass either hanging on a rope or lying on an eleveating platform.<br>
Both inertia and gravitional force is modelled.
</p>
</html>"));
  end MassGravitation;
end Elevator;
