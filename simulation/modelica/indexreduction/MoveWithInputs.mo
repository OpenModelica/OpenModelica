within ;
package MoveWithInputs
  model test
    Modelica.Mechanics.Translational.Sources.Move move
      annotation (Placement(transformation(extent={{34,20},{54,40}})));
    Modelica.Mechanics.Translational.Components.Mass mass(m=1)
      annotation (Placement(transformation(extent={{72,20},{92,40}})));
    Modelica.Blocks.Routing.Multiplex3 multiplex3_1(
      n1=1,
      n2=1,
      n3=1) annotation (Placement(transformation(extent={{-4,20},{16,40}})));
    Modelica.Blocks.Interfaces.RealInput u
      annotation (Placement(transformation(extent={{-114,56},{-74,96}})));
    Modelica.Blocks.Interfaces.RealInput u1
      annotation (Placement(transformation(extent={{-114,-22},{-74,18}})));
    Modelica.Blocks.Interfaces.RealInput u2
      annotation (Placement(transformation(extent={{-116,12},{-76,52}})));
    Modelica.Blocks.Math.Gain
          gain(k=5)
      annotation (Placement(transformation(extent={{-48,66},{-28,86}})));
    Modelica.Blocks.Math.Gain
          gain1(
               k=5)
      annotation (Placement(transformation(extent={{-52,34},{-32,54}})));
    Modelica.Blocks.Math.Gain
          gain2(
               k=5)
      annotation (Placement(transformation(extent={{-58,-14},{-38,6}})));
  equation
    connect(move.flange, mass.flange_a) annotation (Line(
        points={{54,30},{72,30}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(multiplex3_1.y, move.u) annotation (Line(
        points={{17,30},{32,30}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(u, gain.u) annotation (Line(
        points={{-94,76},{-70,76},{-70,78},{-60,78},{-60,76},{-50,76}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(gain.y, multiplex3_1.u1[1]) annotation (Line(
        points={{-27,76},{-16,76},{-16,37},{-6,37}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(gain1.u, u2) annotation (Line(
        points={{-54,44},{-66,44},{-66,32},{-96,32}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(gain1.y, multiplex3_1.u2[1]) annotation (Line(
        points={{-31,44},{-20,44},{-20,30},{-6,30}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(u1, gain2.u) annotation (Line(
        points={{-94,-2},{-74,-2},{-74,-4},{-60,-4}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(gain2.y, multiplex3_1.u3[1]) annotation (Line(
        points={{-37,-4},{-22,-4},{-22,23},{-6,23}},
        color={0,0,127},
        smooth=Smooth.None));
    annotation (                                 Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
  end test;



  annotation (uses(Modelica(version="3.2.1")));
end MoveWithInputs;
