model Inittest
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Text(visible=true, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-110}}, textString="%name")}),Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})));
  Modelica.Mechanics.Translational.SlidingMass slidingMass1(L=0.01,m=0.05) annotation(Placement(visible=true,transformation(x=-22.5,y=22.5,scale=0.075)));
  Modelica.Blocks.Sources.Sine sine1(amplitude=2.83e-05,freqHz=61) annotation(Placement(visible=true,transformation(x=-125.189,y=22.5,scale=0.075)));
  Modelica.Mechanics.Translational.SpringDamper springDamper1(s_rel0=0.01,c=7106,d=0.189,s_rel.start=0.015,s_rel.fixed=false) annotation(Placement(visible=true,transformation(x=-67.5,y=22.5,scale=0.075)));
  Modelica.Mechanics.Translational.Position position1(exact=true,f_crit=100) annotation(Placement(visible=true,transformation(x=-94.3203,y=22.5,scale=0.075)));

equation
  connect(springDamper1.flange_a,position1.flange_b) annotation(Line(visible=true,points={{-75.0278,22.7083},{-86.8789,22.7083}}));
  connect(sine1.y,position1.s_ref) annotation(Line(visible=true,points={{-117.196,22.7083},{-103.415,22.7083}}));
  connect(slidingMass1.flange_a,springDamper1.flange_b) annotation(Line(visible=true,points={{-30.1037,22.7083},{-60.145,22.7083}}));
end Inittest;


