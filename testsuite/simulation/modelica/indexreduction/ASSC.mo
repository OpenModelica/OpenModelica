model ASSC
"test model for the ASSC algorithm
 Analytical to Structural Singularity Conversion"
  Real x(fixed = true), y;    // states
  Real a, b, c; // algebraic variables
equation
  der(x) = sin(time);
  der(y) = cos(time) + a;

  // analytically singular algebraic loop
  2*a + 2*b + c + x = 10;
  a + b + y = 5;
  a + b + c = 0;
end ASSC;
