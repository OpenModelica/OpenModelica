model BouncingBall
  parameter Real e=0.7 "coefficient of restitution";
  parameter Real g=9.81 "gravity acceleration";
  Real h(start=1) "height of ball";
  Real v "velocity of ball";
  Real v_new;
equation
  der(v) = -g;
  der(h) = v;

  when h <= 0.0 then
    v_new = -e*pre(v);
    reinit(v, v_new);
  end when;

end BouncingBall;
