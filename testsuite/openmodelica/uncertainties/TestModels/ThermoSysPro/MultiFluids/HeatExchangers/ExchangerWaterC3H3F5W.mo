within ThermoSysPro.MultiFluids.HeatExchangers;
model ExchangerWaterC3H3F5W "Static water - C3H3F5 heat exchanger with fixed delta power"
  parameter Modelica.SIunits.Power DW=0 "Power exchanged between the hot and the cold fluids";
  parameter ThermoSysPro.Units.DifferentialPressure DPc "Total pressure loss for the hot fluid (% of the fluid pressure at the inlet)";
  parameter ThermoSysPro.Units.DifferentialPressure DPf "Total pressure loss for the cold fluid (% of the fluid pressure at the inlet)";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer modec=0 "IF97 region of the water for the hot fluid. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsoluteTemperature Tec "Fluid temperature at the inlet of the hot side";
  ThermoSysPro.Units.AbsoluteTemperature Tsc "Fluid temperature at the outlet of the hot side";
  ThermoSysPro.Units.AbsoluteTemperature Tef "Fluid temperature at the inlet of the cold side";
  ThermoSysPro.Units.AbsoluteTemperature Tsf "Fluid temperature at the outlet of the cold side";
  Modelica.SIunits.MassFlowRate Qc(start=100) "Hot fluid mass flow rate";
  Modelica.SIunits.MassFlowRate Qf(start=100) "Cold fluid mass flow rate";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillColor={255,255,0}, fillPattern=FillPattern.CrossDiag),Line(points={{-56,-50},{-56,4},{0,-28},{60,6},{60,-50}}, color={0,0,255}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillColor={255,255,0}, fillPattern=FillPattern.CrossDiag),Line(points={{-58,-50},{-58,2},{-2,-34},{58,2},{58,-50}}, color={0,0,255}, thickness=0.5)}), Documentation(info="<html>
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
  WaterSteam.Connectors.FluidInlet Ec annotation(Placement(transformation(x=-58.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-58.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  WaterSteam.Connectors.FluidInlet Ef annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  WaterSteam.Connectors.FluidOutlet Sf annotation(Placement(transformation(x=98.0, y=1.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=98.0, y=1.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  WaterSteam.Connectors.FluidOutlet Sc annotation(Placement(transformation(x=58.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=58.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proce annotation(Placement(transformation(x=-10.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph procs annotation(Placement(transformation(x=30.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profe annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profs annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
equation
  if continuous_flow_reversal then
    0=noEvent(if Qc > Qeps then Ec.h - Ec.h_vol else if Qc < -Qeps then Sc.h - Sc.h_vol else Ec.h - 0.5*((Ec.h_vol - Sc.h_vol)*Modelica.Math.sin(pi*Qc/2/Qeps) + Ec.h_vol + Sc.h_vol));
  else
    0=if Qc > 0 then Ec.h - Ec.h_vol else Sc.h - Sc.h_vol;
  end if;
  if continuous_flow_reversal then
    0=noEvent(if Qf > Qeps then Ef.h - Ef.h_vol else if Qf < -Qeps then Sf.h - Sf.h_vol else Ef.h - 0.5*((Ef.h_vol - Sf.h_vol)*Modelica.Math.sin(pi*Qf/2/Qeps) + Ef.h_vol + Sf.h_vol));
  else
    0=if Qf > 0 then Ef.h - Ef.h_vol else Sf.h - Sf.h_vol;
  end if;
  Ec.Q=Sc.Q;
  Qc=Ec.Q;
  Ef.Q=Sf.Q;
  Qf=Ef.Q;
  DW=Qf*(Sf.h - Ef.h);
  DW=Qc*(Ec.h - Sc.h);
  Sc.P=if Qc > 0 then Ec.P - DPc*Ec.P/100 else Ec.P + DPc*Ec.P/100;
  Sf.P=if Qf > 0 then Ef.P - DPf*Ef.P/100 else Ef.P + DPf*Ef.P/100;
  proce=ThermoSysPro.Properties.Fluid.Ph(Ec.P, Ec.h, modec, 1);
  procs=ThermoSysPro.Properties.Fluid.Ph(Sc.P, Sc.h, modec, 1);
  Tec=proce.T;
  Tsc=procs.T;
  profe=ThermoSysPro.Properties.Fluid.Ph(Ef.P, Ef.h, 0, 2);
  profs=ThermoSysPro.Properties.Fluid.Ph(Sf.P, Sf.h, 0, 2);
  Tef=profe.T;
  Tsf=profs.T;
end ExchangerWaterC3H3F5W;
