within ;
package Aufgabe2
  model NonlinearSpring
    "Nonlinear 1D rotational spring (= gear characteristic)"
    import SI = Modelica.SIunits;
    parameter SI.RotationalSpringConstant c_min = 1.95e5
      "Spring constant for small angles";
    parameter SI.RotationalSpringConstant c_max = 5.84e5
      "Spring constant for nominal torque";
    parameter SI.Torque tau_n=500 "Nominal torque";
    SI.Angle phi_rel "Relative rotation angle (flange_b.phi - flange_a.phi)";
    SI.Angle phi_n "Nominal angle at nominal torque tau_n";
    Real a3 "Coefficient a3 of the polynomial";
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (Placement(
          transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation (Placement(
          transformation(extent={{90,-10},{110,10}}, rotation=0)));
  equation
    phi_n   = 3*tau_n/(c_max + 2*c_min);
    a3      = (c_max - c_min)/(3*phi_n*phi_n);
    phi_rel = flange_b.phi - flange_a.phi;
    0       = flange_a.tau + flange_b.tau;
    flange_b.tau = (c_min + a3*phi_rel*phi_rel)*phi_rel;
    annotation (
      Documentation(info="
<HTML>
<p>
A <b>non-linear 1D rotational spring</b> with a characteristic
which is typical for the elasticity of a gearbox. The elasticity
is described by the spring constant c_min for small deformation
angles, by the spring constant c_max for nominal (large) deformation
angles, and by the nominal torque tau_n. With these parameters the
gearbox characteristic is approximated by a polynomial of degree 3.
</p>
</HTML>
"),   Icon(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={1,1}), graphics={
          Text(
            extent={{-151,110},{149,50}},
            textString="%name",
            lineColor={0,0,255}),
          Text(
            extent={{-114,-63},{119,-103}},
            lineColor={0,0,0},
            textString="c_max=%c_max"),
          Line(
            points={{-100,0},{-58,0},{-43,-30},{-13,30},{17,-30},{47,30},{62,0},
                {100,0}},
            color={0,0,0},
            pattern=LinePattern.Solid,
            thickness=0.25,
            arrow={Arrow.None,Arrow.None}),
          Line(points={{-80,-60},{-60,-20},{60,20},{80,60}}, color={255,0,0})}),
      Diagram(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={1,1}), graphics={
          Line(points={{-68,0},{-68,65}}, color={128,128,128}),
          Line(points={{72,0},{72,65}}, color={128,128,128}),
          Line(points={{-68,60},{72,60}}, color={128,128,128}),
          Polygon(
            points={{62,63},{72,60},{62,57},{62,63}},
            lineColor={128,128,128},
            fillColor={128,128,128},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-52,64},{42,79}},
            lineColor={0,0,255},
            textString="phi_rel"),
          Line(points={{-96,0},{-60,0},{-42,-32},{-12,30},{18,-30},{48,28},{62,
                0},{96,0}})}));
  end NonlinearSpring;

  model Test1

    Aufgabe2.NonlinearSpring nonlinearSpring(
      c_max=5.84e5,
      tau_n=500,
      c_min=1.95e5,
      phi_rel(start=0))
                    annotation (Placement(transformation(extent={{20,0},{40,20}},
            rotation=0)));
    Modelica.Mechanics.Rotational.Components.Fixed fixed
                                              annotation (Placement(
          transformation(extent={{60,0},{80,20}}, rotation=0)));
    Modelica.Mechanics.Rotational.Sources.Torque torque(useSupport=true)
                                                annotation (Placement(
          transformation(extent={{-20,0},{0,20}}, rotation=0)));
    Modelica.Blocks.Sources.TimeTable timeTable(table=[0,0; 1,500; 2,-500])
      annotation (Placement(transformation(extent={{-60,0},{-40,20}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Fixed fixed1
                                               annotation (Placement(
          transformation(extent={{-20,-20},{0,0}}, rotation=0)));
  equation
    connect(torque.flange,   nonlinearSpring.flange_a) annotation (Line(points={{
            0,10},{20,10}}, color={0,0,0}));
    connect(timeTable.y,torque.tau)           annotation (Line(points={{-39,10},{
            -22,10}}, color={0,0,127}));
    connect(nonlinearSpring.flange_b,fixed.flange)
      annotation (Line(points={{40,10},{70,10}}, color={0,0,0}));
    connect(fixed1.flange,torque.support)    annotation (Line(
        points={{-10,-10},{-10,0}},
        color={0,0,0},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}})),
      experiment(StopTime=2),
      __Dymola_Commands(file="Plot tau = tau(phi_rel).mos"
          "Plot tau = tau(phi_rel)"));
  end Test1;

  model Test2
    parameter Modelica.SIunits.Angle phi0=0.0016;
    Modelica.Mechanics.Rotational.Components.Inertia inertia1(
                                                   J=5,
      a(fixed=false),
      phi(fixed=true, start=phi0),
      w(fixed=true, start=0))                           annotation (Placement(
          transformation(extent={{-40,20},{-20,40}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Spring spring1(
                                                 c=5.84e5) annotation (Placement(
          transformation(extent={{0,20},{20,40}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Fixed fixed1
                                               annotation (Placement(
          transformation(extent={{40,20},{60,40}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Inertia inertia2(
                                                   J=5,
      a(fixed=false),
      phi(fixed=true, start=phi0),
      w(fixed=true, start=0))                           annotation (Placement(
          transformation(extent={{-40,-20},{-20,0}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Spring spring2(
                                                 c=1.95e5) annotation (Placement(
          transformation(extent={{0,-20},{20,0}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Fixed fixed2
                                               annotation (Placement(
          transformation(extent={{40,-20},{60,0}}, rotation=0)));
    Aufgabe2.NonlinearSpring nonlinearSpring(
      tau_n=500,
      c_max=5.8e5,
      c_min=1.95e5) annotation (Placement(transformation(extent={{0,-60},{20,-40}},
            rotation=0)));
    Modelica.Mechanics.Rotational.Components.Inertia inertia3(
                                                   J=5,
      a(fixed=false),
      phi(fixed=true, start=phi0),
      w(fixed=true, start=0))
                   annotation (Placement(transformation(extent={{-40,-60},{-20,
              -40}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Fixed fixed3
                                               annotation (Placement(
          transformation(extent={{42,-60},{62,-40}}, rotation=0)));
  equation
    connect(inertia1.flange_b, spring1.flange_a) annotation (Line(points={{-20,30},
            {0,30}}, color={0,0,0}));
    connect(fixed1.flange,   spring1.flange_b) annotation (Line(points={{50,30},{
            20,30}}, color={0,0,0}));
    connect(nonlinearSpring.flange_a, inertia3.flange_b) annotation (Line(points=
            {{0,-50},{-20,-50}}, color={0,0,0}));
    connect(nonlinearSpring.flange_b,fixed3.flange)    annotation (Line(points={{
            20,-50},{52,-50}}, color={0,0,0}));
    connect(inertia2.flange_b, spring2.flange_a) annotation (Line(points={{-20,
            -10},{0,-10}}, color={0,0,0}));
    connect(fixed2.flange,   spring2.flange_b) annotation (Line(points={{50,-10},
            {20,-10}}, color={0,0,0}));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}), graphics),
      experiment(StopTime=0.1),
      __Dymola_Commands(file="Plot speeds.mos" "Plot speeds"));
  end Test2;
  annotation (uses(Modelica(version="3.2.1")));
end Aufgabe2;
