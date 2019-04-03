within ThermoSysPro.Properties.FlueGases;
function FlueGases_Absorb "Flue gases - particles emissivity"
  extends ThermoSysPro.Properties.FlueGases.unSafeForJacobian;
  input ThermoSysPro.Units.AbsolutePressure PC "CO2 partial pressure";
  input ThermoSysPro.Units.AbsolutePressure PW "H2O partial pressure";
  input Real FV "Volume concentration of the particles in the flue gases";
  input Modelica.SIunits.Length L "Optical path";
  input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
  output Real EG " ";
  output Real ES " ";
  output Real emigaz "Flue gases - particles emissivity";
algorithm
  (EG,ES,emigaz):=ThermoSysPro.Properties.FlueGases.Absorb(PC*1e-05, PW*1e-05, FV, L, T);
  annotation(smoothOrder=2, Icon, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end FlueGases_Absorb;
