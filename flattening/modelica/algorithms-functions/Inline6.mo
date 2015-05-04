// name: Inline6
// keywords: inline, function
// status: correct
//
// Test case for inline annotations
//

function simpleInline
  input Integer[:] inInt;
  output Integer outInt;
  annotation(Inline = true);
algorithm
  outInt := inInt[1];
end simpleInline;

model Inline6
  Integer[1] x;
  Integer y;
equation
  x[1] = 2;
  y = simpleInline(x);
end Inline6;

// Result:
// class Inline6
// Integer x[1];
// Integer y;
// equation
//   x[1] = 2;
//   y = simpleInline({x[1]});
// end Inline6;
// endResult
