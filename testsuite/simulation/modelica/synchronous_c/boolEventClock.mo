model boolEventClock
  Clock eventClk = Clock(cond);
  Real x, x_clocked, x_clocked_continous;
  Real sub, sub_abs;
  Boolean cond;
  Real y(start=0);
equation
  x = 10*cos(2*Modelica.Constants.pi*time);
  x_clocked = sample(x, eventClk);    // only defined after first tick
  x_clocked_continous = hold(x_clocked);  // Returns start value of x_clocked before first tick

  sub = x - x_clocked_continous;
  sub_abs = if noEvent(sub >= 0) then sub else -sub;

  cond = 3 < sub_abs;

  when eventClk then
    y = previous(y) + 1 ;
  end when;
end boolEventClock;