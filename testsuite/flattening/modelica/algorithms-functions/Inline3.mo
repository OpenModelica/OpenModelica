// name: Inline3
// keywords: inline, function
// status: correct
//
// Test case for inline annotations
//

function inlineFac
  input Integer n;
  output Integer res;
  annotation(Inline = true);
algorithm
  res := if n == 1 then 1 else n * inlineFac(n - 1);
end inlineFac;

model Inline3
  Integer x;
  Integer y;
equation
  x = 5;
  y = inlineFac(x);
end Inline3;

// Result:
// class Inline3
// Integer x;
// Integer y;
// equation
//   x = 5;
//   y = if x == 1 then 1 else x * inlineFac(x - 1);
// end Inline3;
// endResult
