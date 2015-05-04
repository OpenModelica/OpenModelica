within ThermoSysPro.Properties.FlueGases;
function EmissivGP "Flue gases - particles emissivity"
  extends ThermoSysPro.Properties.FlueGases.unSafeForJacobian;
  input Modelica.SIunits.Length AL "Equivalent length (radiation)";
  input ThermoSysPro.Units.AbsoluteTemperature TMF "Flue gases average temperature";
  input ThermoSysPro.Units.AbsoluteTemperature TPE "Wall temperature";
  input ThermoSysPro.Units.AbsolutePressure PMEL "Mixture pressure";
  input ThermoSysPro.Units.AbsolutePressure PH2O "H2O partial pressure";
  input ThermoSysPro.Units.AbsolutePressure PCO2 "PCO2 partial pressure";
  input Real FV "Volume concentration of the particles in the flue gases";
  input Modelica.SIunits.Length DP "Particles average diameter";
  input Real EPSPAR "Wall emissivity";
  output Real EPSFP "Particles/flue gases emissivity";

  external "FORTRAN" emg(AL,TMF,TPE,PMEL,PH2O,PCO2,FV,DP,EPSPAR,EPSFP) ;
  annotation(Coordsys(extent=[-100,-100;100,100], grid=[2,2], component=[20,20]), Window(x=0.22, y=0.22, width=0.44, height=0.65), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end EmissivGP;
