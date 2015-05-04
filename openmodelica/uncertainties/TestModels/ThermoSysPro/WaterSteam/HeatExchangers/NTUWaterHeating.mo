within ThermoSysPro.WaterSteam.HeatExchangers;
model NTUWaterHeating "NTU heat exchanger"
  parameter Real lambdaE=0 "Pressure loss coefficient on the water side";
  parameter Modelica.SIunits.Area SCondDes=3000 "Exchange surface for the condensation and deheating";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer KCond=1 "Heat transfer coefficient for the condensation";
  parameter Modelica.SIunits.Area SPurge=0 "Drain surface - if > 0: with drain cooler";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer KPurge=1 "Heat transfer coefficient for the drain cooler";
  parameter Integer mode_eeF=0 "IF97 region at the inlet of the water side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_seF=0 "IF97 region at the outlet of the water side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_evC=0 "IF97 region at the inlet of the vapor side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_mF=0 "IF97 region in the drain. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_epC=0 "IF97 region at the inlet of the drain. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_spC=0 "IF97 region at the outlet of the drain. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_flash=0 "IF97 region in the flash zone of the drain. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy HsateC(start=300000.0, min=0) "Saturation specific enthalpy of the water at the pressure of the vapor inlet";
  ThermoSysPro.Units.SpecificEnthalpy HsatvC(start=2500000.0, min=0) "Saturation specific enthalpy of the vapor at the pressure of the vapor inlet";
  Modelica.SIunits.Area SDes(start=0) "Heat exchange surface for deheating";
  ThermoSysPro.Units.SpecificEnthalpy HeiF(start=200000.0) "Fluid specific enthalpy after drain cooling";
  ThermoSysPro.Units.SpecificEnthalpy HDesF(start=200000.0) "Fluid specific enthalpy after deheating";
  ThermoSysPro.Units.AbsoluteTemperature TeiF(start=400, min=0) "Fluid temperature after drain cooling";
  ThermoSysPro.Units.AbsoluteTemperature TsatC(start=400, min=0) "Saturation temperature";
  Modelica.SIunits.Power W(start=1) "Total heat power transfered to the cooling water";
  Modelica.SIunits.Power Wdes(start=1) "Energy transfer during deheating";
  Modelica.SIunits.Power Wcond(start=1) "Energy transfer during condensation";
  Modelica.SIunits.Power Wflash(start=1) "Energy transfer during partial vaporisation in the drain";
  Modelica.SIunits.Power Wpurge(start=1) "Energy transfer during drain cooling";
  ThermoSysPro.Units.SpecificEnthalpy Hep(start=300000.0) "Mixing temperature of the drain and the condensate";
  Modelica.SIunits.Density rho(start=1000.0, min=0) "Average water density";
  annotation(Icon(coordinateSystem(scale=0.01, extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-100,-30},{-36,32}}, lineColor={0,0,0}, lineThickness=0.5, fillColor={127,255,127}, fillPattern=FillPattern.Solid),Ellipse(extent={{38,-30},{102,32}}, lineColor={0,0,0}, lineThickness=0.5, fillColor={127,255,127}, fillPattern=FillPattern.Solid),Rectangle(extent={{-68,32},{72,-30}}, lineColor={127,255,127}, lineThickness=0.5, fillColor={127,255,127}, fillPattern=FillPattern.Solid),Line(points={{-70,32},{74,32},{74,32}}, color={0,0,0}, thickness=0.5),Line(points={{-70,-30},{74,-30},{74,-30}}, color={0,0,0}, thickness=0.5),Line(points={{74,32},{74,-30}}, color={0,0,0}, thickness=0.5),Line(points={{74,0},{102,0}}, color={0,0,0}, thickness=0.5),Rectangle(extent={{-58,-14},{74,-16}}, lineColor={0,255,255}, lineThickness=1.0, fillColor={0,255,255}, fillPattern=FillPattern.Solid),Rectangle(extent={{-58,16},{74,14}}, lineColor={0,255,255}, lineThickness=1.0, fillColor={0,255,255}, fillPattern=FillPattern.Solid),Ellipse(extent={{-78,-16},{-44,16}}, lineColor={0,255,255}, lineThickness=1.0, fillColor={0,255,255}, fillPattern=FillPattern.Solid),Ellipse(extent={{-76,-14},{-48,14}}, fillPattern=FillPattern.Solid, lineColor={0,255,0}, lineThickness=1.0, fillColor={127,255,127}),Rectangle(extent={{-62,14},{72,-14}}, lineColor={127,255,127}, fillColor={127,255,127}, fillPattern=FillPattern.Solid),Line(points={{-94,-12},{74,-12}}, color={0,0,255}, pattern=LinePattern.Dash),Line(points={{-94,-18},{74,-18}}, color={0,0,255}, pattern=LinePattern.Dash),Line(points={{-86,-24},{74,-24}}, color={0,0,255}, pattern=LinePattern.Dash)}), Diagram(coordinateSystem(scale=0.01, extent={{-100,-100},{100,100}}), graphics={Line(points={{-40,-40},{20,-24}}, color={0,0,255}, thickness=0.5, arrow={Arrow.None,Arrow.Filled}),Line(points={{-40,-20},{-20,0}}, color={255,0,0}, thickness=0.5),Line(points={{-20,0},{20,0}}, color={255,0,0}, thickness=0.5),Line(points={{60,0},{80,20}}, color={255,0,0}, thickness=0.5),Text(lineColor={0,0,255}, extent={{76,28},{84,20}}, fillColor={255,0,0}, lineThickness=0.5, textString="1C"),Text(lineColor={0,0,255}, extent={{56,10},{64,2}}, fillColor={255,0,0}, lineThickness=0.5, textString="2C"),Text(lineColor={0,0,255}, extent={{-24,8},{-16,0}}, fillColor={255,0,0}, lineThickness=0.5, textString="3C"),Text(lineColor={0,0,255}, extent={{-44,-10},{-36,-18}}, fillColor={255,0,0}, lineThickness=0.5, textString="4C"),Text(lineColor={0,0,255}, extent={{76,-10},{82,-16}}, fillColor={0,0,255}, lineThickness=0.5, textString="1F"),Text(lineColor={0,0,255}, extent={{58,-18},{64,-24}}, fillColor={0,0,255}, lineThickness=0.5, textString="2F"),Text(lineColor={0,0,255}, extent={{-22,-38},{-16,-44}}, fillColor={0,0,255}, lineThickness=0.5, textString="3F"),Text(lineColor={0,0,255}, extent={{-42,-44},{-36,-50}}, fillColor={0,0,255}, lineThickness=0.5, textString="4F"),Line(points={{20,0},{60,0}}, color={255,0,0}, thickness=0.5, arrow={Arrow.Filled,Arrow.None}),Line(points={{20,-24},{80,-8}}, color={0,0,255}, thickness=0.5),Text(lineColor={0,0,255}, extent={{-40,8},{-24,2}}, fillColor={0,0,255}, lineThickness=0.5, textString="Drain"),Text(lineColor={0,0,255}, extent={{66,-18},{82,-24}}, fillColor={0,0,255}, lineThickness=0.5, textString="Deheating"),Text(lineColor={0,0,255}, extent={{-36,-18},{-16,-24}}, fillColor={0,0,255}, lineThickness=0.5, textString="Drain cooling"),Line(points={{-26,4},{-22,0}}, color={0,0,0}, thickness=0.5, arrow={Arrow.None,Arrow.Filled}),Line(points={{-40,-20},{-40,-40}}, color={0,0,0}, pattern=LinePattern.Dot),Line(points={{-20,0},{-20,-34}}, color={0,0,0}, pattern=LinePattern.Dot),Line(points={{60,0},{60,-14}}, color={0,0,0}, pattern=LinePattern.Dot),Line(points={{80,20},{80,-8}}, color={0,0,0}, pattern=LinePattern.Dot),Text(lineColor={0,0,255}, extent={{48,50},{74,44}}, fillColor={0,0,255}, textString="Vapor inlet"),Text(lineColor={0,0,255}, extent={{-74,52},{-48,46}}, fillColor={0,0,255}, textString="Drain inlet"),Text(lineColor={0,0,255}, extent={{-74,-16},{-48,-22}}, fillColor={0,0,255}, textString="Drain outlet"),Text(lineColor={0,0,255}, extent={{-114,18},{-88,12}}, fillColor={0,0,255}, textString="Water inlet"),Text(lineColor={0,0,255}, extent={{86,18},{112,12}}, fillColor={0,0,255}, textString="Water outlet"),Text(lineColor={0,0,255}, extent={{12,-10},{34,-18}}, fillColor={0,0,255}, lineThickness=0.5, textString="Condensation"),Text(lineColor={0,0,255}, extent={{-26,-4},{-12,-8}}, fillColor={0,0,255}, lineThickness=0.5, textString="Flash")}), Documentation(info="<html>
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
"), DymolaStoredErrors);
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proeeF "Water inlet fluid properties (4F)" annotation(Placement(transformation(x=-90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proseF "Water outlet fluid properties (1F)" annotation(Placement(transformation(x=-60.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prospC "Drain outlet fluid properties (4C)" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ee(h_vol(start=200000.0)) "Water inlet" annotation(Placement(transformation(x=-102.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false), iconTransformation(x=-102.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  Connectors.FluidOutlet Se "Water outlet" annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  Connectors.FluidInlet Ep(h_vol(start=200000.0)) "Drain inlet" annotation(Placement(transformation(x=-60.0, y=34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false), iconTransformation(x=-60.0, y=34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  Connectors.FluidOutlet Sp "Drain outlet" annotation(Placement(transformation(x=-60.0, y=-33.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false), iconTransformation(x=-60.0, y=-33.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  Connectors.FluidInlet Ev(h_vol(start=200000.0)) "Vapor inlet" annotation(Placement(transformation(x=60.0, y=32.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false), iconTransformation(x=60.0, y=32.0, scale=0.1, aspectRatio=1.0, flipHorizontal=true, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proevC "Vapor inlet fluid properties (1C)" annotation(Placement(transformation(x=-60.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsatC "Saturation conditions for the liquid phase" annotation(Placement(transformation(x=20.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsatC "Saturation conditions for the vapor phase" annotation(Placement(transformation(x=-20.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph promeF "Average water fluid properties (between 4F and 3F)" annotation(Placement(transformation(x=-30.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prodesmC "Deheating average fluid properties (between 1C and 2C)" annotation(Placement(transformation(x=60.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph promcF "Average deheating fluid properties (between 3F and 2F)" annotation(Placement(transformation(x=60.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prodesF "Deheating inlet fluid properties (2F)" annotation(Placement(transformation(x=0.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prodesmF "Average deheating fluid properties (between 2F and 1F)" annotation(Placement(transformation(x=30.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prosp "Drain outlet fluid properties before cooling (near 3C)" annotation(Placement(transformation(x=-30.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prompC "Average fluid properties in the drain (between 3C and 4C)" annotation(Placement(transformation(x=30.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prompF "Average water fluid properties (between 4F and 3F)" annotation(Placement(transformation(x=-90.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proecF "Water fluid properties (3F)" annotation(Placement(transformation(x=90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph flashepC "Flash fluid properties (near 4C)" annotation(Placement(transformation(x=90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=1.0 "Small number for pressure loss equation";
equation
  if cardinality(Ep) == 0 then
    Ep.Q=1e-06;
    Ep.h=100000.0;
    Ep.P=100000.0;
    Ep.b=true;
  end if;
  0=if noEvent(Ee.Q > 0) then Ee.h - Ee.h_vol else Se.h - Se.h_vol;
  Se.Q=Ee.Q;
  Ee.P - Se.P=lambdaE*ThermoSysPro.Functions.ThermoSquare(Ee.Q, eps)/rho;
  W=Se.Q*(Se.h - Ee.h);
  P=Ev.P;
  P=Sp.P;
  Sp.h_vol=h;
  Ev.h_vol=h;
  Ep.h_vol=h;
  Sp.Q=Ev.Q + Ep.Q;
  if noEvent(HsatvC < Ev.h) then
    Wdes=Ev.Q*(Ev.h - HsatvC);
    Wdes=Ee.Q*(Se.h - HDesF);
    Wdes=noEvent(min(Ev.Q*prodesmC.cp, Ee.Q*prodesmF.cp)*ThermoSysPro.Correlations.Thermal.WBHeatExchangerEfficiency(Ev.Q, Ee.Q, prodesmC.cp, prodesmF.cp, KCond/2, SDes, 1)*(proevC.T - prodesF.T));
  else
    Wdes=1e-09;
    HDesF=Se.h;
    SDes=1e-09;
  end if;
  if noEvent(Ev.h < HsatvC) then
    Wcond=Ev.Q*(Ev.h - HsateC) + Wflash;
  else
    Wcond=Ev.Q*(HsatvC - HsateC) + Wflash;
  end if;
  Wcond=Ee.Q*(HDesF - HeiF);
  Wcond=Ee.Q*promcF.cp*ThermoSysPro.Correlations.Thermal.WBHeatExchangerEfficiency(Ev.Q, Ee.Q, 1e+20, promcF.cp, KCond, SCondDes - SDes, 0.5)*(TsatC - TeiF);
  if flashepC.x > 0 then
    Wflash=Ep.Q*(Ep.h - HsateC);
  else
    Wflash=0;
  end if;
  if flashepC.x > 0 then
    Hep=HsateC;
  else
    Sp.Q*Hep=HsateC*Ev.Q + Ep.h*Ep.Q;
  end if;
  if noEvent(SPurge > 0) then
    Wpurge=Sp.Q*(Hep - Sp.h);
    Wpurge=Ee.Q*(HeiF - Ee.h);
    Wpurge=noEvent(min(Sp.Q*prompC.cp, Ee.Q*prompF.cp)*ThermoSysPro.Correlations.Thermal.WBHeatExchangerEfficiency(Sp.Q, Ee.Q, prompC.cp, prompF.cp, KPurge, SPurge, 0)*(prosp.T - proeeF.T));
    TeiF=proecF.T;
  else
    HeiF=Ee.h;
    Wpurge=0;
    Hep=Sp.h;
    TeiF=proeeF.T;
  end if;
  proeeF=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ee.P, Ee.h, mode_eeF);
  proseF=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Se.P, Se.h, mode_seF);
  promeF=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Ee.P + Se.P)/2, (Ee.h + Se.h)/2, mode_eeF);
  proevC=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ev.P, Ev.h, mode_evC);
  prospC=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sp.P, Sp.h, mode_spC);
  prosp=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ev.P, Hep, mode_spC);
  prodesF=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Se.P, HDesF, mode_seF);
  prompC=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ev.P, (Hep + Sp.h)/2, mode_spC);
  prodesmC=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ev.P, (vsatC.h + Ev.h)/2, mode_evC);
  prompF=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ee.P, (Ee.h + HeiF)/2, mode_eeF);
  promcF=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Ee.P + Se.P)/2, (HeiF + HDesF)/2, mode_mF);
  prodesmF=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Se.P, (HDesF + Se.h)/2, mode_seF);
  proecF=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ee.P, HeiF, mode_eeF);
  flashepC=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ev.P, Ep.h, mode_flash);
  rho=promeF.d;
  (lsatC,vsatC)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(Ev.P);
  TsatC=lsatC.T;
  HsateC=lsatC.h;
  HsatvC=vsatC.h;
end NTUWaterHeating;
