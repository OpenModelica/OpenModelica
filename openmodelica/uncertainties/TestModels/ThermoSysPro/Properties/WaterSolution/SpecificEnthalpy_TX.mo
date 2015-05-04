within ThermoSysPro.Properties.WaterSolution;
function SpecificEnthalpy_TX "Specific enthalpy of the H2O/LiBr solution as a function of T and Xh2o"
  input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
  input Real X "Water mass fraction in the solution";
  output ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy of the solution";
protected
  Real C1;
  Real C2;
  Real C3;
  Real C4;
  Real C5;
  Real DXi;
  Real Xi "LiBr mass fraction in the solution";
  ThermoSysPro.Units.AbsoluteTemperature Tc "Temperature in Celsius";
  ThermoSysPro.Units.SpecificEnthalpy H1 "Liquid LiBr specific enthalpy on the saturation line";
  ThermoSysPro.Units.SpecificEnthalpy Hliq "Liquid H2O specific enthalpy on the saturation line";
  ThermoSysPro.Units.SpecificEnthalpy Dh "Difference in specific enthalpy wrt. ideal mixing";
algorithm
  Hliq:=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(1500000.0, T, 1);
  Tc:=T - 273.15;
  Xi:=1 - X;
  DXi:=2*Xi - 1;
  H1:=508.6682481 - 18.62407335*Tc + 0.09859458321*Tc*Tc - 2.509791095e-05*Tc*Tc*Tc + 4.15800771e-08*Tc*Tc*Tc*Tc;
  C1:=-1021.608631 + 36.87726426*Tc - 0.18605141*Tc*Tc - 7.512766773e-06*Tc*Tc*Tc;
  C2:=-533.308211 + 40.28472553*Tc - 0.1911981148*Tc*Tc;
  C3:=483.6280661 + 39.91418127*Tc - 0.1992131652*Tc*Tc;
  C4:=1155.132809 + 33.35722311*Tc - 0.1782584073*Tc*Tc;
  C5:=640.6219484 + 13.10318363*Tc - 0.07751011421*Tc*Tc;
  Dh:=(C1 + C2*DXi + C3*DXi*DXi + C4*DXi*DXi*DXi + C5*DXi*DXi*DXi*DXi)*Xi*(1 - Xi);
  h:=1000*(Xi*H1 + (1 - Xi)*Hliq/1000 + Dh);
  annotation(smoothOrder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end SpecificEnthalpy_TX;
