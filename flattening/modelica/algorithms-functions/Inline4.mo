// name: Inline4
// keywords: function, inline
// status: correct
//
// Tests inline functions passed to inline functions as arguments
//

function inlineTwoArgs
  input Integer inInt1;
  input Integer inInt2;
  output Integer outInt;
  annotation(Inline = true);
algorithm
  outInt := (inInt1 + inInt2) * (inInt1 - inInt2);
end inlineTwoArgs;

function simpleInline
  input Integer inInt;
  output Integer outInt;
  annotation(Inline = true);
algorithm
  outInt := inInt + 2;
end simpleInline;

model Inline4
  Integer x,y,z;
equation
  x = 4;
  y = x + 4;
  z = inlineTwoArgs(x, inlineTwoArgs(x, simpleInline(y)));
end Inline4;

// Result:
// class Inline4
// Integer x;
// Integer y;
// Integer z;
// equation
//   x = 4;
//   y = 4 + x;
//   z = inlineTwoArgs(x,inlineTwoArgs(x,simpleInline(y)));
// end Inline4;
// endResult
