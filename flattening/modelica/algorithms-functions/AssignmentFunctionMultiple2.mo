// name: AssignmentFunctionMultiple2
// keywords: assignment, function
// status: correct
//
// Tests assignment to a function call with multiple outputs, omitting one of the outputs
//

function F
  input Real inReal;
  output Real outReal1;
  output Real outReal2;
algorithm
  outReal1 := inReal + 2;
  outReal2 := inReal + 4;
end F;

model AssignmentFunctionMultiple2
  Real x;
  Real y;
algorithm
  x := 2;
  (y,) := F(x);
end AssignmentFunctionMultiple2;
