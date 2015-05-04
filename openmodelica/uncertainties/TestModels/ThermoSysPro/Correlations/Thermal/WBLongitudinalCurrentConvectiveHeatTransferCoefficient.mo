within ThermoSysPro.Correlations.Thermal;
function WBLongitudinalCurrentConvectiveHeatTransferCoefficient "Convective heat transfer coefficient for co- or counter-current heat exchangers"
  input ThermoSysPro.Units.AbsoluteTemperature TFilm "Film temperature";
  input ThermoSysPro.Units.AbsoluteTemperature Tmf "Flue gases average temperature";
  input Modelica.SIunits.MassFlowRate Qf "Flue gases mass flow rate";
  input Real Xh2o "H2O mass fraction";
  input Modelica.SIunits.Area Sgaz "Geometrical parameter";
  input Modelica.SIunits.Diameter Dext "Pipes external diameter";
  output Modelica.SIunits.CoefficientOfHeatTransfer Kcfl "Convective heat transfer coefficient for longitudinal flows";
protected
  Real Dextb "Pipes external diameter in feet";
  Real Qfb "Flue gases mass flow rate in pound/hour";
  Real Sgazb "Geometrical parameter Sgaz in feet^2";
  Real TFilmb "Film temperature in Farenheit";
  Real Tmfb "Température moyenne des fumées en °F";
  constant Real TabUm[5]={0,5,10,15,20};
  constant Real TabTFilm[12]={0,200,400,600,800,1000,1200,1400,1600,2000,2400,2800};
  constant Real TabFpp[5,12]=[0.152,0.166,0.18,0.19,0.198,0.205,0.212,0.217,0.221,0.229,0.236,0.242;0.158,0.171,0.184,0.195,0.204,0.211,0.218,0.222,0.228,0.236,0.244,0.251;0.163,0.176,0.189,0.2,0.209,0.216,0.224,0.229,0.234,0.244,0.252,0.26;0.17,0.183,0.194,0.205,0.214,0.222,0.229,0.237,0.24,0.25,0.26,0.268;0.178,0.189,0.2,0.211,0.22,0.228,0.234,0.241,0.247,0.256,0.266,0.275];
  Real CondConv "Base convective conductance";
  Real MassFlow "Mass flow rate";
  Real Fpp "Physical properties factor";
  Real FT "Temperature factor";
  Real Kcb "Heat transfer coefficient in English units";
  Real Z1 "Unused variable returned by LinTab";
  Real Z2 "Unused variable returned by LinTab";
algorithm
  Dextb:=3.28084*Dext;
  Qfb:=2.20462*3600*Qf;
  Sgazb:=10.7369*Sgaz;
  Tmfb:=9.0/5.0*Tmf - 459.69;
  TFilmb:=9.0/5.0*TFilm - 459.69;
  MassFlow:=abs(Qfb)/Sgazb;
  CondConv:=0.023*MassFlow^0.6/Dextb^0.2;
  (Fpp,Z1,Z2):=ThermoSysPro.Functions.TableLinearInterpolation(TabUm, TabTFilm, TabFpp, Xh2o, TFilmb);
  FT:=(Tmfb/TFilmb)^0.8;
  Kcb:=CondConv*Fpp*FT;
  Kcfl:=5.67826*Kcb;
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
end WBLongitudinalCurrentConvectiveHeatTransferCoefficient;
