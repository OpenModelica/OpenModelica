// name:     Faculty1
// keywords: algorithm,scoping
// status:   correct
//
// Example for a recursive function. The function 'Faculty' must be
// known during its definition in order to be called from itself.

function Faculty1
  input Integer x;
  output Integer y;
algorithm
  y := if x > 0 then x*Faculty1(x-1) else 1;
end Faculty1;


model Test
  Real x=Faculty1(integer(2*time));
end Test;

// Result:
// function Faculty1
//   input Integer x;
//   output Integer y;
// algorithm
//   y := if x > 0 then x * Faculty1(-1 + x) else 1;
// end Faculty1;
//
// class Test
//   Real x = /*Real*/(Faculty1(integer(2.0 * time)));
// end Test;
// endResult
