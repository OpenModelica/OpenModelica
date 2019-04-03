within ThermoSysPro.Thermal.HeatTransfer;
model ConvectiveHeatFlow "Convective heat flow"
  parameter Modelica.SIunits.Area A[:]={1} "Heat exchange surface";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer k[:]={1000} "Heat exchange coefficient";
  ThermoSysPro.Thermal.Connectors.ThermalPort C1 annotation(Placement(transformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort C2 annotation(Placement(transformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Integer N=size(A, 1);
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-15,65},{15,65},{0,90},{-15,65}}, fillPattern=FillPattern.Solid, lineColor={255,0,0}, fillColor={255,0,0}),Line(points={{0,70},{0,40},{-20,30},{20,10},{-20,-10},{20,-30},{0,-40},{0,-70}}, color={255,0,0}, thickness=0.5),Polygon(points={{-15,-65},{15,-65},{0,-90},{-15,-65}}, fillPattern=FillPattern.Solid, lineColor={255,0,0}, fillColor={255,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-15,65},{15,65},{0,90},{-15,65}}, fillPattern=FillPattern.Solid, lineColor={255,0,0}, fillColor={255,0,0}),Line(points={{0,70},{0,40},{-20,30},{20,10},{-20,-10},{20,-30},{0,-40},{0,-70}}, color={255,0,0}, thickness=0.5),Polygon(points={{-15,-65},{15,-65},{0,-90},{-15,-65}}, fillPattern=FillPattern.Solid, lineColor={255,0,0}, fillColor={255,0,0})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
equation
  C1.W=k*A*(C1.T - C2.T);
  C1.W=-C2.W;
end ConvectiveHeatFlow;
