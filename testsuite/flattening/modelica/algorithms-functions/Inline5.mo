// name: Inline5
// keywords: inline, function
// status: correct
//
// Test case for inline annotations
//

model Inline5

function simpleInline
  input Integer inInt;
  output Integer outInt;
  annotation(Inline = true);
algorithm
  outInt := (inInt + 2 + 3 - inInt) * inInt;
end simpleInline;

  Integer x;
  Integer y;
equation
  x = 2;
  y = (2 + simpleInline(x)) * (simpleInline(x + 8) / 2);
end Inline5;

// Result:
// class Inline5
// Integer x;
// Integer y;
// equation
//   x = 2;
//   Real(y) = Real(2 + (5 + x - x) * x) * Real((13 + x - (8 + x)) * (8 + x)) / 2.0;
// end Inline5;
// endResult
