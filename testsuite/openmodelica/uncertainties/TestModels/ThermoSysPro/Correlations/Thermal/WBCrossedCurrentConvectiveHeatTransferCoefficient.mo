within ThermoSysPro.Correlations.Thermal;
function WBCrossedCurrentConvectiveHeatTransferCoefficient "Convective heat transfer coefficient for crossed current heat exchangers"
  input ThermoSysPro.Units.AbsoluteTemperature TFilm "Film temperature";
  input Modelica.SIunits.MassFlowRate Qf "Flue gases mass flow rate";
  input Real Xh2o "H2O mass fraction in the flue gases";
  input Modelica.SIunits.Area Sgaz "Geometrical parameter";
  input Modelica.SIunits.Diameter Dext "Pipes external diameter";
  input Real Fa "Pipes position coefficient";
  output Modelica.SIunits.CoefficientOfHeatTransfer Kcfc "Convective heat transfer coefficient for crossed current heat exchanger";
protected
  Real Dextb "Pipes external diameter in feet";
  Real Qfb "Flue gases mass flow rate in pound/hour";
  Real Sgazb "Sgaz in feet^2";
  Real TFilmb "Film temperature in Farenheit";
  constant Real TabUm[5]={0,5,10,15,20};
  constant Real TabTFilm[6]={0,600,1200,1800,2400,3000};
  constant Real TabFpp[5,6]=[0.0825,0.11,0.129,0.142,0.155,0.165;0.085,0.112,0.132,0.148,0.161,0.172;0.087,0.114,0.136,0.152,0.167,0.18;0.0885,0.117,0.139,0.158,0.173,0.1872;0.09,0.1183,0.1422,0.163,0.18,0.195];
  Real CondConv "Base convective conductance";
  Real MassFlow "Mass flow rate";
  Real Fpp "Physical properties factor";
  Real Kcb "Heat transfer coefficient in English units";
  Real Z1 "Unused variable returned by LinTab";
  Real Z2 "Unused variable returned by LinTab";
algorithm
  Dextb:=3.28084*Dext;
  Qfb:=2.20462*3600.0*Qf + 0.5;
  Sgazb:=10.7369*Sgaz;
  TFilmb:=9/5*TFilm - 459.69;
  MassFlow:=abs(Qfb)/Sgazb;
  CondConv:=0.287*MassFlow^0.61/Dextb^0.39;
  (Fpp,Z1,Z2):=ThermoSysPro.Functions.TableLinearInterpolation(TabUm, TabTFilm, TabFpp, Xh2o, TFilmb);
  Kcb:=CondConv*Fpp*Fa;
  Kcfc:=5.67826*Kcb;
  annotation(smoothOrder=2, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-100,52},{100,-88}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-82,8},{86,-40}}, textString="fonction", fillColor={255,127,0})}), Documentation(info="<html>
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
end WBCrossedCurrentConvectiveHeatTransferCoefficient;
