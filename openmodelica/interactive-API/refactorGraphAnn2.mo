// name:     refactorGraphAnn2
// keywords: annotation
// status:   correct
//
// Graphical  class annotations of old standard to be refactored into a new on.
//

model connecttest

  annotation (uses(Modelica(version="1.6"), ModelicaAdditions(version="1.5")),Diagram);
  Modelica.Electrical.Analog.Basic.Conductor conductor annotation (extent=[24,54; 44,74]);
  Modelica.Electrical.Analog.Basic.Resistor resistor  annotation (rotation = 180,extent=[-18,18;0,94]);
  Modelica.Electrical.Analog.Basic.Conductor conductor1 annotation (extent=[94,22;64,42],rotation= 45);
equation
  connect(resistor.n, conductor.p) annotation (points=[-18,56; 14,56; 14,64; 24,64], style(
      color=85,
      rgbcolor={255,0,128},
      pattern=2,
      arrow=3));
  connect(resistor.p, conductor1.p) annotation (style(color=3, rgbcolor={0,0,255}),points=[0,56;
        -20,56; -20,-40; 89.6066,-40; 89.6066,24.9289]);
  connect(conductor1.n, conductor.n) annotation (points=[68.3934,39.0711;
        68.3934,64; 44,64],style(
      color=3,
      rgbcolor={0,0,255},
      thickness=4));
end connecttest;

// class complextest
// end complextest;
