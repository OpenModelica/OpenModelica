model TestSwitch1
  Modelica.Electrical.Analog.Basic.Ground G
    annotation (extent=[0,-28; 20,-8]);
  Modelica.Electrical.Analog.Basic.Inductor I(i(start=0.075))
    annotation (extent=[-48,18; -28,38]);
  Modelica.Electrical.Analog.Sources.SineVoltage U
    annotation (extent=[-66,-2; -46,18], rotation=90);
  IdealSwitchDummy S          annotation (extent=[-18,18; 2,38]);
equation
  connect(U.n, I.p)                    annotation (points=[-56,18; -56,28; -48,
        28], style(color=3, rgbcolor={0,0,255}));
  connect(U.p, G.p)
    annotation (points=[-56,-2; -56,-8; 10,-8],
                                        style(color=3, rgbcolor={0,0,255}));
  connect(I.n, S.p)
    annotation (points=[-28,28; -18,28], style(color=3, rgbcolor={0,0,255}));
  connect(S.n, G.p)      annotation (points=[2,28; 10,28; 10,-8], style(color=3,
        rgbcolor={0,0,255}));
end TestSwitch1;
