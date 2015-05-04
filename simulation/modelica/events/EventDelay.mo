model TestModel
  Real Auxiliary1 = if time > 0 then 0 else 1;
  Real Valve1;
  Real Stock1(start = 0.0, fixed = true);
equation
  Valve1 = delay(Stock1, 1);
  der(Stock1) = +Valve1;
end TestModel;

