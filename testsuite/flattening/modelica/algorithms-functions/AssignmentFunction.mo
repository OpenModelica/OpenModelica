// name: AssignmentFunction
// keywords: assignment, function
// status: correct
//
// Tests assignment to a simple function call
//

function F
  input Real inReal;
  output Real outReal;
algorithm
  outReal := inReal + 2;
end F;

model AssignmentFunction
  Real x;
  Real y;
algorithm
  x := 2;
  y := F(x);
end AssignmentFunction;

// Result:
// function F
//   input Real inReal;
//   output Real outReal;
// algorithm
//   outReal := 2.0 + inReal;
// end F;
//
// class AssignmentFunction
//   Real x;
//   Real y;
// algorithm
//   x := 2.0;
//   y := F(x);
// end AssignmentFunction;
// endResult
