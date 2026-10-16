package FunctionInverseSolve
  function f "monotone in x, no closed form for x"
    input Real a;
    input Real x;
    output Real y;
  algorithm
    y := a*x + 0.1*x^3;
    annotation(Inline=false, inverse(x = FunctionInverseSolve.f_inv(a, y)));
  end f;

  function f_inv
    input Real a;
    input Real y;
    output Real x;
  algorithm
    x := y/a;
    for i in 1:30 loop
      x := x - (a*x + 0.1*x^3 - y)/(a + 0.3*x^2);
    end for;
    annotation(Inline=false);
  end f_inv;

  model Test "y given, equation solved for x with the inverse"
    parameter Real a = 2;
    Real x;
    Real y = 3 + time;
  equation
    y = FunctionInverseSolve.f(a, x);
  end Test;

  model Test2 "the call is isolated first"
    parameter Real a = 2;
    Real x;
    Real z = time;
  equation
    2*FunctionInverseSolve.f(a, x) + z = 7;
  end Test2;
end FunctionInverseSolve;
