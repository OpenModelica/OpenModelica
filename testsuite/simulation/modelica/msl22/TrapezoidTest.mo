model Trapezoidtest
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}),graphics={Text(visible=true, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-110}}, textString="%name")}),Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor1 annotation(Placement(visible=true,transformation(x=-7.5,y=22.5,scale=0.075,rotation=270)));
  Modelica.Electrical.Analog.Basic.Ground ground1 annotation(Placement(visible=true,transformation(x=-52.5,y=-3.96875,scale=0.075)));
  Modelica.Electrical.Analog.Sources.TrapezoidVoltage trapezoidVoltage1(rising=0.2,falling=0.2) annotation(Placement(visible=true,transformation(x=-52.5,y=22.5,scale=0.075,rotation=1350)));

equation
  connect(trapezoidVoltage1.n,ground1.p) annotation(Line(visible=true,points={{-52.5859,15.2135},{-52.5859,3.63802}}));
  connect(trapezoidVoltage1.p,resistor1.p) annotation(Line(visible=true,points={{-52.5859,30.0964},{-52.5859,37.5},{-7.5,37.5},{-7.60677,30.0964}}));
  connect(ground1.p,resistor1.n) annotation(Line(visible=true,points={{-52.5859,3.63802},{-52.5,7.5},{-7.5,7.5},{-7.60677,15.2135}}));
end Trapezoidtest;



