model dcmotor
  import Modelica.Electrical.Analog.Basic;
  Basic.Resistor resistor1(R = 10);
  Basic.Inductor inductor1(L = 0.2, i.fixed=true);
  Basic.Ground ground1;
  Modelica.Mechanics.Rotational.Components.Inertia load(J = 1, phi.fixed=true, w.fixed=true);
  Basic.EMF emf1(k=1.0);
  Modelica.Blocks.Sources.Step step1;
  Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage1;
equation
  connect(step1.y, signalVoltage1.v);
  connect(signalVoltage1.p, resistor1.p);
  connect(resistor1.n, inductor1.p);
  connect(inductor1.n, emf1.p);
  connect(emf1.flange, load.flange_a);
  connect(signalVoltage1.n, ground1.p);
  connect(ground1.p, emf1.n);
  annotation(uses(Modelica(version="3.2.2")));
end dcmotor;
