within ThermoSysPro.Properties.FlueGases;
function FlueGases_cp "Specific heat capacity"
  input ThermoSysPro.Units.AbsolutePressure PMF "Flue gases average pressure";
  input ThermoSysPro.Units.AbsoluteTemperature TMF "Flue gases average temperature";
  input Real Xco2 "CO2 mass fraction";
  input Real Xh2o "H2O mass fraction";
  input Real Xo2 "O2 mass fraction";
  input Real Xso2 "SO2 mass fraction";
  output Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
protected
  ThermoSysPro.Properties.ModelicaMediaFlueGases.ThermodynamicState state;
  Real Xn2 "N2 mass fraction";
algorithm
  Xn2:=1 - Xco2 - Xh2o - Xo2 - Xso2;
  state.p:=PMF;
  state.T:=TMF;
  state.X:={Xn2,Xo2,Xh2o,Xco2,Xso2};
  cp:=ThermoSysPro.Properties.ModelicaMediaFlueGases.specificHeatCapacityCp(state);
  annotation(smoothOrder=2, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-136,102},{140,42}}, textString="%name"),Ellipse(extent={{-100,40},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-84,-4},{84,-52}}, textString="function", fillColor={255,127,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end FlueGases_cp;
