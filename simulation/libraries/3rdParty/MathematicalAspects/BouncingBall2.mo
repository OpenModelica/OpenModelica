model BouncingBall2
  import Modelica.SIunits;
  parameter Real e=0.7 "coefficient of restitution";
  parameter SIunits.Acceleration g=9.81 "gravity acceleration";
  SIunits.Position h(start=1) "height of ball";
  SIunits.Velocity v "velocity of ball";
  Boolean flying(start=true) "true, if ball is flying";
  Boolean impact;
  SIunits.Velocity v_new;
equation
  der(h) = v;
  der(v) = if flying then -g else 0;

  impact = h < 0;
  when {impact,h < 0 and v < 0} then
    v_new = if edge(impact) then -e*pre(v) else 0;
    flying = v_new > 0;
    reinit(v, v_new);
  end when;
end BouncingBall2;
