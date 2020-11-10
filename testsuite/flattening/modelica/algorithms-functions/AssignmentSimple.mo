// name: AssignmentSimple
// keywords: assignment
// status: correct
// cflags: -d=-newInst
//
// Tests simple assignment
//

model AssignmentSimple
  Real x;
algorithm
  x := 2;
end AssignmentSimple;

// Result:
// class AssignmentSimple
//   Real x;
// algorithm
//   x := 2.0;
// end AssignmentSimple;
// endResult
