within ThermoSysPro.FlueGases.HeatExchangers;
model StaticFluegasesFluegasesExchangerKS "Static flue gases/flue gases heat exchanger with fixed K and S"
  parameter Modelica.SIunits.CoefficientOfHeatTransfer K=100 "Global heat exchange coefficient";
  parameter Modelica.SIunits.Area S=10 "Heat exchange surface";
  parameter ThermoSysPro.Units.DifferentialPressure DPc "Pressure losses in the hot fluid as a percent of the pressure at the inlet";
  parameter ThermoSysPro.Units.DifferentialPressure DPf "Pressure losses in the cold fluid as a percent of the pressure at the inlet";
  Modelica.SIunits.Power W "Power exchanged";
  ThermoSysPro.Units.AbsoluteTemperature Tec(start=400) "Temperature of the hot fluid at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsc(start=300) "Temperature of the hot fluid at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tef(start=300) "Temperature of the cold fluid at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsf(start=400) "Temperature of the cold fluid at the outlet";
  ThermoSysPro.Units.DifferentialTemperature DT1 "Delta T at the inlet";
  ThermoSysPro.Units.DifferentialTemperature DT2 "Delta T at the outlet";
  Modelica.SIunits.SpecificHeatCapacity Cpf "Specific heat capacity of the cold fluid";
  Modelica.SIunits.SpecificHeatCapacity Cpc "Specific heat capacity of the hot fluid";
  Modelica.SIunits.MassFlowRate Qc(start=100) "Mass flow rate of the hot fluid";
  Modelica.SIunits.MassFlowRate Qf(start=100) "Mass flow rate of the cold fluid";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(points={{-60,-50},{-60,30},{0,-14},{60,30},{60,-50}}, color={0,0,255}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(points={{-60,-50},{-60,30},{0,-14},{60,30},{60,-50}}, color={0,0,255}, thickness=0.5)}), Documentation(info="<html>
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
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Sc annotation(Placement(transformation(x=60.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=60.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Ec annotation(Placement(transformation(x=-60.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-60.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Ef annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Sf annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Tec=Ec.T;
  Tsc=Sc.T;
  Tef=Ef.T;
  Tsf=Sf.T;
  Qc=Ec.Q;
  Qf=Ef.Q;
  Sc.Q=Ec.Q;
  Sf.Q=Ef.Q;
  Sc.Xco2=Ec.Xco2;
  Sc.Xh2o=Ec.Xh2o;
  Sc.Xo2=Ec.Xo2;
  Sc.Xso2=Ec.Xso2;
  Sf.Xco2=Ef.Xco2;
  Sf.Xh2o=Ef.Xh2o;
  Sf.Xo2=Ef.Xo2;
  Sf.Xso2=Ef.Xso2;
  Sc.P=if Qc > 0 then Ec.P - DPc*Ec.P/100 else Ec.P + DPc*Ec.P/100;
  Sf.P=if Qf > 0 then Ef.P - DPf*Ef.P/100 else Ef.P + DPf*Ef.P/100;
  DT1=Tec - Tsf;
  DT2=Tsc - Tef;
  DT2=DT1*Modelica.Math.exp(-K*S*(1/(Qc*Cpc) - 1/(Qf*Cpf)));
  W=Qc*Cpc*(Tec - Tsc);
  W=Qf*Cpf*(Tsf - Tef);
  Cpf=ThermoSysPro.Properties.FlueGases.FlueGases_cp(Ef.P, (Tef + Tsf)/2, Ef.Xco2, Ef.Xh2o, Ef.Xo2, Ef.Xso2);
  Cpc=ThermoSysPro.Properties.FlueGases.FlueGases_cp(Ec.P, (Tec + Tsc)/2, Ec.Xco2, Ec.Xh2o, Ec.Xo2, Ec.Xso2);
end StaticFluegasesFluegasesExchangerKS;
