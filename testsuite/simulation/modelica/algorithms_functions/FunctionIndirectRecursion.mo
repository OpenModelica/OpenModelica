// name:     FunctionIndirectRecursion
// keywords: function
// status:   correct
//
// Constant evaluation of indirectly recursive function call.

function test2
  input  Integer x;
  output Integer y;
algorithm
  y := facIndirect(x);
end test2;

function facIndirect "Indirect recursion"
  input  Integer x;
  output Integer y;
algorithm
  y := if x>0 then x*test2(x-1) else 1;
end facIndirect;

model FunctionIndirectRecursion
  constant Integer x = 5;
  Integer y1;
equation
  y1 = facIndirect(x);
end FunctionIndirectRecursion;
