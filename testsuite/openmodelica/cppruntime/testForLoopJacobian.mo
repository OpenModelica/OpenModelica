package testForLoopJacobian
  model Component
    parameter Real amp;
    Real x;
    Real y;
  equation
    der(x) + y = amp * sin(time) - der(x);
    0 = der(x) + amp * x;
  end Component;

  model Example
    parameter Integer n = 10;
    Component[n] a(each x(start=1, fixed=true), amp=1:n);
    Real[n] x(each start=1, each fixed=true);
    Real[n] y;
  equation
    for i in 1:n loop
      der(x[i]) + y[i] = i * sin(time) - der(x[i]);
      0 = der(x[i]) + i * x[i];
    end for;
  end Example;
end testForLoopJacobian;

