model SmoothEvent3
  Real u;
  Real v;
protected
  constant Real pi=Modelica.Constants.pi;
equation
  v = time;
  u = smooth(1,if time < pi/2 then cos(time) else pi/2-time);
end SmoothEvent3;
