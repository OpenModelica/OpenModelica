within ;
package gearDrive
  package Rotational

    model Verpanneinheit

      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Verspanneinheit(J = J_Verspanneinheit) annotation (
        Placement(visible = true, transformation(origin = {-16, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      gearDrive.Sources.Verspannmoment Verspannmoment annotation (Placement(
            visible=true, transformation(
            origin={14,0},
            extent={{-10,-10},{10,10}},
            rotation=0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
        Placement(visible = true, transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-148, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression Absolutwert(y = y) annotation (
        Placement(visible = true, transformation(origin = {14, 42}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zwischenwelle32(J = J_Zwischenwelle32) annotation (
        Placement(visible = true, transformation(origin = {40, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zwischenwelle33(J = J_Zwischenwelle33) annotation (
        Placement(visible = true, transformation(origin = {-76, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Zwischenwelle33(c = c_Zwischenwelle33) annotation (
        Placement(visible = true, transformation(origin = {-46, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      parameter Modelica.Blocks.Interfaces.RealOutput y = 0.0
        "Torsionsmoment durch Verspannung [Nm]";
      parameter Modelica.SIunits.Inertia J_Verspanneinheit(min = 0, start = 1)
        "Trägheitsmoment der Verspanneinheit";
      parameter Modelica.SIunits.Inertia J_Zwischenwelle32(min = 0, start = 1)
        "Trägheitsmoment der Zwischenwelle32";
      parameter Modelica.SIunits.Inertia J_Zwischenwelle33(min = 0, start = 1)
        "Trägheitsmoment der Zwischenwelle33";
      parameter Modelica.SIunits.RotationalSpringConstant c_Zwischenwelle32(final min = 0, start = 1.0e5)
        "Federsteifigkeit Zwischenwelle32";
      parameter Modelica.SIunits.RotationalSpringConstant c_Zwischenwelle33(final min = 0, start = 1.0e5)
        "Federsteifigkeit Zwischenwelle33";
      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Zwischenwelle32(c = c_Zwischenwelle32) annotation (
        Placement(visible = true, transformation(origin = {74, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation (
        Placement(visible = true, transformation(origin = {112, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(Federsteifigkeit_Zwischenwelle32.flange_b, flange_b) annotation (
        Line(points = {{84, 0}, {112, 0}, {112, 0}, {112, 0}}));
      connect(Traegheit_Zwischenwelle32.flange_b, Federsteifigkeit_Zwischenwelle32.flange_a) annotation (
        Line(points = {{50, 0}, {64, 0}, {64, 0}, {64, 0}}));
      connect(Verspannmoment.flange_b, Traegheit_Zwischenwelle32.flange_a) annotation (
        Line(points = {{24, 0}, {30, 0}, {30, 0}, {30, 0}}));
      connect(Federsteifigkeit_Zwischenwelle33.flange_b, Traegheit_Verspanneinheit.flange_a) annotation (
        Line(points = {{-36, 0}, {-26, 0}, {-26, 0}, {-26, 0}}));
      connect(Traegheit_Zwischenwelle33.flange_b, Federsteifigkeit_Zwischenwelle33.flange_a) annotation (
        Line(points = {{-66, 0}, {-56, 0}, {-56, 0}, {-56, 0}}));
      connect(flange_a, Traegheit_Zwischenwelle33.flange_a) annotation (
        Line(points = {{-100, 0}, {-86, 0}, {-86, 0}, {-86, 0}}));
      connect(Absolutwert.y, Verspannmoment.tau) annotation (
        Line(points = {{14, 31}, {14, 4}}, color = {0, 0, 127}));
      connect(Traegheit_Verspanneinheit.flange_b, Verspannmoment.flange_a) annotation (
        Line(points = {{-6, 0}, {4, 0}}));
      annotation (
        Icon(graphics={  Rectangle(origin=  {-25, 21}, fillColor=  {255, 255, 255},
                fillPattern=                                                                      FillPattern.HorizontalCylinder, extent=  {{-15, 59}, {65, -101}}, radius=  5), Rectangle(origin=  {-60, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-90, 20}, {20, -20}}), Rectangle(origin=  {60, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-20, 20}, {90, -20}}), Text(origin=  {-7, 16}, lineColor=  {0, 0, 255}, extent=  {{-150, 60}, {150, 100}}, textString=  "%name"), Line(origin=  {0, 1.21084}, points=  {{0, 78.7892}, {0, -81.2108}})}, coordinateSystem(extent = {{-150, -100}, {150, 100}})),
        Diagram(coordinateSystem(extent = {{-150, -100}, {150, 100}})),
        __OpenModelica_commandLineOptions = "");
    end Verpanneinheit;

    model Zahnkupplungseinheit_Strang1

      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Flanschwelle31(c = c_Flanschwelle31) annotation (
        Placement(visible = true, transformation(origin = {88, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Flanschwelle31(J = J_Flanschwelle31) annotation (
        Placement(visible = true, transformation(origin = {126, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zahnkupplung22_1(J = J_Zahnkupplung22) annotation (
        Placement(visible = true, transformation(origin = {54, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Welle26(c = c_Welle26) annotation (
        Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Welle26(J = J_Welle26) annotation (
        Placement(visible = true, transformation(origin = {-16, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zahnkupplung22_2(J = J_Zahnkupplung22) annotation (
        Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Spannsatzflansch30(J = J_Spannsatzflansch30) annotation (
        Placement(visible = true, transformation(origin = {-86, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Schrumpfscheibe(J = J_Schrumpfscheibe28) annotation (
        Placement(visible = true, transformation(origin = {-120, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
        Placement(visible = true, transformation(origin = {-150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation (
        Placement(visible = true, transformation(origin = {150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {200, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      parameter Modelica.SIunits.Inertia J_Schrumpfscheibe28(min = 0, start = 1)
        "Trägheitsmoment Schrumpscheibe28";
      parameter Modelica.SIunits.Inertia J_Spannsatzflansch30(min = 0, start = 1)
        "Trägheitsmoment Spannsatzflansch30";
      parameter Modelica.SIunits.Inertia J_Zahnkupplung22(min = 0, start = 1)
        "Trägheitsmoment einer Zahnkupplung";
      parameter Modelica.SIunits.Inertia J_Welle26(min = 0, start = 1)
        "Trägheitsmoment Welle26";
      parameter Modelica.SIunits.Inertia J_Flanschwelle31(min = 0, start = 1)
        "Trägheitsmoment Flanschwelle31";
      parameter Modelica.SIunits.RotationalSpringConstant c_Welle26(final min = 0, start = 1.0e5)
        "Federsteifigkeit Welle26";
      parameter Modelica.SIunits.RotationalSpringConstant c_Flanschwelle31(final min = 0, start = 1.0e5)
        "Federsteifigkeit Flanschwelle31";
    equation
      connect(Traegheit_Flanschwelle31.flange_b, flange_b) annotation (
        Line(points = {{136, 0}, {150, 0}, {150, 0}, {150, 0}}));
      connect(Federsteifigkeit_Flanschwelle31.flange_b, Traegheit_Flanschwelle31.flange_a) annotation (
        Line(points = {{98, 0}, {116, 0}, {116, 0}, {116, 0}}));
      connect(Traegheit_Zahnkupplung22_1.flange_b, Federsteifigkeit_Flanschwelle31.flange_a) annotation (
        Line(points = {{64, 0}, {78, 0}, {78, 0}, {78, 0}}));
      connect(Federsteifigkeit_Welle26.flange_b, Traegheit_Zahnkupplung22_1.flange_a) annotation (
        Line(points = {{30, 0}, {44, 0}, {44, 0}, {44, 0}}));
      connect(Traegheit_Welle26.flange_b, Federsteifigkeit_Welle26.flange_a) annotation (
        Line(points = {{-6, 0}, {10, 0}, {10, 0}, {10, 0}}));
      connect(Traegheit_Zahnkupplung22_2.flange_b, Traegheit_Welle26.flange_a) annotation (
        Line(points = {{-40, 0}, {-26, 0}, {-26, 0}, {-26, 0}}));
      connect(Traegheit_Spannsatzflansch30.flange_b, Traegheit_Zahnkupplung22_2.flange_a) annotation (
        Line(points = {{-76, 0}, {-60, 0}, {-60, 0}, {-60, 0}}));
      connect(Traegheit_Schrumpfscheibe.flange_b, Traegheit_Spannsatzflansch30.flange_a) annotation (
        Line(points = {{-110, 0}, {-96, 0}, {-96, 0}, {-96, 0}}));
      connect(flange_a, Traegheit_Schrumpfscheibe.flange_a) annotation (
        Line(points={{-150,0},{-130,0}}));
      annotation (
        Diagram(coordinateSystem(extent={{-150,-60},{150,60}}, preserveAspectRatio=false),
            graphics),
        Icon(coordinateSystem(extent = {{-150, -60}, {150, 60}}, initialScale = 0.1), graphics={  Rectangle(origin=  {-121, 10}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-19, 50}, {53, -70}}, radius=  1), Rectangle(origin=  {119, 10}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-41, 50}, {33, -70}}, radius=  1), Rectangle(origin=  {-22, 4}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-46, 16}, {100, -24}}), Text(origin=  {4, -10}, lineColor=  {0, 0, 255}, fillColor=  {0, 0, 255}, extent=  {{-150, 100}, {150, 60}}, textString=  "%name"), Rectangle(origin=  {-145, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-5, 32}, {5, -32}}, radius=  1), Rectangle(origin=  {198, 4}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-46, 16}, {2, -24}})}),
        __OpenModelica_commandLineOptions = "");
    end Zahnkupplungseinheit_Strang1;

    model Getriebe1

      Modelica.Mechanics.Rotational.Components.Gearbox Getriebe1(b = b, c = c, d = d, ratio = ratio) annotation (
        Placement(visible = true, transformation(origin = {24, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Schrumpfscheibe28_1(J = J_Schrumpfscheibe28) annotation (
        Placement(visible = true, transformation(origin = {-22, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Getriebe1_reduziertAufAntriebswelle(J = J_Getriebe1) annotation (
        Placement(visible = true, transformation(origin = {-74, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Schrumpscheibe28_2(J = J_Schrumpfscheibe28) annotation (
        Placement(visible = true, transformation(origin = {62, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
        Placement(visible = true, transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {0, 200}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation (
        Placement(visible = true, transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-2, -200}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      parameter Real ratio(start = 1)
        "Transmission ratio (flange_a.phi/flange_b.phi)";
      parameter Real lossTable[:, 5] = [0, 1, 1, 0, 0]
        "Array for mesh efficiencies and bearing friction depending on speed (see docu of LossyGear)";
      parameter Modelica.SIunits.RotationalSpringConstant c(final min = Modelica.Constants.small, start = 1.0e5)
        "Gear elasticity (spring constant)";
      parameter Modelica.SIunits.RotationalDampingConstant d(final min = 0, start = 0)
        "(relative) gear damping";
      parameter Modelica.SIunits.Angle b(final min = 0) = 0 "Total backlash";
      parameter StateSelect stateSelect = StateSelect.prefer
        "Priority to use phi_rel and w_rel as states"                                                      annotation (
        HideResult = true,
        Dialog(tab = "Advanced"));
      parameter Modelica.SIunits.Inertia J_Getriebe1(min = 0, start = 1)
        "Trägheitsmoment des Getriebe1 auf die Antriebswelle reduziert";
      parameter Modelica.SIunits.Inertia J_Schrumpfscheibe28(min = 0, start = 1)
        "Trägheitsmoment der Schrumpscheieb28";
    equation
      connect(Traegheit_Schrumpfscheibe28_1.flange_b, Getriebe1.flange_a) annotation (
        Line(points = {{-12, 0}, {14, 0}}));
      connect(Traegheit_Getriebe1_reduziertAufAntriebswelle.flange_b, Traegheit_Schrumpfscheibe28_1.flange_a) annotation (
        Line(points = {{-64, 0}, {-32, 0}}));
      connect(Getriebe1.flange_b, Traegheit_Schrumpscheibe28_2.flange_a) annotation (
        Line(points = {{34, 0}, {52, 0}}));
      connect(Traegheit_Schrumpscheibe28_2.flange_b, flange_b) annotation (
        Line(points = {{72, 0}, {100, 0}}));
      connect(flange_a, Traegheit_Getriebe1_reduziertAufAntriebswelle.flange_a) annotation (
        Line(points = {{-100, 0}, {-84, 0}, {-84, 0}, {-84, 0}}));
      annotation (
        Icon(coordinateSystem(extent = {{-100, -200}, {100, 200}}), graphics={  Rectangle(origin=  {2, -5}, fillColor=  {140, 140, 140},
                fillPattern=                                                                                                    FillPattern.Solid, extent=  {{-82, 265}, {78, -253}}, radius=  20), Rectangle(origin=  {-90, 210}, fillColor=  {140, 140, 140},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{0, 10}, {10, -30}}), Rectangle(origin=  {80, 210}, fillColor=  {140, 140, 140},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{0, 10}, {10, -30}}), Rectangle(origin=  {-111, -199}, fillColor=  {140, 140, 140},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-29, 19}, {31, -21}}), Text(origin=  {-4, 209}, lineColor=  {0, 0, 255}, fillColor=  {0, 85, 255}, extent=  {{-150, 60}, {150, 100}}, textString=  "%name")}),
        Diagram(coordinateSystem(extent = {{-100, -200}, {100, 200}})),
        __OpenModelica_commandLineOptions = "");
    end Getriebe1;

    model Getriebe2

      Modelica.Mechanics.Rotational.Components.Gearbox Getriebe2(b = b, c = c, d = d, ratio = ratio) annotation (
        Placement(visible = true, transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Getriebe2_reduziertAufStrang2(J = J_Getriebe2) annotation (
        Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
        Placement(visible = true, transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {0, 200}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation (
        Placement(visible = true, transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-2, -200}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      parameter Real ratio(start = 1)
        "Transmission ratio (flange_a.phi/flange_b.phi)";
      parameter Real lossTable[:, 5] = [0, 1, 1, 0, 0]
        "Array for mesh efficiencies and bearing friction depending on speed (see docu of LossyGear)";
      parameter Modelica.SIunits.RotationalSpringConstant c(final min = Modelica.Constants.small, start = 1.0e5)
        "Gear elasticity (spring constant)";
      parameter Modelica.SIunits.RotationalDampingConstant d(final min = 0, start = 0)
        "(relative) gear damping";
      parameter Modelica.SIunits.Angle b(final min = 0) = 0 "Total backlash";
      parameter StateSelect stateSelect = StateSelect.prefer
        "Priority to use phi_rel and w_rel as states"                                                      annotation (
        HideResult = true,
        Dialog(tab = "Advanced"));
      parameter Modelica.SIunits.Inertia J_Getriebe2(min = 0, start = 1)
        "Trägheitsmoment des Getriebe2 auf Strang 2 reduziert";
      parameter Modelica.SIunits.Inertia J_Schrumpfscheibe28(min = 0, start = 1)
        "Trägheitsmoment der Schrumpscheieb28";
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Schrumpfscheibe28(J = J_Schrumpfscheibe28) annotation (
        Placement(visible = true, transformation(origin = {-70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(Traegheit_Getriebe2_reduziertAufStrang2.flange_b, flange_b) annotation (
        Line(points = {{60, 0}, {100, 0}, {100, 0}, {100, 0}}));
      connect(Getriebe2.flange_b, Traegheit_Getriebe2_reduziertAufStrang2.flange_a) annotation (
        Line(points={{10,0},{40,0}}));
      connect(Traegheit_Schrumpfscheibe28.flange_b, Getriebe2.flange_a) annotation (
        Line(points={{-60,0},{-10,0}}));
      connect(flange_a, Traegheit_Schrumpfscheibe28.flange_a) annotation (
        Line(points = {{-100, 0}, {-80, 0}, {-80, 0}, {-80, 0}}));
      annotation (
        Icon(coordinateSystem(extent = {{-100, -200}, {100, 200}}, initialScale = 0.1), graphics={  Rectangle(origin=  {2, -5}, fillColor=  {140, 140, 140},
                fillPattern=                                                                                                    FillPattern.Solid, extent=  {{-82, 265}, {78, -253}}, radius=  20), Rectangle(origin=  {80, 200}, fillColor=  {140, 140, 140},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{0, 20}, {10, -20}}), Rectangle(origin=  {109, -199}, fillColor=  {140, 140, 140},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-29, 19}, {31, -21}}), Text(origin=  {-4, 209}, lineColor=  {0, 0, 255}, fillColor=  {0, 85, 255}, extent=  {{-150, 60}, {150, 100}}, textString=  "%name")}),
        Diagram(coordinateSystem(extent = {{-100, -200}, {100, 200}})),
        __OpenModelica_commandLineOptions = "");
    end Getriebe2;

    model Antriebsmotor

      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Laeufer(J = J_Laeufer) annotation (
        Placement(visible = true, transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Antriebswelle(c = c_Antriebswelle) annotation (
        Placement(visible = true, transformation(origin = {-92, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Sources.Speed Drehzahl_Antriebsmotor annotation (
        Placement(visible = true, transformation(origin = {-16, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.Ramp Anlaufkurve_Antriebsmotor(duration = duration, height = height, offset = offset, startTime = startTime) annotation (
        Placement(visible = true, transformation(origin = {44, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Antriebswelle(J = J_Antriebswelle) annotation (
        Placement(visible = true, transformation(origin = {-126, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
        Placement(visible = true, transformation(origin = {-150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      parameter Modelica.SIunits.Inertia J_Laeufer(min = 0, start = 1)
        "Trägheitsmoment des Laeufers";
      parameter Modelica.SIunits.Inertia J_Antriebswelle(min = 0, start = 1)
        "Trägheitsmoment der Antriebswelle";
      parameter Modelica.SIunits.RotationalSpringConstant c_Antriebswelle(final min = 0, start = 1.0e5)
        "Federsteifigkeit der Antriebswelle";
      //Parameter Rampe
      parameter Real height = 1 "Drehzahl des Antriebsmotors [rad/s]";
      parameter Modelica.SIunits.Time duration(min = 0.0, start = 2)
        "Duration of ramp (= 0.0 gives a Step)";
      parameter Real offset = 0 "Offset of output signal";
      parameter Modelica.SIunits.Time startTime = 0
        "Output = offset for time < startTime";
    equation
      connect(Drehzahl_Antriebsmotor.w_ref, Anlaufkurve_Antriebsmotor.y) annotation (
        Line(points={{-4,0},{32,0},{32,0},{33,0}},          color = {0, 0, 127}));
      connect(Traegheit_Laeufer.flange_b, Drehzahl_Antriebsmotor.flange) annotation (
        Line(points = {{-50, 0}, {-26, 0}, {-26, 0}, {-26, 0}}));
      connect(Federsteifigkeit_Antriebswelle.flange_b, Traegheit_Laeufer.flange_a) annotation (
        Line(points = {{-82, 0}, {-70, 0}, {-70, 0}, {-70, 0}}));
      connect(Traegheit_Antriebswelle.flange_b, Federsteifigkeit_Antriebswelle.flange_a) annotation (
        Line(points = {{-116, 0}, {-102, 0}, {-102, 0}, {-102, 0}}));
      connect(flange_a, Traegheit_Antriebswelle.flange_a) annotation (
        Line(points = {{-150, 0}, {-138, 0}, {-138, 0}, {-136, 0}}));
      annotation (
        Diagram(coordinateSystem(extent = {{-150, -100}, {150, 100}})),
        Icon(coordinateSystem(extent = {{-150, -100}, {150, 100}}, initialScale = 0.1), graphics={  Rectangle(origin=  {52, 38}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-92, 42}, {98, -118}}, radius=  10), Rectangle(origin=  {-102, -10}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-48, 30}, {62, -10}}), Text(origin=  {3, 41}, lineColor=  {0, 0, 255}, extent=  {{-150, 60}, {150, 100}}, textString=  "%name")}),
        __OpenModelica_commandLineOptions = "");
    end Antriebsmotor;

    model Zahnkupplungseinheit_Strang2

      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
        Placement(visible = true, transformation(origin = {-150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation (
        Placement(visible = true, transformation(origin = {150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {152, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Kupplungsflansch42(J = J_Kupplungsflansch42) annotation (
        Placement(visible = true, transformation(origin = {130, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zwischenflansch29(J = J_Zwischenflansch29) annotation (
        Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zahnkupplung22_1(J = J_Zahnkupplung22) annotation (
        Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Welle27(J = J_Welle27) annotation (
        Placement(visible = true, transformation(origin = {10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Welle27(c = c_Welle27) annotation (
        Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zahnkupplung22_2(J = J_Zahnkupplung22) annotation (
        Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Spannsatzflansch30(J = J_Spannsatzflansch30) annotation (
        Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Schrumpfscheibe28(J = J_Schrumpfscheibe28) annotation (
        Placement(visible = true, transformation(origin = {-130, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      parameter Modelica.SIunits.Inertia J_Schrumpfscheibe28(min = 0, start = 1)
        "Trägheitsmoment der Schrumpfscheieb28";
      parameter Modelica.SIunits.Inertia J_Spannsatzflansch30(min = 0, start = 1)
        "Trägheitsmoment des Spannsatzflansch30";
      parameter Modelica.SIunits.Inertia J_Zahnkupplung22(min = 0, start = 1)
        "Trägheitsmoment der Zahnkupplung22";
      parameter Modelica.SIunits.Inertia J_Zwischenflansch29(min = 0, start = 1)
        "Trägheitsmoment des Zwischenflansch29";
      parameter Modelica.SIunits.Inertia J_Kupplungsflansch42(min = 0, start = 1)
        "Trägheitsmoment des Kupplungsflansch42";
      parameter Modelica.SIunits.Inertia J_Welle27(min = 0, start = 1)
        "Trägheitsmoment der Welle27";
      parameter Modelica.SIunits.RotationalSpringConstant c_Welle27(final min = 0, start = 1.0e5)
        "Federsteifigkeit der Welle27";
    equation
      connect(Traegheit_Kupplungsflansch42.flange_b, flange_b) annotation (
        Line(points = {{140, 0}, {152, 0}, {152, 0}, {150, 0}}));
      connect(Traegheit_Zwischenflansch29.flange_b, Traegheit_Kupplungsflansch42.flange_a) annotation (
        Line(points = {{100, 0}, {120, 0}, {120, 0}, {120, 0}}));
      connect(Traegheit_Zahnkupplung22_1.flange_b, Traegheit_Zwischenflansch29.flange_a) annotation (
        Line(points = {{60, 0}, {80, 0}, {80, 0}, {80, 0}}));
      connect(Traegheit_Welle27.flange_b, Traegheit_Zahnkupplung22_1.flange_a) annotation (
        Line(points = {{20, 0}, {40, 0}, {40, 0}, {40, 0}}));
      connect(Federsteifigkeit_Welle27.flange_b, Traegheit_Welle27.flange_a) annotation (
        Line(points = {{-10, 0}, {-10, 0}, {-10, 0}, {0, 0}}));
      connect(Traegheit_Zahnkupplung22_2.flange_b, Federsteifigkeit_Welle27.flange_a) annotation (
        Line(points = {{-40, 0}, {-30, 0}, {-30, 0}, {-30, 0}}));
      connect(Traegheit_Spannsatzflansch30.flange_b, Traegheit_Zahnkupplung22_2.flange_a) annotation (
        Line(points = {{-80, 0}, {-60, 0}, {-60, 0}, {-60, 0}}));
      connect(Traegheit_Schrumpfscheibe28.flange_b, Traegheit_Spannsatzflansch30.flange_a) annotation (
        Line(points = {{-120, 0}, {-100, 0}, {-100, 0}, {-100, 0}}));
      connect(flange_a, Traegheit_Schrumpfscheibe28.flange_a) annotation (
        Line(points = {{-150, 0}, {-140, 0}, {-140, 0}, {-140, 0}}));
      annotation (
        Diagram(coordinateSystem(extent = {{-150, -60}, {150, 60}})),
        Icon(coordinateSystem(extent = {{-150, -60}, {150, 60}}, initialScale = 0.1), graphics={  Rectangle(origin=  {-121, 10}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-19, 50}, {53, -70}}, radius=  1), Rectangle(origin=  {119, 10}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-41, 50}, {33, -70}}, radius=  1), Rectangle(origin=  {-22, 4}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-46, 16}, {100, -24}}), Text(origin=  {4, -10}, lineColor=  {0, 0, 255}, fillColor=  {0, 0, 255}, extent=  {{-150, 100}, {150, 60}}, textString=  "%name"), Rectangle(origin=  {-145, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-5, 32}, {5, -32}}, radius=  1)}),
        __OpenModelica_commandLineOptions = "");
    end Zahnkupplungseinheit_Strang2;

    model Messwelle

      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
        Placement(visible = true, transformation(origin = {-150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation (
        Placement(visible = true, transformation(origin = {150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {150, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zwischenwelle34(J = J_Zwischenwelle34) annotation (
        Placement(visible = true, transformation(origin = {128, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Zwischenwelle34(c = c_Zwischenwelle34) annotation (
        Placement(visible = true, transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Schrumpfscheibe28_1(J = J_Schrumpfscheibe28) annotation (
        Placement(visible = true, transformation(origin = {70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Spannsatzflansch30_1(J = J_Spannsatzflansch30) annotation (
        Placement(visible = true, transformation(origin = {40, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Messwelle(J = J_Messwelle) annotation (
        Placement(visible = true, transformation(origin = {10, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Messwelle(c = c_Messwelle) annotation (
        Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Spannsatzflansch30_2(J = J_Spannsatzflansch30) annotation (
        Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Schrumpfscheibe28_2(J = J_Schrumpfscheibe28) annotation (
        Placement(visible = true, transformation(origin = {-80, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Inertia Traegheit_Zwischenwelle(J = J_Zwischenwelle) annotation (
        Placement(visible = true, transformation(origin = {-130, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Mechanics.Rotational.Components.Spring Federsteifigkeit_Zwischenwelle(c = c_Zwischenwelle) annotation (
        Placement(visible = true, transformation(origin = {-106, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      parameter Modelica.SIunits.Inertia J_Zwischenwelle(min = 0, start = 1)
        "Trägheitsmoment der Zwischenwelle";
      parameter Modelica.SIunits.Inertia J_Schrumpfscheibe28(min = 0, start = 1)
        "Trägheitsmoment der Schrumpfscheibe28";
      parameter Modelica.SIunits.Inertia J_Spannsatzflansch30(min = 0, start = 1)
        "Trägheitsmoment des Spannsatzflansch30";
      parameter Modelica.SIunits.Inertia J_Messwelle(min = 0, start = 1)
        "Trägheitsmoment der Messwelle";
      parameter Modelica.SIunits.Inertia J_Zwischenwelle34(min = 0, start = 1)
        "Trägheitsmoment der Zwischenwelle34";
      parameter Modelica.SIunits.RotationalSpringConstant c_Zwischenwelle(final min = 0, start = 1.0e5)
        "Federsteifigkeit Zwischenwelle";
      parameter Modelica.SIunits.RotationalSpringConstant c_Messwelle(final min = 0, start = 1.0e5)
        "Federsteifigkeit Messwelle";
      parameter Modelica.SIunits.RotationalSpringConstant c_Zwischenwelle34(final min = 0, start = 1.0e5)
        "Federsteifigkeit Zwischenwelle34";
    equation
      connect(Traegheit_Zwischenwelle34.flange_b, flange_b) annotation (
        Line(points = {{138, 0}, {150, 0}, {150, 0}, {150, 0}}));
      connect(Federsteifigkeit_Zwischenwelle34.flange_b, Traegheit_Zwischenwelle34.flange_a) annotation (
        Line(points = {{110, 0}, {118, 0}, {118, 0}, {118, 0}}));
      connect(Traegheit_Schrumpfscheibe28_1.flange_b, Federsteifigkeit_Zwischenwelle34.flange_a) annotation (
        Line(points = {{80, 0}, {90, 0}, {90, 0}, {90, 0}}));
      connect(Traegheit_Spannsatzflansch30_1.flange_b, Traegheit_Schrumpfscheibe28_1.flange_a) annotation (
        Line(points = {{50, 0}, {60, 0}, {60, 0}, {60, 0}}));
      connect(Traegheit_Messwelle.flange_b, Traegheit_Spannsatzflansch30_1.flange_a) annotation (
        Line(points = {{20, 0}, {30, 0}, {30, 0}, {30, 0}}));
      connect(Federsteifigkeit_Messwelle.flange_b, Traegheit_Messwelle.flange_a) annotation (
        Line(points = {{-10, 0}, {-10, 0}, {-10, 0}, {0, 0}}));
      connect(Traegheit_Spannsatzflansch30_2.flange_b, Federsteifigkeit_Messwelle.flange_a) annotation (
        Line(points={{-40,0},{-30,0}}));
      connect(Traegheit_Schrumpfscheibe28_2.flange_b, Traegheit_Spannsatzflansch30_2.flange_a) annotation (
        Line(points={{-70,0},{-60,0}}));
      connect(Federsteifigkeit_Zwischenwelle.flange_b, Traegheit_Schrumpfscheibe28_2.flange_a) annotation (
        Line(points = {{-96, 0}, {-90, 0}, {-90, 0}, {-90, 0}}));
      connect(Traegheit_Zwischenwelle.flange_b, Federsteifigkeit_Zwischenwelle.flange_a) annotation (
        Line(points = {{-120, 0}, {-116, 0}, {-116, 0}, {-116, 0}}));
      connect(flange_a, Traegheit_Zwischenwelle.flange_a) annotation (
        Line(points = {{-150, 0}, {-140, 0}, {-140, 0}, {-140, 0}}));
      annotation (
        Diagram(coordinateSystem(extent = {{-150, -100}, {150, 100}})),
        Icon(coordinateSystem(extent = {{-150, -100}, {150, 100}}, initialScale = 0.1), graphics={  Rectangle(origin=  {-2, -12}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-108, 32}, {112, -8}}), Rectangle(origin=  {-120, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{10, 60}, {-10, -60}}), Rectangle(origin=  {120, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-10, 60}, {10, -60}}), Rectangle(origin=  {-140, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-10, 20}, {10, -20}}), Rectangle(origin=  {138, -14}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-8, 34}, {12, -6}}), Text(origin=  {-6, 13}, lineColor=  {0, 0, 255}, extent=  {{-150, 60}, {150, 100}}, textString=  "%name"), Rectangle(origin=  {-135, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-5, 40}, {5, -40}}), Rectangle(origin=  {135, 0}, fillColor=  {255, 255, 255},
                fillPattern=                                                                                                    FillPattern.HorizontalCylinder, extent=  {{-5, 40}, {5, -40}})}),
        __OpenModelica_commandLineOptions = "");
    end Messwelle;

  end Rotational;

  package Sources

    model Verspannmoment "Input signal acting as torque on two flanges"
      extends Modelica.Mechanics.Rotational.Interfaces.PartialTwoFlanges;
      Modelica.Blocks.Interfaces.RealInput tau(unit = "N.m")
        "Torque driving the two flanges (a positive value accelerates the flange)"
                                                                                                            annotation (
        Placement(transformation(origin = {0, 40}, extent = {{-20, -20}, {20, 20}}, rotation = 270)));
    equation
      flange_a.tau = tau / 2;
      flange_b.tau = -tau / 2;
      annotation (
        Documentation(info = "<html>
<p>
The input signal <b>tau</b> defines an external
torque in [Nm] which acts at both flange connectors,
i.e., the components connected to these flanges are driven by torque <b>tau</b>.</p>
<p>The input signal can be provided from one of the signal generator
blocks of Modelica.Blocks.Sources.
</p>
</html>"),
        Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics={  Text(extent=  {{-150, -40}, {150, -80}}, textString=  "%name", lineColor=  {0, 0, 255}), Polygon(points=  {{-78, 24}, {-69, 17}, {-89, 0}, {-78, 24}}, lineColor=  {0, 0, 0},
                lineThickness=                                                                                                    0.5, fillColor=  {0, 0, 0},
                fillPattern=                                                                                                    FillPattern.Solid), Line(points=  {{-74, 20}, {-70, 23}, {-65, 26}, {-60, 28}, {-56, 29}, {-50, 30}, {-41, 30}, {-35, 29}, {-31, 28}, {-26, 26}, {-21, 23}, {-17, 20}, {-13, 15}, {-10, 9}}, thickness=  0.5, smooth=  Smooth.Bezier), Line(points=  {{74, 20}, {70, 23}, {65, 26}, {60, 28}, {56, 29}, {50, 30}, {41, 30}, {35, 29}, {31, 28}, {26, 26}, {21, 23}, {17, 20}, {13, 15}, {10, 9}}, thickness=  0.5, smooth=  Smooth.Bezier), Polygon(points=  {{89, 0}, {78, 24}, {69, 17}, {89, 0}}, lineColor=  {0, 0, 0}, fillColor=  {0, 0, 0},
                fillPattern=                                                                                                    FillPattern.Solid)}),
        Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics={  Text(extent=  {{15, -71}, {83, -84}}, lineColor=  {128, 128, 128}, textString=  "rotation axis"), Polygon(points=  {{11, -77}, {-9, -72}, {-9, -82}, {11, -77}}, lineColor=  {128, 128, 128}, fillColor=  {128, 128, 128},
                fillPattern=                                                                                                    FillPattern.Solid), Line(points=  {{-79, -77}, {-8, -77}}, color=  {128, 128, 128}), Line(points=  {{-75, 20}, {-71, 23}, {-66, 26}, {-61, 28}, {-57, 29}, {-51, 30}, {-42, 30}, {-36, 29}, {-32, 28}, {-27, 26}, {-22, 23}, {-18, 20}, {-14, 15}, {-11, 9}}, thickness=  0.5, smooth=  Smooth.Bezier), Polygon(points=  {{-79, 24}, {-70, 17}, {-90, 0}, {-79, 24}}, lineColor=  {0, 0, 0},
                lineThickness=                                                                                                    0.5, fillColor=  {0, 0, 0},
                fillPattern=                                                                                                    FillPattern.Solid), Line(points=  {{73, 20}, {69, 23}, {64, 26}, {59, 28}, {55, 29}, {49, 30}, {40, 30}, {34, 29}, {30, 28}, {25, 26}, {20, 23}, {16, 20}, {12, 15}, {9, 9}}, thickness=  0.5, smooth=  Smooth.Bezier), Polygon(points=  {{88, 0}, {77, 24}, {68, 17}, {88, 0}}, lineColor=  {0, 0, 0}, fillColor=  {0, 0, 0},
                fillPattern=                                                                                                    FillPattern.Solid)}));
    end Verspannmoment;
  end Sources;

  model drive
    gearDrive.Rotational.Zahnkupplungseinheit_Strang1 Zahnkupplungseinheit_Strang1_1(
      J_Flanschwelle31=1,
      J_Schrumpfscheibe28=1,
      J_Spannsatzflansch30=1,
      J_Welle26=1,
      J_Zahnkupplung22=1,
      c_Flanschwelle31=100000,
      c_Welle26=100000) annotation (Placement(visible=true, transformation(
          origin={46,20},
          extent={{-15,-6},{15,6}},
          rotation=0)));
    gearDrive.Rotational.Zahnkupplungseinheit_Strang1 Zahnkupplungseinheit_Strang1_2(
      J_Flanschwelle31=1,
      J_Schrumpfscheibe28=1,
      J_Spannsatzflansch30=1,
      J_Welle26=1,
      J_Zahnkupplung22=1,
      c_Flanschwelle31=100000,
      c_Welle26=100000) annotation (Placement(visible=true, transformation(
          origin={-50,20},
          extent={{15,-6},{-15,6}},
          rotation=0)));
    gearDrive.Rotational.Getriebe1 Getriebe1(
      J_Getriebe1=1,
      J_Schrumpfscheibe28=1,
      c=100000,
      d=10,
      ratio=1) annotation (Placement(visible=true, transformation(
          origin={92,0},
          extent={{-10,-20},{10,20}},
          rotation=0)));
    gearDrive.Rotational.Getriebe2 Getriebe2(
      J_Getriebe2=1,
      J_Schrumpfscheibe28=1,
      c=100000,
      d=10,
      ratio=1) annotation (Placement(visible=true, transformation(
          origin={-100,0},
          extent={{-10,-20},{10,20}},
          rotation=0)));
    gearDrive.Rotational.Antriebsmotor Antriebsmotor(
      J_Antriebswelle=1,
      J_Laeufer=1,
      c_Antriebswelle=100000,
      duration=5,
      height=150) annotation (Placement(visible=true, transformation(
          origin={134,20},
          extent={{-15,-10},{15,10}},
          rotation=0)));
    gearDrive.Rotational.Verpanneinheit Verpanneinheit(
      J_Verspanneinheit=1,
      J_Zwischenwelle32=1,
      J_Zwischenwelle33=1,
      c_Zwischenwelle32=100000,
      c_Zwischenwelle33=100000,
      y=100) annotation (Placement(visible=true, transformation(
          origin={0,20},
          extent={{-15,-10},{15,10}},
          rotation=0)));
    gearDrive.Rotational.Zahnkupplungseinheit_Strang2 Zahnkupplungseinheit_Strang2_1(
      J_Kupplungsflansch42=1,
      J_Schrumpfscheibe28=1,
      J_Spannsatzflansch30=1,
      J_Welle27=1,
      J_Zahnkupplung22=1,
      J_Zwischenflansch29=1,
      c_Welle27=100000) annotation (Placement(visible=true, transformation(
          origin={48,-20},
          extent={{-15,-6},{15,6}},
          rotation=0)));
    gearDrive.Rotational.Zahnkupplungseinheit_Strang2 Zahnkupplungseinheit_Strang2_2(
      J_Kupplungsflansch42=1,
      J_Schrumpfscheibe28=1,
      J_Spannsatzflansch30=1,
      J_Welle27=1,
      J_Zahnkupplung22=1,
      J_Zwischenflansch29=1,
      c_Welle27=100000) annotation (Placement(visible=true, transformation(
          origin={-48,-20},
          extent={{15,-6},{-15,6}},
          rotation=0)));
    Rotational.Messwelle messwelle1(J_Messwelle = 1, J_Schrumpfscheibe28 = 1, J_Spannsatzflansch30 = 1, J_Zwischenwelle = 1, J_Zwischenwelle34 = 1, c_Messwelle = 100000, c_Zwischenwelle = 100000, c_Zwischenwelle34 = 100000) annotation (
      Placement(visible = true, transformation(origin = {2, -20}, extent = {{-15, -10}, {15, 10}}, rotation = 0)));
  equation
    connect(Zahnkupplungseinheit_Strang1_2.flange_a, Verpanneinheit.flange_a) annotation (
      Line(points={{-35,20},{-14.8,20}}));
    connect(Zahnkupplungseinheit_Strang1_2.flange_b, Getriebe2.flange_a) annotation (
      Line(points = {{-70, 20}, {-100, 20}}));
    connect(Getriebe2.flange_b, Zahnkupplungseinheit_Strang2_2.flange_b) annotation (
      Line(points={{-100.2,-20},{-63.2,-20}}));
    connect(Zahnkupplungseinheit_Strang2_2.flange_a, messwelle1.flange_a) annotation (
      Line(points={{-33,-20},{-13,-20}}));
    connect(messwelle1.flange_b, Zahnkupplungseinheit_Strang2_1.flange_a) annotation (
      Line(points={{17,-20},{34,-20},{34,-20},{33,-20}}));
    connect(Zahnkupplungseinheit_Strang2_1.flange_b, Getriebe1.flange_b) annotation (
      Line(points={{63.2,-20},{92,-20},{91.8,-20}}));
    connect(Zahnkupplungseinheit_Strang1_1.flange_b, Getriebe1.flange_a) annotation (
      Line(points = {{66, 20}, {92, 20}}));
    connect(Verpanneinheit.flange_b, Zahnkupplungseinheit_Strang1_1.flange_a) annotation (
      Line(points = {{15, 20}, {31, 20}}));
    connect(Antriebsmotor.flange_a, Getriebe1.flange_a) annotation (
      Line(points = {{119, 20}, {92, 20}}));
    annotation (
      experiment(StartTime = 0, StopTime = 100, Tolerance = 0.000001, Interval = 0.1),
      Diagram(coordinateSystem(extent = {{-150, -50}, {150, 50}})),
      Icon(coordinateSystem(extent = {{-150, -50}, {150, 50}})),
      __OpenModelica_commandLineOptions = "");
  end drive;

  annotation (
    uses(Modelica(version = "3.2.2")),
    Diagram);
end gearDrive;
