model dcmotor
  Modelica.Electrical.Analog.Basic.Resistor     resistor1(R = 10); 
  //Observe the difference between MSL 2.2 and 3.1 regarding the default values, in 3.1 there are no default values set, only start values
  Modelica.Electrical.Analog.Basic.Inductor     inductor1(L = 0.2);
  Modelica.Electrical.Analog.Basic.Ground       ground1;
  Modelica.Mechanics.Rotational.Components.Inertia      load(J = 1);    // Modelica version 3.1
  // Modelica.Mechanics.Rotational.Inertia         load(J = 1); // Modelica version 2.2
  Modelica.Electrical.Analog.Basic.EMF          emf1;
  Modelica.Blocks.Sources.Step                  step1;
  Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage1;
equation
  //connect(step1.outport, signalVoltage1.inPort);
  connect(step1.y, signalVoltage1.v);
  connect(signalVoltage1.p, resistor1.p);
  connect(resistor1.n, inductor1.p);
  connect(inductor1.n, emf1.p);
  // connect(emf1.flange_b, load.flange_a); //Modelica version 2.2
  connect(emf1.flange, load.flange_a); // Modelica version 3.1
  connect(signalVoltage1.n, ground1.p);
  connect(ground1.p, emf1.n);
end dcmotor;
