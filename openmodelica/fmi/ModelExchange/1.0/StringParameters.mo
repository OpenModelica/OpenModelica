model StringParameters
  parameter String sball = "RedBall";
  parameter String eball = "BlueBall";
  parameter Real e=0.7 "coefficient of restitution";
  parameter Real g=9.81 "gravity acceleration";
  Real h(start=1) "height of ball";
  Real v "velocity of ball";
  Real v_new;
  String ball(start = sball);
equation
  der(v) = -g;
  der(h) = v;
  ball = if h <= 0.0 then sball else eball;
  when h <= 0.0 then
    v_new = -e*pre(v);
    reinit(v, v_new);
  end when;
end StringParameters;
