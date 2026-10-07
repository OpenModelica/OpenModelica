// name: AssignmentToInput
// keywords: assignment input bug1819
// status: correct
//
// Tests assignment to input in model scope.
//

model M
  input Real x;
end M;

model AssignmentToInput
  M m;
  input Real x;
algorithm
  x := 2;
  m.x := x;
end AssignmentToInput;

// Result:
// class AssignmentToInput
//   Real m.x;
//   input Real x;
// algorithm
//   x := 2.0;
//   m.x := x;
// end AssignmentToInput;
// endResult
