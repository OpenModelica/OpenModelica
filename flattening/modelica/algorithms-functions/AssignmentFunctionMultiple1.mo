// name: AssignmentFunctionMultiple1
// keywords: assignment, function
// status: correct
//
// Tests assignment to a function call with multiple outputs
//

function F
  input Real inReal;
  output Real outReal1;
  output Real outReal2;
algorithm
  outReal1 := inReal + 2;
  outReal2 := inReal + 4;
end F;

model AssignmentFunctionMultiple1
  Real x;
  Real y;
  Real z;
algorithm
  x := 2;
  (y, z) := F(x);
end AssignmentFunctionMultiple1;

// Result:
// function F
//   input Real inReal;
//   output Real outReal1;
//   output Real outReal2;
// algorithm
//   outReal1 := 2.0 + inReal;
//   outReal2 := 4.0 + inReal;
// end F;
//
// class AssignmentFunctionMultiple1
//   Real x;
//   Real y;
//   Real z;
// algorithm
//   x := 2.0;
//   (y, z) := F(x);
// end AssignmentFunctionMultiple1;
// endResult
