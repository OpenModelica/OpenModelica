model SmoothEvent2
  Real u;
  Real v;
protected
  constant Real pi=Modelica.Constants.pi;
equation
  v = time;
  u = noEvent(if time < pi/2 then cos(time) else pi/2-time);
end SmoothEvent2;
