within ThermoSysPro.Correlations.Thermal;
function WBRadiativeHeatTransferCoefficient "Radiative heat transfer coefficient for the wall heat exchanger"
  input ThermoSysPro.Units.DifferentialTemperature DeltaT "Temperature difference between the flue gases and the walls";
  input ThermoSysPro.Units.AbsoluteTemperature Tp "Surface temperature";
  input Real Pph2o "H20 fraction";
  input Real Ppco2 "CO2 fraction";
  input Real Beaml "Geometrical parameter";
  output Modelica.SIunits.CoefficientOfHeatTransfer Kr "Radiative heat transgfer coefficient";
protected
  ThermoSysPro.Units.AbsolutePressure Pgaz "CO2+H2O partial pressure";
  Real Rap "H20/C02 partial pressure";
  Real Kprim "Interpolation result over TabKr";
  Real Ak "Interpolation result over TabK2";
  Real Pperl "Intermediate variable";
  constant Real TabDeltaT[20]={-1100,-1000,-900,-800,-700,-600,-500,-400,-300,-200,-100,0,100,200,400,600,800,1000,1400,1500};
  constant Real TabTp[4]={273.15,523.15,773.15,1366.483333};
  constant Real TabKr[4,20]=[0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,1.163,1.977,2.56,6.63,12.793,22.446,35.82,59.89,65.94;0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,1.72,2.15,6.98,10.23,14.54,25.586,37.216,49.08,61.06,84.9,90.714;0.0001,0.0001,0.0001,0.0001,0.0001,0.0001,1.63,1.977,2.56,8.47,12.38,30.59,36.64,42.22,54.08,65.128,76.76,88.39,110.48,116.3;0.0001,1.84,2.52,8.23,12.1,16.64,36.13,41.96,47.76,53.55,59.33,88.01,93.29,98.57,109.14,119.7,130.26,140.82,161.94,167.23];
  constant Real TabPl[6]={0.0,0.06,0.12,0.18,0.24,0.3};
  constant Real TabRap[4]={0.3,0.4,0.76,2.0};
  constant Real TabK2[4,6]=[0.13,0.372,0.517,0.626,0.725,0.815;0.13,0.38,0.545,0.675,0.792,0.882;0.13,0.392,0.592,0.75,0.875,0.985;0.13,0.429,0.67,0.862,1.027,1.1647];
  Real Z1 "Unused variable returned by LinTab";
  Real Z2 "Unused variable returned by LinTab";
  Real Z3 "Unused variable returned by LinTab";
  Real Z4 "Unused variable returned by LinTab";
algorithm
  Pgaz:=Ppco2 + Pph2o;
  Rap:=Pph2o/Ppco2;
  if Beaml <= 0 then
    Kr:=0;
  else
    (Kprim,Z1,Z2):=ThermoSysPro.Functions.TableLinearInterpolation(TabTp, TabDeltaT, TabKr, Tp, DeltaT);
    Pperl:=Pgaz*Beaml;
    (Ak,Z3,Z4):=ThermoSysPro.Functions.TableLinearInterpolation(TabRap, TabPl, TabK2, Rap, Pperl);
    Kr:=Kprim*Ak;
  end if;
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
end WBRadiativeHeatTransferCoefficient;
