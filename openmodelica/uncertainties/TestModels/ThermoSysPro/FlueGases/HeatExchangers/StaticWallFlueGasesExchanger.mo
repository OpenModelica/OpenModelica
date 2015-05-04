within ThermoSysPro.FlueGases.HeatExchangers;
model StaticWallFlueGasesExchanger "Static wall/flue gases exchanger"
  parameter Integer Ns=1 "Number of segments";
  parameter Integer NbTub=100 "Number of pipes";
  parameter Real DPc=0 "Pressure loss coefficient";
  parameter Modelica.SIunits.Length L=2 "Exchanger length";
  parameter Modelica.SIunits.Diameter Dext=0.022 "External pipe diameter";
  parameter Modelica.SIunits.PathLength step_L=0.033 "Longitudinal length step";
  parameter Modelica.SIunits.PathLength step_T=0.066 "Transverse length step";
  parameter Modelica.SIunits.Area St=100 "Cross-sectional area";
  parameter Real Encras=1.0 "Heat exchange fouling coefficient";
  parameter Real Fa=0.7 "Fouling factor (0.3 - 1.1)";
  parameter Modelica.SIunits.MassFlowRate Qmin=0.001 "Minimum flue gases mass flow rate";
  parameter Integer exchanger_type=1 "Exchanger type - 1:crossed flux - 2:longitudinal flux";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tp0=500 "Wall temperature (active if the thermal connector is not connected)";
  parameter Real CSailettes=1 "Increase factor of the heat exchange surface to to the fins";
  parameter Real Coeff=1 "Corrective coeffeicient";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  Modelica.SIunits.Density rho(start=1) "Flue gases density";
  ThermoSysPro.Units.AbsoluteTemperature T[Ns + 1](start=fill(900, Ns + 1)) "Flue gases temperature at the inlet of section i";
  ThermoSysPro.Units.AbsoluteTemperature Tm[Ns](start=fill(900, Ns)) "Average flue gases temperature in section i";
  ThermoSysPro.Units.SpecificEnthalpy h[Ns + 1](start=fill(1000000.0, Ns + 1)) "Flue gases specific enthalpy at the inlet of section i";
  ThermoSysPro.Units.AbsoluteTemperature Tp[Ns](start=fill(500, Ns)) "Wall temperature";
  ThermoSysPro.Units.AbsolutePressure Pe(start=100000.0) "Flue gases partial pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Pco2 "CO2 partial pressure";
  ThermoSysPro.Units.AbsolutePressure Ph2o "H2O partial pressure";
  Real Xh2o "H2O mass fraction";
  Real Xco2 "CO2 mass fraction";
  Real Xn2 "N2 mass fraction";
  Real Xvh2o "H2O volume fraction";
  Real Xvco2 "CO2 volume fraction";
  Real Xvo2 "O2 volume fraction";
  Real Xvn2 "N2 volume fraction";
  Real Xvso2 "SO2 volume fraction";
  Modelica.SIunits.MassFlowRate Q(start=1) "Flue gases mass flow rate";
  Modelica.SIunits.CoefficientOfHeatTransfer K(start=0) "Total heat exchange coefficient";
  Modelica.SIunits.CoefficientOfHeatTransfer Kc(start=0) "Convective heat exchange coefficient";
  Modelica.SIunits.CoefficientOfHeatTransfer Kr(start=0) "Radiative heat exchange coefficient";
  Modelica.SIunits.CoefficientOfHeatTransfer Kcc[Ns](start=fill(0, Ns)) "Intermedaite variable for the computation of the convective heat exchange coefficient";
  Modelica.SIunits.CoefficientOfHeatTransfer Krr[Ns](start=fill(0, Ns)) "Intermedaite variable for the computation of the radiative heat exchange coefficient";
  Modelica.SIunits.Power dW[Ns](start=fill(0, Ns)) "Power exchange between the wall and the fluid in each section";
  Modelica.SIunits.Power W(start=0) "Total power exchanged";
  ThermoSysPro.Units.DifferentialTemperature DeltaT[Ns](start=fill(50, Ns)) "Temperature difference between the fluid and the wall";
  ThermoSysPro.Units.AbsoluteTemperature TFilm[Ns] "Film temperature";
  Real Mmt "Total flue gases molar mass";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,20},{100,-20}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(color={0,0,255}, points={{-60,20},{-60,-20}}),Line(color={0,0,255}, points={{-20,20},{-20,-20}}),Line(color={0,0,255}, points={{20,20},{20,-20}}),Line(color={0,0,255}, points={{60,20},{60,-20}})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,20},{100,-20}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(color={0,0,255}, points={{-60,20},{-60,-20}}),Line(color={0,0,255}, points={{-20,20},{-20,-20}}),Line(color={0,0,255}, points={{20,20},{20,-20}}),Line(color={0,0,255}, points={{60,20},{60,-20}})}), Documentation(revisions="<html>
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
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort CTh[Ns] annotation(Placement(transformation(x=0.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=0.1 "Small number for the computation of the pressure losses";
  constant Real Mco2=44.009 "CO2 molar mass";
  constant Real Mh2o=18.0148 "H2O molar mass";
  constant Real Mo2=31.998 "O2 molar mass";
  constant Real Mn2=28.014 "N2 molar mass";
  constant Real Mso2=64.063 "SO2 molar mass";
  constant Real pi=Modelica.Constants.pi;
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  parameter Modelica.SIunits.PathLength Ls=L/Ns "Section length";
  parameter Modelica.SIunits.Area Surf_ext=pi*Dext*Ls*NbTub*CSailettes "Heat exchange surface for one section";
  parameter Modelica.SIunits.Area Surf_tot=Ns*Surf_ext "Total heat exchange surface";
  parameter Modelica.SIunits.Area Sgaz=St*(1 - Dext/step_T) "Geometrical parameter";
  parameter Real PasLD=step_L/Dext "Geometrical parameter";
  parameter Real PasTD=step_T/Dext "Geometrical parameter";
  parameter Real Optl=ThermoSysPro.Correlations.Misc.WBCorrectiveDiameterCoefficient(PasTD, PasLD, Dext) "Geometrical parameter";
  parameter Modelica.SIunits.Length Deq=4*Sgaz/Perb "Equivalent diameter for longitudinal flux";
  parameter Modelica.SIunits.Length Perb=Surf_ext/Ls "Geometrical parameter";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer Kdef=50 "Heat exchange coefficient in case of zero flow";
equation
  CTh.W=-dW;
  CTh.T=Tp;
  C2.Q=C1.Q;
  Xh2o=C1.Xh2o;
  Xco2=C1.Xco2;
  T[1]=C1.T;
  T[Ns + 1]=C2.T;
  Pe=C1.P;
  Q=C1.Q;
  C2.Xco2=C1.Xco2;
  C2.Xh2o=C1.Xh2o;
  C2.Xo2=C1.Xo2;
  C2.Xso2=C1.Xso2;
  Xn2=1 - C1.Xco2 - C1.Xh2o - C1.Xo2 - C1.Xso2;
  Xvco2=C1.Xco2/Mco2/(C1.Xco2/Mco2 + C1.Xh2o/Mh2o + C1.Xo2/Mo2 + Xn2/Mn2 + C1.Xso2/Mso2);
  Xvh2o=C1.Xh2o/Mh2o/(C1.Xco2/Mco2 + C1.Xh2o/Mh2o + C1.Xo2/Mo2 + Xn2/Mn2 + C1.Xso2/Mso2);
  Xvo2=C1.Xo2/Mo2/(C1.Xco2/Mco2 + C1.Xh2o/Mh2o + C1.Xo2/Mo2 + Xn2/Mn2 + C1.Xso2/Mso2);
  Xvn2=Xn2/Mn2/(C1.Xco2/Mco2 + C1.Xh2o/Mh2o + C1.Xo2/Mo2 + Xn2/Mn2 + C1.Xso2/Mso2);
  Xvso2=C1.Xso2/Mso2/(C1.Xco2/Mco2 + C1.Xh2o/Mh2o + C1.Xo2/Mo2 + Xn2/Mn2 + C1.Xso2/Mso2);
  Mmt=Xvco2*Mco2 + Xvh2o*Mh2o + Xvo2*Mo2 + Xvn2*Mn2 + Xvso2*Mso2;
  Ph2o=Pe*Xh2o*Mmt/Mh2o;
  Pco2=Pe*Xco2*Mmt/Mco2;
  Pe - C2.P=DPc*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;
  h[1]=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pe, T[1], C1.Xco2, C1.Xh2o, C1.Xo2, C1.Xso2);
  for i in 1:Ns loop
    h[i + 1]=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pe, T[i + 1], C1.Xco2, C1.Xh2o, C1.Xo2, C1.Xso2);
    Tm[i]=0.5*(T[i] + T[i + 1]);
    0=noEvent(if abs(Q) < Qmin then Tm[i] - Tp[i] else Q*(h[i] - h[i + 1]) - 1/Coeff*K*(Tm[i] - Tp[i])*Surf_ext);
    DeltaT[i]=Tm[i] - Tp[i];
    if abs(Q) >= Qmin then
      if exchanger_type == 1 then
        Kcc[i]=ThermoSysPro.Correlations.Thermal.WBCrossedCurrentConvectiveHeatTransferCoefficient(TFilm[i], abs(Q), Xh2o*100, Sgaz, Dext, Fa);
      else
        Kcc[i]=ThermoSysPro.Correlations.Thermal.WBLongitudinalCurrentConvectiveHeatTransferCoefficient(TFilm[i], Tm[i], abs(Q), Xh2o*100, Sgaz, Deq);
      end if;
      Krr[i]=ThermoSysPro.Correlations.Thermal.WBRadiativeHeatTransferCoefficient(DeltaT[i], Tp[i], Ph2o/Pe, Pco2/Pe, Optl);
    else
      Krr[i]=0;
      Kcc[i]=0;
    end if;
    TFilm[i]=0.5*(Tm[i] + Tp[i]);
    dW[i]=K*(Tm[i] - Tp[i])*Surf_ext;
  end for;
  0=noEvent(if abs(Q) >= Qmin then K - (Kc + Kr)*Encras else K - Kdef);
  Kc=sum(Kcc)*Surf_ext/Surf_tot;
  Kr=sum(Krr)*Surf_ext/Surf_tot;
  W=sum(dW);
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pe, 0.5*(T[1] + T[Ns + 1]), C1.Xco2, C1.Xh2o, C1.Xo2, C1.Xso2);
  end if;
end StaticWallFlueGasesExchanger;
