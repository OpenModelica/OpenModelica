within ;
model Inverter2 "Simple inverter circuit"
//--------------------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------------------
  extends Modelica.Icons.Example;

  Modelica.Electrical.Spice3.Semiconductors.M_NMOS mn(modelcard(
      RD=0,
      RS=0,
      CBD=0,
      CBS=0))
    annotation (Placement(transformation(extent={{-14,-34},{6,-14}})));
  Modelica.Electrical.Spice3.Basic.Ground ground
    annotation (Placement(transformation(extent={{-14,-60},{6,-40}})));
  Modelica.Electrical.Spice3.Sources.V_pulse vin(
    V2=5,
    TD=4e-12,
    TR=0.1e-12,
    TF=0.1e-12,
    PW=1e-12,
    PER=2e-12) annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={-40,-16})));
equation
  connect(mn.S,mn. B)     annotation (Line(
      points={{-4,-34},{6,-34},{6,-24}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(mn.S, ground.p)   annotation (Line(
      points={{-4,-34},{-4,-40}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(vin.n, ground.p)     annotation (Line(
      points={{-40,-26},{-40,-40},{-4,-40}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(mn.D, vin.p) annotation (Line(
      points={{-4,-14},{-22,-14},{-22,-6},{-40,-6}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(mn.G, ground.p) annotation (Line(
      points={{-14,-24.1},{-28,-24.1},{-28,-28},{-40,-28},{-40,-40},{-4,-40}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation ( Diagram(
        coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
            100}}),     graphics),
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
            100,100}}), graphics),
    experiment(
      StopTime=1e-011,
      NumberOfIntervals=2000,
      Tolerance=1e-007),
    Documentation(info="<html>
<p>An inverter is an electrical circuit that consists of a PMOS and a NMOS transistor. Its task is to turn the input voltage from high potential to low potential or the other way round.</p>
<p>Simulate until 1.e-11 s. Display the input voltage Vin.p.v as well as the output voltage mp.S.v. It shows that the input voltage is inverted.</p>
</html>",
      revisions="<html>
<ul>
<li><i>March 2009 </i>by Kristin Majetta initially implemented</li>
</ul>
</html>"),
    uses(Modelica(version="3.2.1")));
end Inverter2;
