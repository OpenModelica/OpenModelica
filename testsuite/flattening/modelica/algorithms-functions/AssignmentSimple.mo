// name: AssignmentSimple
// keywords: assignment
// status: correct
//
// Tests simple assignment
//

model AssignmentSimple
  Real x;
algorithm
  x := 2;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end AssignmentSimple;

// Result:
// class AssignmentSimple
//   Real x;
// algorithm
//   x := 2.0;
// end AssignmentSimple;
// endResult
