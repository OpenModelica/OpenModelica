// name:     Delay3
// keywords: builtin
// status:   correct
//
// Test builtin function delay.
//

model Delay
  Real x;
  Integer y;
equation
  x = 0;
  y = delay(x, 2.5);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Delay;

// Result:
// class Delay
//   Real x;
//   Integer y;
// equation
//   x = 0.0;
//   /*Real*/(y) = delay(x, 2.5, 2.5);
// end Delay;
// endResult
