within DataReconciliationSimpleTests.QPLib.WaterSteam.PressureLosses;
model PipePressureLoss "Pipe generic pressure loss"
  parameter Real K=10 "Friction pressure loss coefficient";
  parameter Modelica.SIunits.Position z1=0 "Inlet altitude";
  parameter Modelica.SIunits.Position z2=0 "Outlet altitude";
  parameter Modelica.SIunits.Density p_rho=1000 "If > 0, fixed fluid density";

protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n
    "Gravity constant";
  parameter Real eps=1.e-3 "Small number for pressure loss equation";

public
  QPLib.Units.DifferentialPressure deltaPf "Friction pressure loss";
  QPLib.Units.DifferentialPressure deltaPg "Gravity pressure loss";
  QPLib.Units.DifferentialPressure deltaP "Total pressure loss";
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow rate";
  Modelica.SIunits.Density rho(start=998) "Fluid density";
  Modelica.SIunits.AbsolutePressure Pm(start=1.e5) "Average fluid pressure";

public
  Connectors.FluidInlet                         C1 annotation (Placement(
        transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
  Connectors.FluidOutlet                         C2 annotation (Placement(
        transformation(extent={{90,-10},{110,10}}, rotation=0)));

equation
  C1.P - C2.P = deltaP;
  C2.Q = C1.Q;

  Q = C1.Q;


  /* Pressure loss */
  deltaPf = K*QPLib.Functions.ThermoSquare(Q, eps)/rho;
  deltaPg = rho*g*(z2 - z1);
  deltaP = deltaPf + deltaPg;

  /* Fluid thermodynamic properties */
  Pm = (C1.P + C2.P)/2;

  rho = p_rho;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Rectangle(
          extent={{-100,20},{100,-20}},
          lineColor={0,0,255},
          fillColor={85,255,85},
          fillPattern=FillPattern.Solid), Text(
          extent={{-12,14},{16,-14}},
          lineColor={0,0,255},
          fillColor={85,255,85},
          fillPattern=FillPattern.Solid,
          textString=
               "K")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Rectangle(
          extent={{-100,20},{100,-20}},
          lineColor={0,0,255},
          fillColor={85,255,85},
          fillPattern=FillPattern.Solid), Text(
          extent={{-12,14},{16,-14}},
          lineColor={0,0,255},
          fillColor={85,255,85},
          fillPattern=FillPattern.Solid,
          textString=
               "K")}),
    Window(
      x=0.11,
      y=0.04,
      width=0.71,
      height=0.88),
    Documentation(info="<html>
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
end PipePressureLoss;
