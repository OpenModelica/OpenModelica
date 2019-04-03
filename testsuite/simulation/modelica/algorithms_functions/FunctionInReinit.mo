model FunctionInReinit

  function fn
    input Real t;
    output Real y;
  algorithm
    y := 10*t;
  end fn;

  Real x(start=1.0);
equation
  der(x) = -1;
  when sample(0.05, 0.05) then
    reinit(x, fn(time));
  end when;
end FunctionInReinit;
