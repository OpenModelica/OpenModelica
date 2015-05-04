model Test3PhaseSystems
  constant Real pi=Modelica.Constants.pi;
  parameter Real shift=0.4;
  Real i_abc[3]={I1.i,I2.i,I3.i};
  Real i_dq0[3];
protected
  Real theta;
  Real P[3,3];
public
  Modelica.Electrical.Analog.Basic.Resistor R1(R=0.5)
    annotation (extent=[20,40; 40,60]);
  Modelica.Electrical.Analog.Basic.Inductor I1(L=1) annotation (extent=[-20,40; 0,60]);
  Modelica.Electrical.Analog.Basic.Resistor R2(R=0.5)
    annotation (extent=[20,0; 40,20]);
  Modelica.Electrical.Analog.Basic.Inductor I2(L=1) annotation (extent=[-20,0; 0,20]);
  Modelica.Electrical.Analog.Basic.Resistor R3(R=0.5)
    annotation (extent=[20,-40; 40,-20]);
  Modelica.Electrical.Analog.Basic.Inductor I3(L=1)
    annotation (extent=[-20,-40; 0,-20]);
  Modelica.Electrical.Analog.Sources.SineVoltage S1(freqHz=1, V=1, phase=0)
    annotation (extent=[-60,40; -40,60], rotation=0);
  Modelica.Electrical.Analog.Sources.SineVoltage S3(freqHz=1, V=1, phase=4*pi/3)
    annotation (extent=[-60,-40; -40,-20], rotation=0);
  Modelica.Electrical.Analog.Sources.SineVoltage S2(freqHz=1, V=1, phase=2*pi/3)
    annotation (extent=[-60,0; -40,20], rotation=0);
  Modelica.Electrical.Analog.Basic.Ground G
    annotation (extent=[70,-84; 90,-64]);
  Modelica.Electrical.Analog.Sources.SineVoltage SS1(freqHz=1, V=1, phase=shift)
    annotation (extent=[60,40; 80,60], rotation=0);
  Modelica.Electrical.Analog.Sources.SineVoltage SS2(freqHz=1, V=1, phase=2*pi/3 + shift)
               annotation (extent=[60,0; 80,20], rotation=0);
  Modelica.Electrical.Analog.Sources.SineVoltage SS3(freqHz=1, V=1, phase=4*pi/3 + shift)
               annotation (extent=[60,-40; 80,-20], rotation=0);
equation
  theta = 2*pi*time;
  P = sqrt(2)/sqrt(3)*
    [sin(theta), sin(theta+2*pi/3), sin(theta+4*pi/3);
     cos(theta), cos(theta+2*pi/3), cos(theta+4*pi/3);
     1/sqrt(2), 1/sqrt(2), 1/sqrt(2)];
  i_dq0 = P*i_abc;

  connect(I2.n, R2.p)
    annotation (points=[0,10; 20,10], style(color=3, rgbcolor={0,0,255}));
  connect(I1.n, R1.p)
    annotation (points=[0,50; 20,50], style(color=3, rgbcolor={0,0,255}));
  connect(I3.n, R3.p)
    annotation (points=[0,-30; 20,-30], style(color=3, rgbcolor={0,0,255}));
  connect(I1.p, S1.n)
    annotation (points=[-20,50; -40,50], style(color=3, rgbcolor={0,0,255}));
  connect(S3.n, I3.p)
    annotation (points=[-40,-30; -20,-30], style(color=3, rgbcolor={0,0,255}));
  connect(S2.n, I2.p)
    annotation (points=[-40,10; -20,10], style(color=3, rgbcolor={0,0,255}));
  connect(S1.p, S2.p)
    annotation (points=[-60,50; -60,10], style(color=3, rgbcolor={0,0,255}));
  connect(S2.p, S3.p)
    annotation (points=[-60,10; -60,-30], style(color=3, rgbcolor={0,0,255}));
  connect(S3.p, G.p)                 annotation (points=[-60,-30; -60,-64; 80,
        -64], style(color=3, rgbcolor={0,0,255}));
  connect(R3.n, SS3.p)
    annotation (points=[40,-30; 60,-30], style(color=3, rgbcolor={0,0,255}));
  connect(R2.n, SS2.p)
    annotation (points=[40,10; 60,10], style(color=3, rgbcolor={0,0,255}));
  connect(R1.n, SS1.p)
    annotation (points=[40,50; 60,50], style(color=3, rgbcolor={0,0,255}));
  connect(SS1.n, SS2.n)
    annotation (points=[80,50; 80,10], style(color=3, rgbcolor={0,0,255}));
  connect(SS2.n, SS3.n)
    annotation (points=[80,10; 80,-30], style(color=3, rgbcolor={0,0,255}));
  connect(SS3.n, G.p)
    annotation (points=[80,-30; 80,-64], style(color=3, rgbcolor={0,0,255}));
end Test3PhaseSystems;
