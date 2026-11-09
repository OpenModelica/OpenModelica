package PPAP
  model M
    parameter Real p = 3
      "This has some formatting on its own";
    Real x,     y,      z "Variables with some whitespace";
  equation
       x  +  10*y + 20*z = 10;
    10*x  +  20*y +    z = 30;
                y        = p;
  end M;
end PPAP;