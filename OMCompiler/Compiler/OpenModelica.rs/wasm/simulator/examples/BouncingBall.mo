model BouncingBall "A ball bouncing on the ground, losing energy until it rests"
  parameter Real e=0.7 "coefficient of restitution";
  parameter Real g(unit = "m/s2") = 9.81 "gravity acceleration";
  Real h(unit = "m", fixed=true, start=1) "height of ball";
  Real v(unit = "m/s", fixed=true) "velocity of ball";
  Boolean flying(fixed=true, start=true) "true, if ball is flying";
  Boolean impact;
  Real v_new(fixed=true);
equation
  impact = h <= 0.0;
  der(v) = if flying then -g else 0;
  der(h) = v;
  when {h <= 0.0 and v <= 0.0,impact} then
    v_new = if edge(impact) then -e*pre(v) else 0;
    flying = v_new > 0;
    reinit(v, v_new);
  end when;
  annotation(experiment(StopTime = 3, Interval = 2e-3),
    Documentation(figures = {
      Figure(title = "Bouncing ball", preferred = true, plots = {
        Plot(title = "Height", curves = {Curve(y = h, legend = "height")}),
        Plot(title = "Velocity", curves = {Curve(y = v, legend = "velocity")})},
        caption = "Height and velocity of a ball that retains %{e} of its speed at each bounce.")}));
end BouncingBall;
