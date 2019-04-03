model BouncingBallExamples
  parameter Real e=0.7 "coefficient of restitution";
  parameter Real g=9.81 "gravity acceleration";
  Real h(start=1) "height of ball";
  Real v "velocity of ball";
  Boolean flying(start=true) "true, if ball is flying";
  Boolean impact;
  Real v_new;
equation
  impact = h <= 0.0;
  der(v) = if flying then -g else 0;
  der(h) = v;

  when {h <= 0.0 and v <= 0.0,impact} then
    v_new = if edge(impact) then -e*pre(v) else 0;
    flying = v_new > 0;
    reinit(v, v_new);
  end when;
end BouncingBallExamples;

model BouncingBall "Simple model of a bouncing ball"
   constant Real g=9.81;
   parameter Real c=0.9;
   parameter Real r=0.1;
   Real x(start=1), y(start=0);

equation
   der(x) = y;
   der(y) = -g;
   when x < r then
      reinit(y,(-c)*pre(y));
   end when;
end BouncingBall;


