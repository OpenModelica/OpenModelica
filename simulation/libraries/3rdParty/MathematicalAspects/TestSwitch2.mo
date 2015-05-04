model TestSwitch2
  Modelica.Electrical.Analog.Basic.Ground G;
  Modelica.Electrical.Analog.Basic.Inductor I(i(start=0.075));
  Modelica.Electrical.Analog.Sources.SineVoltage U;
  IdealSwitchStiff S(t0=0.5);
equation
  connect(U.n, I.p);
  connect(U.p, G.p);
  connect(I.n, S.p);
  connect(S.n, G.p);
end TestSwitch2;
