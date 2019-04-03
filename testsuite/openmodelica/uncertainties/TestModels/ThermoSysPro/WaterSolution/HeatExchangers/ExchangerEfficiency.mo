within ThermoSysPro.WaterSolution.HeatExchangers;
model ExchangerEfficiency "H2O/LiBr solution heat exchanger with prescribed efficiency"
  parameter Real Eff=0.9 "Thermal exchange efficiency (between 0 and 1 =W/Wmax)";
  parameter ThermoSysPro.Units.AbsolutePressure DPc=0 "Pressure loss in the hot fluid as a percent of the pressure at the inlet";
  parameter ThermoSysPro.Units.AbsolutePressure DPf=0 "Pressure loss in the cold fluid as a percent of the pressure at the inlet";
  Modelica.SIunits.Power W(start=1000000.0) "Power exchanged";
  ThermoSysPro.Units.AbsoluteTemperature Tec(start=500) "Hot fluid temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsc(start=400) "Hot fluid temperature at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tef(start=350) "Cold fluid temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsf(start=450) "Cold fluid temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hec(start=500000.0) "Hot fluid specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hsc(start=200000.0) "Hot fluid specific enthalpy at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hef(start=100000.0) "Cold fluid specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hsf(start=400000.0) "Cold fluid specific enthalpy at the outlet";
  Modelica.SIunits.Power Wmax(start=1000000.0) "Maximum exchangeable power";
  Modelica.SIunits.Power Wmaxf(start=1000000.0) "Maximum power acceptable by the cold fluid";
  Modelica.SIunits.Power Wmaxc(start=1000000.0) "Maximum power releasable by the hot fluid";
  ThermoSysPro.Units.SpecificEnthalpy Hmaxf(start=100000.0) "Maximum specific enthalpy reachable by the cold fluid";
  ThermoSysPro.Units.SpecificEnthalpy Hminc(start=100000.0) "Minimum specific enthalpy reachable by the hot fluid";
  Real Xc(start=0.5) "H2O mass fraction in the hot fluid";
  Real Xf(start=0.5) "H2O mass fraction in the cold fluid";
  Modelica.SIunits.MassFlowRate Qc(start=100) "Hot fluid mass flow rate";
  Modelica.SIunits.MassFlowRate Qf(start=100) "Cold fluid mass flow rate";
  ThermoSysPro.Units.SpecificEnthalpy Hliq(start=400000.0) "Liquid water specific enthalpy at the cold inlet";
  ThermoSysPro.Units.DifferentialTemperature DTc_ec(start=10) "Difference with the cristallisation temperature at the hot inlet";
  ThermoSysPro.Units.DifferentialTemperature DTc_sc(start=10) "Difference with the cristallisation temperature at the hot outlet";
  ThermoSysPro.Units.DifferentialTemperature DTc_ef(start=10) "Difference with the cristallisation temperature at the cold inlet";
  ThermoSysPro.Units.DifferentialTemperature DTc_sf(start=10) "Difference with the cristallisation temperature at the cold outlet";
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionInlet Ef annotation(Placement(transformation(x=-100.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionInlet Ec annotation(Placement(transformation(x=-58.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-58.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet Sc annotation(Placement(transformation(x=58.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=58.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet Sf annotation(Placement(transformation(x=100.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Ec.Q=Sc.Q;
  Ef.Q=Sf.Q;
  Qc=Ec.Q;
  Qf=Ef.Q;
  Ec.Xh2o=Sc.Xh2o;
  Ef.Xh2o=Sf.Xh2o;
  Xc=Ec.Xh2o;
  Xf=Ef.Xh2o;
  Hec=ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Tec, Xc);
  Hef=ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Tef, Xf);
  W=Qf*(Hsf - Hef);
  W=Qc*(Hec - Hsc);
  Hliq=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(100000.0, Tef, 1);
  Tec=Ec.T;
  Tsc=Sc.T;
  Tef=Ef.T;
  Tsf=Sf.T;
  DTc_ec=ThermoSysPro.Properties.WaterSolution.DTcristal_TX(Ec.T, Xc);
  DTc_sc=ThermoSysPro.Properties.WaterSolution.DTcristal_TX(Sc.T, Xc);
  DTc_ef=ThermoSysPro.Properties.WaterSolution.DTcristal_TX(Ef.T, Xf);
  DTc_sf=ThermoSysPro.Properties.WaterSolution.DTcristal_TX(Sf.T, Xf);
  Tsf=ThermoSysPro.Properties.WaterSolution.Temperature_hX(Hsf, Xf);
  Tsc=ThermoSysPro.Properties.WaterSolution.Temperature_hX(Hsc, Xc);
  Sc.P=if Qc > 0 then Ec.P - DPc*Ec.P/100 else Ec.P + DPc*Ec.P/100;
  Sf.P=if Qf > 0 then Ef.P - DPf*Ef.P/100 else Ef.P + DPf*Ef.P/100;
  Hmaxf=ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Tec, Xf);
  Wmaxf=Qf*(Hmaxf - Hef);
  Hminc=ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Tef, Xc);
  Wmaxc=Qc*(Hec - Hminc);
  Wmax=min(Wmaxf, Wmaxc);
  W=Eff*Wmax;
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillPattern=FillPattern.Solid, fillColor={223,159,159}),Line(points={{-56,-50},{-56,2},{2,2},{60,2},{60,-50}}, color={0,0,255}, thickness=0.5),Text(lineColor={0,0,255}, extent={{-50,66},{46,-2}}, fillColor={0,0,255}, textString="E"),Line(points={{-100,60},{100,-60}}, color={0,0,255})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillPattern=FillPattern.Solid, fillColor={223,159,159}),Line(points={{-58,-50},{-58,0},{0,0},{58,0},{58,-50}}, color={0,0,255}, thickness=0.5),Text(lineColor={0,0,255}, extent={{-50,66},{46,-2}}, fillColor={0,0,255}, textString="E"),Line(points={{-100,60},{100,-60}}, color={0,0,255})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Benoît Bride</li>
</html>
"));
end ExchangerEfficiency;
