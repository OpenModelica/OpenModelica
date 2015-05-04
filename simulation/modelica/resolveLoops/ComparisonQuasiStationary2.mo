within ;
model ComparisonQuasiStationary2
  "Slow forced armature motion of both solenoid models so that electromagnetic field and current are quasi-stationary"

  extends Modelica.Icons.Example;

  parameter Modelica.SIunits.Voltage v_step=12 "Applied voltage";

  Modelica.Blocks.Sources.Ramp x_set(
    duration=10,
    offset=1,
    height=1)
    "Prescribed armature position, slow enforced motion from x_max to x_min"
                         annotation (Placement(transformation(extent={{80,
          -10},{60,10}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Ground simpleGround
    annotation (Placement(transformation(extent={{-80,-90},{-60,-70}},
        rotation=0)));
  Modelica.Electrical.Analog.Sources.StepVoltage simpleSource(V=v_step)
    annotation (Placement(transformation(
      origin={-70,-50},
      extent={{-10,-10},{10,10}},
      rotation=270)));
  Modelica.Mechanics.Translational.Sources.Position simpleFeed_x(
                                                         f_crit=1000, exact=false)
    annotation (Placement(transformation(
      origin={-2,-50},
      extent={{-10,-10},{10,10}},
      rotation=180)));
  SimpleSolenoid2 simpleSolenoid2_1
    annotation (Placement(transformation(extent={{-44,-56},{-24,-36}})));
equation
  connect(simpleFeed_x.s_ref, x_set.y)  annotation (Line(points={{10,-50},{20,
          -50},{20,0},{59,0}},   color={0,0,127}));
  connect(simpleGround.p, simpleSource.n)
                                  annotation (Line(points={{-70,-70},{-70,
        -60}}, color={0,0,255}));
  connect(simpleSolenoid2_1.p, simpleSource.p) annotation (Line(
      points={{-44,-40},{-70,-40}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(simpleSolenoid2_1.n, simpleSource.n) annotation (Line(
      points={{-44,-52},{-56,-52},{-56,-60},{-70,-60}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(simpleSolenoid2_1.flange, simpleFeed_x.flange) annotation (Line(
      points={{-24,-46},{-18,-46},{-18,-50},{-12,-50}},
      color={0,127,0},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}),
                      graphics),                             experiment(StopTime=
          10, Tolerance=1e-007),
    Documentation(info="<html>
<p>
Have a look at <a href=\"modelica://Modelica.Magnetic.FluxTubes.Examples.SolenoidActuator\">SolenoidActuator</a> for general comments and at <a href=\"modelica://Modelica.Magnetic.FluxTubes.Examples.SolenoidActuator.Components.SimpleSolenoid\">SimpleSolenoid</a> and <a href=\"modelica://Modelica.Magnetic.FluxTubes.Examples.SolenoidActuator.Components.AdvancedSolenoid\">AdvancedSolenoid</a> for a detailed description of both magnetic network models.
</p>

<p>
Similar to static force-stroke measurements on real actuators, the armatures of both actuator models are forced to move slowly here. Hence, the dynamics of the electrical subsystems due to coil inductance and armature motion can be neglected and the static force-stroke characteristics are obtained. To illustrate the accuracy to be expected from the lumped magnetic network models, results obtained with stationary FEA are included as reference (position-dependent force, armature flux and actuator inductance). Note that these reference values are valid for the default supply voltage v_step=12V DC only!
</p>

<p>
Set the <b>tolerance</b> to <b>1e-7</b> and <b>simulate for 10 s</b>. Plot in one common window the electromagnetic force of the two magnetic network models and the FEA reference <b>vs. armature position x_set.y</b>:
</p>

<pre>
    simpleSolenoid.armature.flange_a.f     // electromagnetic force of simple magnetic network model
    advancedSolenoid.armature.flange_a.f   // electromagnetic force of advaned magnetic network model
    comparisonWithFEA.y[1]                 // electromagnetic force obtained with FEA as reference
</pre>

<p>
Electromagnetic or reluctance forces always act towards a decrease of air gap lengths. With the defined armature position coordinate x, the forces of the models are negative.
</p>

<p>
The magnetic flux through the armature and the actuator's static inductance both illustrate the differences between the two magnetic network models. Similar to the forces, compare these quantities in one common plot window for each variable (plot vs. armature position x_set.y):
</p>

<pre>
    simpleSolenoid.G_mFeArm.Phi            // magnetic flux through armature of simple magnetic network model
    advancedSolenoid.G_mFeArm.Phi          // magnetic flux through armature of advanced magnetic network model
    comparisonWithFEA.y[2]                 // magnetic flux obtained with FEA as reference

    simpleSolenoid.coil.L_stat             // static inductance of simple magnetic network model
    advancedSolenoid.L_statTot             // series connection of both partial coils of advanced network model
    comparisonWithFEA.y[3]                 // static inductance obtained with FEA as reference
</pre>

<p>
As mentioned in the description of both magnetic network models, one can tell the higher armature flux and inductance of the advanced solenoid model at large air gaps compared to that of the simple model. The effect of this difference on dynamic model behaviour can be analysed in <a href=\"modelica://Modelica.Magnetic.FluxTubes.Examples.SolenoidActuator.ComparisonPullInStroke\">ComparisonPullInStroke</a>.
</p>
</html>"),
    uses(Modelica(version="3.2")));
end ComparisonQuasiStationary2;
