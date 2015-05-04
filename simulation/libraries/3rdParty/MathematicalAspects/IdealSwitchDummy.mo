model IdealSwitchDummy "Ideal electrical switch"
  extends Modelica.Electrical.Analog.Interfaces.OnePort;
  Boolean off(start=false);
  discrete Integer sign_i(start=0);
  parameter Real t0=0.5;
  annotation (
    Documentation(info="<html>
<P>
Ideal electrical switch. In order to prevent singularities
during switching, the opened switch has a high resistance
and the closed switch has a low resistance.
</P>
<P>
If the actual circuit has an appropriate structure, the
limiting case is also allowed, i.e., the resistance of the
closed switch could be exactly zero and the conductance of the
open switch could be also exactly zero (i.e. the resistance is
infinite). Note, there are circuits, where a description
with zero/infinity resistances is not possible.
</P>
</HTML>
"), Coordsys(
      extent=[-100, -100; 100, 100],
      grid=[1, 1],
      component=[20, 20]),
    Window(
      x=0.28,
      y=0.13,
      width=0.56,
      height=0.63),
    Icon(
      Ellipse(extent=[-44, 4; -36, -4]),
      Line(points=[-90, 0; -44, 0]),
      Line(points=[-37, 2; 40, 50]),
      Line(points=[40, 0; 90, 0]),
      Text(extent=[-100, -70; 100, -100], string="%name")),
    Diagram(
      Ellipse(extent=[-44, 4; -36, -4]),
      Line(points=[-90, 0; -44, 0]),
      Line(points=[-37, 2; 40, 50]),
      Line(points=[40, 0; 90, 0]),
      Text(extent=[-100, -40; 100, -79], string="%name")));
equation
  when (time>t0) then
    sign_i = if (i>0) then 1 else -1;
  end when;
  when (time>t0 and sign_i*i<0) then
   off = true;
  end when;
  0 = if off then der(i) else v;
end IdealSwitchDummy;
