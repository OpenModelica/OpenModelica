// name: Inline2
// keywords: inline, function
// status: correct
//
// Test case for inline annotations
//

function simpleInline
  input Integer inInt;
  output Integer outInt;
  annotation(Inline = true);
algorithm
  outInt := inInt + simpleInline2(inInt + 10);
end simpleInline;

function simpleInline2
  input Integer inInt2;
  output Integer outInt2;
  annotation(Inline = true);
algorithm
  outInt2 := inInt2 * 3;
end simpleInline2;

model Inline2
  Integer x;
  Integer y;
equation
  x = 2;
  y = (2 + simpleInline(x)) * (simpleInline(x + 8) / 2);
end Inline2;

// Result:
// class Inline2
// Integer x;
// Integer y;
// equation
//   x = 2;
//   Real(y) = Real(32 + 4 * x) * Real(62 + 4 * x) / 2.0;
// end Inline2;
// endResult
