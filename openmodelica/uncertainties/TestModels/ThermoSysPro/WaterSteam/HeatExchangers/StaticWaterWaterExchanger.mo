within ThermoSysPro.WaterSteam.HeatExchangers;
model StaticWaterWaterExchanger "Static water/water heat exchanger"
  parameter Modelica.SIunits.ThermalConductivity lambdam=15.0 "Metal thermal conductivity";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer p_hc=6000 "Heat transfer coefficient for the hot side if not computed by the correlations";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer p_hf=3000 "Heat transfer coefficient for the cold side if not computed by the correlations";
  parameter Real p_Kc=100 "Pressure loss coefficient for the hot side if not computed by the correlations";
  parameter Real p_Kf=100 "Pressure loss coefficient for the cold side if not computed by the correlations";
  parameter Modelica.SIunits.Thickness emetal=0.0006 "Wall thickness";
  parameter Modelica.SIunits.Area Sp=2 "Plate area";
  parameter Real nbp=499 "Number of plates";
  parameter Real c1=1.12647 "Correction coefficient";
  parameter Modelica.SIunits.Density p_rhoc=0 "If > 0, fixed fluid density for the hot fluid";
  parameter Modelica.SIunits.Density p_rhof=0 "If > 0, fixed fluid density for the cold fluid";
  parameter Integer modec=0 "IF97 region for the hot fluid. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer modef=0 "IF97 region for the cold fluid. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer exchanger_type=1 "Exchanger type - 1: countercurrent. 2: cocurrent";
  parameter Integer heat_exchange_correlation=1 "Correlation for the computation of the heat exchange coefficient - 0: no correlation. 1: SRI correlations";
  parameter Integer pressure_loss_correlation=1 "Correlation for the computation of the pressure loss coefficient - 0: no correlation. 1: SRI correlations";
  Modelica.SIunits.Power W "Thermal power exchanged between the two sides";
  ThermoSysPro.Units.DifferentialPressure DPc "Pressure loss of the hot fluid";
  ThermoSysPro.Units.DifferentialPressure DPf "Pressure loss of the cold fluid";
  Modelica.SIunits.CoefficientOfHeatTransfer hc "Heat transfer coefficient of the hot fluid";
  Modelica.SIunits.CoefficientOfHeatTransfer hf "Heat transfer coefficient of the cold fluid";
  Modelica.SIunits.CoefficientOfHeatTransfer K "Global heat transfer coefficient";
  Modelica.SIunits.Area S "Heat exchange surface";
  ThermoSysPro.Units.AbsoluteTemperature Tec "Fluid temperature at the hot inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsc "Fluid temperature at the hot outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tef "Fluid temperature at the cold inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsf "Fluid temperature at the cold outlet";
  ThermoSysPro.Units.DifferentialTemperature DTm "Difference in average temperature";
  ThermoSysPro.Units.DifferentialTemperature DT1 "Temperature difference at the inlet of the exchanger";
  ThermoSysPro.Units.DifferentialTemperature DT2 "Temperature difference at the outlet of the exchanger";
  Real DT12 "DT1/DT2 (s.u.)";
  Modelica.SIunits.MassFlowRate Qc(start=500) "Mass flow rate of the hot fluid";
  Modelica.SIunits.MassFlowRate Qf(start=500) "Mass flow rate of the cold fluid";
  Real qmc;
  Real qmf;
  Real quc;
  Real quf;
  Real N;
  Modelica.SIunits.Density rhoc(start=998) "Hot fluid density";
  Modelica.SIunits.Density rhof(start=998) "Cold fluid density";
  Modelica.SIunits.DynamicViscosity muc(start=0.001) "Hot fluid dynamic viscosity";
  Modelica.SIunits.DynamicViscosity muf(start=0.001) "Cold fluid dynamic viscosity";
  Modelica.SIunits.ThermalConductivity lambdac(start=0.602698) "Hot fluid thermal conductivity";
  Modelica.SIunits.ThermalConductivity lambdaf(start=0.597928) "Cold fluid thermal conductivity";
  ThermoSysPro.Units.AbsoluteTemperature Tmc(start=290) "Hot fluid average temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tmf(start=290) "Cold fluid average temperature";
  ThermoSysPro.Units.AbsolutePressure Pmc(start=100000.0) "Hot fluid average pressure";
  ThermoSysPro.Units.AbsolutePressure Pmf(start=100000.0) "Cold fluid average pressure";
  ThermoSysPro.Units.SpecificEnthalpy Hmc(start=100000) "Hot fluid average specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hmf(start=100000) "Cold fluid average specific enthalpy";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(color={0,0,255}, points={{-80,60},{-80,-60}}),Line(color={0,0,255}, points={{80,60},{80,-60}}),Line(color={0,0,255}, points={{-80,0},{-60,0},{-40,20},{40,-20},{60,0},{80,0}})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(color={0,0,255}, points={{-80,60},{-80,-60}}),Line(color={0,0,255}, points={{80,60},{80,-60}}),Line(color={0,0,255}, points={{-80,0},{-60,0},{-40,20},{40,-20},{60,0},{80,0}})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
  Connectors.FluidInlet Ec annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ef annotation(Placement(transformation(x=-50.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-50.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Sf annotation(Placement(transformation(x=50.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=50.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Sc annotation(Placement(transformation(x=100.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proce annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph procs annotation(Placement(transformation(x=-10.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profe annotation(Placement(transformation(x=-50.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profs annotation(Placement(transformation(x=-10.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proc annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prof annotation(Placement(transformation(x=-90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Ec.Q=Sc.Q;
  Ef.Q=Sf.Q;
  Qc=Ec.Q;
  Qf=Ef.Q;
  Sc.P=if Qc > 0 then Ec.P - DPc else Ec.P + DPc;
  Sf.P=if Qf > 0 then Ef.P - DPf else Ef.P + DPf;
  0=if Qc > 0 then Ec.h - Ec.h_vol else Sc.h - Sc.h_vol;
  0=if Qf > 0 then Ef.h - Ef.h_vol else Sf.h - Sf.h_vol;
  K=hc*hf/(hc + hf + hc*hf*emetal/lambdam);
  W=K*S*DTm;
  if abs(Qc) > 0.001 then
    W=Qc*proc.cp*(Tec - Tsc);
  else
    Tec=Tsc;
  end if;
  if abs(Qf) > 0.001 then
    W=Qf*prof.cp*(Tsf - Tef);
  else
    Tef=Tsf;
  end if;
  if noEvent(DT1 > DT2 and DT2 > 0 or DT1 < DT2 and DT2 < 0) then
    DTm=(DT1 - DT2)/Modelica.Math.log(DT1/DT2);
  else
    DTm=(DT1 + DT2)/2;
  end if;
  if exchanger_type == 1 then
    DT1=Tec - Tsf;
    DT2=Tsc - Tef;
  elseif exchanger_type == 2 then
    DT1=Tec - Tef;
    DT2=Tsc - Tsf;
  else
    DT1=0;
    DT2=0;
    assert(false, "StaticWaterWaterExchanger: incorrect exchanger type");
  end if;
  DT12=if noEvent(abs(DT2) > Modelica.Constants.eps) then DT1/DT2 else 0;
  S=(nbp - 2)*Sp;
  N=(nbp - 1)/2;
  qmc=noEvent(abs(Qc)/(muc*N));
  qmf=noEvent(abs(Qf)/(muf*N));
  if heat_exchange_correlation == 0 then
    hc=p_hc;
    hf=p_hf;
  elseif heat_exchange_correlation == 1 then
    hc=noEvent(if qmc < 0.001 then 0 else 11.245*qmc^0.8*abs(muc*proc.cp/lambdac)^0.4*lambdac);
    hf=noEvent(if qmf < 0.001 then 0 else 11.245*qmf^0.8*abs(muf*prof.cp/lambdaf)^0.4*lambdaf);
  else
    hc=0;
    hf=0;
    assert(false, "StaticWaterWaterExchanger: incorrect heat exchange correlation number");
  end if;
  quc=noEvent(abs(Qc)/N);
  quf=noEvent(abs(Qf)/N);
  if pressure_loss_correlation == 0 then
    DPc=p_Kc*Qc^2/(2*rhoc);
    DPf=p_Kf*Qf^2/(2*rhof);
  elseif pressure_loss_correlation == 1 then
    DPc=noEvent(if qmc < 0.001 then 0 else c1*14423.2/rhoc*qmc^(-0.097)*quc^2*(1472.47 + 1.54*(N - 1)/2 + 104.97*qmc^(-0.25)));
    DPf=noEvent(if qmf < 0.001 then 0 else 14423.2/rhof*qmf^(-0.097)*quf^2*(1472.47 + 1.54*(N - 1)/2 + 104.97*qmf^(-0.25)));
  else
    DPc=0;
    DPf=0;
    assert(false, "StaticWaterWaterExchanger: incorrect pressure loss correlation number");
  end if;
  Pmc=(Ec.P + Sc.P)/2;
  Pmf=(Ef.P + Sf.P)/2;
  Hmc=(Ec.h + Sc.h)/2;
  Hmf=(Ef.h + Sf.h)/2;
  proc=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pmc, Hmc, modec);
  prof=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pmf, Hmf, modef);
  Tmc=proc.T;
  Tmf=prof.T;
  if p_rhoc > 0 then
    rhoc=p_rhoc;
  else
    rhoc=proc.d;
  end if;
  if p_rhof > 0 then
    rhof=p_rhof;
  else
    rhof=prof.d;
  end if;
  muc=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rhoc, Tmc);
  muf=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rhof, Tmf);
  lambdac=ThermoSysPro.Properties.WaterSteam.IF97.ThermalConductivity_rhoT(rhoc, Tmc, Pmc);
  lambdaf=ThermoSysPro.Properties.WaterSteam.IF97.ThermalConductivity_rhoT(rhof, Tmf, Pmf);
  proce=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ec.P, Ec.h, modec);
  procs=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sc.P, Sc.h, modec);
  profe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ef.P, Ef.h, modef);
  profs=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sf.P, Sf.h, modef);
  Tec=proce.T;
  Tsc=procs.T;
  Tef=profe.T;
  Tsf=profs.T;
end StaticWaterWaterExchanger;
