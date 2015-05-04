within ThermoSysPro.ElectroMechanics.BoundaryConditions;
model SourceMechanicalPower "Mechanical power source"
  parameter Modelica.SIunits.Power W0=150000;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{-20,20},{20,-20}}, fillColor={0,0,255}, textString="W"),Line(points={{40,0},{100,0}}, color={0,0,255}),Line(points={{100,0},{80,-20}}, color={0,0,255}),Line(points={{100,0},{80,20}}, color={0,0,255})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{-20,20},{20,-20}}, fillColor={0,0,255}, textString="W"),Line(points={{40,0},{100,0}}, color={0,0,255}),Line(points={{100,0},{80,-20}}, color={0,0,255}),Line(points={{100,0},{80,20}}, color={0,0,255})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
  ThermoSysPro.ElectroMechanics.Connectors.MechanichalTorque M annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-180.0), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false, rotation=-180.0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPower annotation(Placement(transformation(x=-50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(IPower) == 0 then
    IPower.signal=W0;
  end if;
  M.Ctr*abs(M.w)=IPower.signal;
end SourceMechanicalPower;
