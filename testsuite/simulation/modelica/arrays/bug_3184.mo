within ;
model arrTest

  Modelica.Blocks.Sources.Sine sine annotation (Placement(transformation(extent=
           {{-94,40},{-74,60}}, rotation=0)));
  Modelica.Blocks.Sources.Sine sine1 annotation (Placement(transformation(
          extent={{-94,-16},{-74,4}}, rotation=0)));
  Modelica.Blocks.Continuous.Filter filter1[2](each order=2,
      each f_cut=1)
    annotation (Placement(transformation(extent={{-36,16},{-16,36}}, rotation=0)));
equation
  connect(filter1[1].u, sine.y) annotation (Line(
      points={{-38,26},{-56,26},{-56,50},{-73,50}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(sine1.y, filter1[2].u) annotation (Line(
      points={{-73,-6},{-56,-6},{-56,26},{-38,26}},
      color={0,0,127},
      smooth=Smooth.None));
  annotation (uses(Modelica(version="3.2.1")), Diagram(graphics),
    version="1",
    conversion(noneFromVersion=""));
end arrTest;
