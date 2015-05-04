within ThermoSysPro.Combustion.BoundaryConditions;
model FuelSourcePQ "Fuel source with fixed pressure and mass flow rate"
  parameter ThermoSysPro.Units.AbsolutePressure P0=100000.0 "Fuel presure";
  parameter Modelica.SIunits.MassFlowRate Q0=10 "Fuel mass flow rate";
  parameter ThermoSysPro.Units.AbsoluteTemperature T0=300 "Fuel temperature";
  parameter Modelica.SIunits.SpecificEnergy LHV=48000000.0 "Lower heating value";
  parameter Modelica.SIunits.SpecificHeatCapacity Cp=1000.0 "Fuel specific heat capacity at 273.15K";
  parameter Real Hum=0.0 "Fuel humidity (%)";
  parameter Real Xc=0.75 "C mass fraction";
  parameter Real Xh=0.25 "H mass fraction";
  parameter Real Xo=0 "O mass fraction";
  parameter Real Xn=0 "N mass fraction";
  parameter Real Xs=0 "S mass fraction";
  parameter Real Xashes=0 "Ashes mass fraction";
  parameter Real Vol=0 "Volatile matter mass fraction";
  parameter Modelica.SIunits.Density rho=0.72 "Fuel density";
  Connectors.FuelOutlet C annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IMassFlow annotation(Placement(transformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  InstrumentationAndControl.Connectors.InputReal IPressure annotation(Placement(transformation(x=-50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  C.hum=Hum;
  C.Xc=Xc;
  C.Xh=Xh;
  C.Xo=Xo;
  C.Xn=Xn;
  C.Xs=Xs;
  C.Xashes=Xashes;
  C.VolM=Vol;
  if cardinality(IMassFlow) == 0 then
    C.Q=Q0;
  end if;
  C.Q=IMassFlow.signal;
  C.T=T0;
  C.P=P0;
  C.LHV=LHV;
  C.cp=Cp;
  C.rho=rho;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{40,0},{90,0},{72,10}}),Line(color={0,0,255}, points={{90,0},{72,-10}}),Rectangle(extent={{-40,40},{40,-40}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.CrossDiag),Text(lineColor={0,0,255}, extent={{-30,60},{-12,40}}, textString="Q"),Text(lineColor={0,0,255}, extent={{-64,26},{-40,6}}, fillColor={0,0,255}, textString="P")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-38,60},{-4,40}}, fillColor={0,0,255}, textString="Q"),Rectangle(extent={{-40,40},{40,-40}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.CrossDiag),Line(color={0,0,255}, points={{40,0},{90,0},{72,10}}),Line(color={0,0,255}, points={{90,0},{72,-10}}),Text(lineColor={0,0,255}, extent={{-64,26},{-40,6}}, fillColor={0,0,255}, textString="P")}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end FuelSourcePQ;
