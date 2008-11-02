model dcmotor
  Modelica.Electrical.Analog.Basic.Resistor r1(R=10);
  Modelica.Electrical.Analog.Basic.Inductor i1;
  Modelica.Electrical.Analog.Basic.EMF emf1;
  Modelica.Mechanics.Rotational.Inertia load;
  Modelica.Electrical.Analog.Basic.Ground g;
  Modelica.Electrical.Analog.Sources.ConstantVoltage v;
equation
  connect(v.p, r1.p);
  connect(v.n, g.p);
  connect(r1.n, i1.p);
  connect(i1.n, emf1.p);
  connect(emf1.n, g.p);
  connect(emf1.flange_b, load.flange_a);
end dcmotor;
