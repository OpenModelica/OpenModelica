within ThermoSysPro.Properties.FlueGases;
function Absorb "Flue gases - particles emissivity"
  extends ThermoSysPro.Properties.FlueGases.unSafeForJacobian;
  input ThermoSysPro.Units.AbsolutePressure PC "CO2 partial pressure";
  input ThermoSysPro.Units.AbsolutePressure PW "H2O partial pressure";
  input Real FV "Volume concentration of the particules";
  input Modelica.SIunits.Length L "Optical path";
  input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
  output Real EG " ";
  output Real ES " ";
  output Real emigaz "Gas emissivity";

  external "FORTRAN" absorb(PC,PW,FV,L,T,EG,ES,emigaz) ;
  annotation(Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end Absorb;
