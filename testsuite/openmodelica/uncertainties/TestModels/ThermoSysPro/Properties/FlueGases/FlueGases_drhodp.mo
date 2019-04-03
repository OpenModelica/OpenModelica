within ThermoSysPro.Properties.FlueGases;
function FlueGases_drhodp "Derivative of the density wrt. the pressure at constant specific enthalpy"
  input ThermoSysPro.Units.AbsolutePressure PMF "Flue gases average pressure";
  input ThermoSysPro.Units.AbsoluteTemperature TMF "Flue gases average temperature";
  input Real Xco2 "CO2 mass fraction";
  input Real Xh2o "H2O mass fraction";
  input Real Xo2 "O2 mass fraction";
  input Real Xso2 "SO2 mass fraction";
  output Modelica.SIunits.DerDensityByPressure drhodp "Derivative of the density wrt. the pressure at constant specific enthalpy";
protected
  ThermoSysPro.Properties.ModelicaMediaFlueGases.ThermodynamicState state;
  Modelica.SIunits.SpecificEntropy s "Flue gases specific entropy";
  Modelica.SIunits.Density rho "Flue gaases density";
  Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
  Modelica.SIunits.SpecificHeatCapacity R "gas constant";
  Real Xn2 "N2 mass fraction";
algorithm
  Xn2:=1 - Xco2 - Xh2o - Xo2 - Xso2;
  state:=ThermoSysPro.Properties.ModelicaMediaFlueGases.setState_pTX(PMF, TMF, {Xn2,Xo2,Xh2o,Xco2,Xso2});
  s:=ThermoSysPro.Properties.ModelicaMediaFlueGases.specificEntropy(state);
  rho:=ThermoSysPro.Properties.ModelicaMediaFlueGases.density(state);
  cp:=ThermoSysPro.Properties.ModelicaMediaFlueGases.specificHeatCapacityCp(state);
  R:=ThermoSysPro.Properties.ModelicaMediaFlueGases.gasConstant(state);
  drhodp:=rho*rho*R/(PMF*cp)*(1/rho + TMF/PMF*(cp - R));
  annotation(smoothOrder=2, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={graphics()}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
</html>"));
end FlueGases_drhodp;
