within ThermoSysPro.FlueGases.BoundaryConditions;
model Source "Flue gas source"
  parameter ThermoSysPro.Units.AbsoluteTemperature T0=400 "Source temperature";
  parameter Real Xco2=0.1 "CO2 mass fraction";
  parameter Real Xh2o=0.05 "H2O mass fraction";
  parameter Real Xo2=0.22 "O2 mass fraction";
  parameter Real Xso2=0.0 "SO2 mass fraction";
  ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  Real Xn2 "N2 mas fraction";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(color={0,0,255}, points={{40,0},{90,0},{72,10}}),Line(color={0,0,255}, points={{90,0},{72,-10}}),Text(lineColor={0,0,255}, extent={{-40,-40},{-2,-60}}, fillColor={0,0,255}, textString="T")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(color={0,0,255}, points={{40,0},{90,0},{72,10}}),Line(color={0,0,255}, points={{90,0},{72,-10}}),Text(lineColor={0,0,255}, extent={{-40,-40},{-2,-60}}, fillColor={0,0,255}, textString="T")}), Documentation(info="<html>
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
</ul>
</html>
"));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet C annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  InstrumentationAndControl.Connectors.InputReal ITemperature annotation(Placement(transformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0), iconTransformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0)));
equation
  C.P=P;
  C.Q=Q;
  C.T=T;
  C.Xco2=Xco2;
  C.Xh2o=Xh2o;
  C.Xo2=Xo2;
  C.Xso2=Xso2;
  Xn2=1 - Xco2 - Xh2o - Xo2 - Xso2;
  if cardinality(ITemperature) == 0 then
    ITemperature.signal=T0;
  end if;
  T=ITemperature.signal;
end Source;
