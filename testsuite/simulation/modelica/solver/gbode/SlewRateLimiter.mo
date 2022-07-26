model SlewRateLimiter
  "Demonstrate usage of Nonlinear.SlewRateLimiter"
  import Modelica.Units.SI;
  extends Modelica.Icons.Example;
  parameter SI.Velocity vMax=2 "Max. velocity";
  parameter SI.Acceleration aMax=20 "Max. acceleration";
  Modelica.Blocks.Continuous.Der v
    annotation (Placement(transformation(extent={{-20,-10},{0,10}})));
  Modelica.Blocks.Sources.Step positionStep(startTime=0.1)
    annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));
  Modelica.Blocks.Continuous.Der a
    annotation (Placement(transformation(extent={{50,-40},{70,-20}})));
  SI.Position s=positionStep.y "Reference position";
  SI.Position sSmoothed=positionSmoothed.y "Smoothed position";
  Modelica.Blocks.Nonlinear.SlewRateLimiter limit_a(
    initType=Modelica.Blocks.Types.Init.InitialOutput,
    y_start=0,
    Rising=20,
    Td=0.0001)
              annotation (Placement(transformation(extent={{10,-10},{30,10}})));
  Modelica.Blocks.Nonlinear.SlewRateLimiter limit_v(
    initType=Modelica.Blocks.Types.Init.InitialOutput,
    Rising=vMax,
    y_start=positionStep.offset,
    Td=0.0001)
    annotation (Placement(transformation(extent={{-50,-10},{-30,10}})));
  Modelica.Blocks.Continuous.Integrator positionSmoothed(
    k=1,
    initType=Modelica.Blocks.Types.Init.InitialOutput,
    y_start=positionStep.offset)
    annotation (Placement(transformation(extent={{50,-10},{70,10}})));
  SI.Velocity vLimited=limit_a.y "Limited velocity";
  SI.Acceleration aLimited=a.y "Limited acceleration";
equation
  connect(limit_v.y, v.u)
    annotation (Line(points={{-29,0},{-22,0}}, color={0,0,127}));
  connect(v.y, limit_a.u)
    annotation (Line(points={{1,0},{8,0}}, color={0,0,127}));
  connect(limit_a.y, a.u) annotation (Line(points={{31,0},{40,0},{40,-30},{48,-30}},
        color={0,0,127}));
  connect(limit_a.y, positionSmoothed.u)
    annotation (Line(points={{31,0},{39.5,0},{48,0}}, color={0,0,127}));
  connect(positionStep.y, limit_v.u)
    annotation (Line(points={{-59,0},{-52,0}}, color={0,0,127}));

  annotation (experiment(StopTime = 1, Interval = 0.001, StartTime = 0, Tolerance = 1e-06), Documentation(info="<html>
<p>
This example demonstrates how to use the Nonlinear.SlewRateLimiter block to limit a position step with regards to velocity and acceleration:
</p>
<ul>
<li> The Sources.Step block <code>positionStep</code> demands an unphysical position step.</li>
<li> The first SlewRateLimiter block  <code>limit_v</code> limits velocity.</li>
<li> The first Der block <code>v</code> calculates velocity from the smoothed position signal.</li>
<li> The second SlewRateLimiter block <code>limit_a</code> limits acceleration of the smoothed velocity signal.</li>
<li> The second Der block <code>a</code> calculates acceleration from the smoothed velocity signal.</li>
<li> The Integrator block <code>positionSmoothed</code> calculates smoothed position from the smoothed velocity signal.</li>
</ul>
<p>
A position controlled drive with limited velocity and limited acceleration (i.e. torque) is able to follow the smoothed reference position.
</p>
</html>"),
    __OpenModelica_simulationFlags(lv = "LOG_STATS", s = "gbode"));
end SlewRateLimiter;
