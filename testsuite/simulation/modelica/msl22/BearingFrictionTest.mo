model BearingFrictionTest
  annotation (uses(Modelica(version="2.2")), Diagram);
  Modelica.Mechanics.Rotational.BearingFriction BearingFriction1(tau_pos=[0,0.7;
        1,2; 2,1.6; 3,0.6; 4,0.4]) annotation (extent=[2,16; 22,36]);
  Modelica.Mechanics.Rotational.Torque Torque1
    annotation (extent=[-40,16; -20,36]);
  Modelica.Blocks.Sources.Constant Constant1(k=2)
    annotation (extent=[-84,16; -64,36]);
  Modelica.Mechanics.Rotational.Inertia Inertia1
    annotation (extent=[40,16; 60,36]);
equation
  connect(Torque1.flange_b, BearingFriction1.flange_a)
    annotation (points=[-20,26; 2,26], style(color=0, rgbcolor={0,0,0}));
  connect(Constant1.y, Torque1.tau)
    annotation (points=[-63,26; -42,26], style(color=74, rgbcolor={0,0,127}));
  connect(BearingFriction1.flange_b, Inertia1.flange_a)
    annotation (points=[22,26; 40,26], style(color=0, rgbcolor={0,0,0}));
end BearingFrictionTest;
