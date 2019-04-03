// name:     TupleAssignmentMismatch1
// keywords: algorithm, tuple, assignment, #3421
// status:   incorrect
//
// Checks that too many tuple elements generate an error when assigning a
// function call to a tuple.
//

model TupleAssignmentMismatch1
  function f
    output Real r1;
    output Real r2;
  algorithm
    r1 := 1.0;
    r2 := 2.0;
  end f;

  Real x, y, z;
algorithm
  (x, y, z) := f();
end TupleAssignmentMismatch1;


// Result:
// Error processing file: TupleAssignmentMismatch1.mo
// [flattening/modelica/algorithms-functions/TupleAssignmentMismatch1.mo:20:3-20:19:writable] Error: Type mismatch in assignment in (x, y, z) := f() of (Real, Real, Real) := (Real, Real)
// Error: Error occurred while flattening model TupleAssignmentMismatch1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
