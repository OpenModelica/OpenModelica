within ThermoSysPro.WaterSolution.Machines;
model StaticCentrifugalPumpNom "Static centrigugal pump with nominal operating point"
  parameter Modelica.SIunits.MassFlowRate Qnom=1 "Nominal mass flow";
  parameter ThermoSysPro.Units.DifferentialPressure DPnom=100000.0 "Nominal pressure increase";
  parameter Real A=0.15 "x^2 coef. of the pump characteristics (A>0)";
  parameter Real B=0.35 "x coef. of the pump characteristics (B>0)";
  parameter Real eta=0.9 "Hydraulic efficiency";
  ThermoSysPro.Units.DifferentialPressure deltaP(start=100000.0) "Pressure difference between the outlet and the inlet";
  ThermoSysPro.Units.SpecificEnthalpy He(start=1000.0) "Fluid specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hs(start=1000.0) "Fluid specific enthalpy at the outlet";
  Modelica.SIunits.Power W(start=1000000.0) "Mechanical power of the pump";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{64,-18},{42,-64},{-22,-80},{-68,-60},{-90,-20},{-90,20},{-70,60},{-30,80},{90,80},{90,20},{54,20},{64,-18}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={223,159,159})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{64,-18},{42,-64},{-22,-80},{-68,-60},{-90,-20},{-90,20},{-70,60},{-30,80},{90,80},{90,20},{54,20},{64,-18}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={223,159,159})}), Documentation(info="<html>
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
  Connectors.WaterSolutionInlet Ce annotation(Placement(transformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.WaterSolutionOutlet Cs annotation(Placement(transformation(x=90.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  Cs.Xh2o=Ce.Xh2o;
  Cs.Q=Ce.Q;
  deltaP=Cs.P - Ce.P;
  He=ThermoSysPro.Properties.WaterSolution.SpecificEnthalpy_TX(Ce.T, Ce.Xh2o);
  Hs=He + W/Ce.Q;
  Cs.T=ThermoSysPro.Properties.WaterSolution.Temperature_hX(Hs, Cs.Xh2o);
  deltaP/DPnom - 1=-A*(Ce.Q/Qnom - 1)*abs(Ce.Q/Qnom - 1) - B*(Ce.Q/Qnom - 1);
  W=Ce.Q*deltaP/eta;
end StaticCentrifugalPumpNom;
