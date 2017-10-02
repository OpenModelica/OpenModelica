// name: StatementInvalidType1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model StatementInvalidType1
  Real x;
  String s;
algorithm
  x := s;
end StatementInvalidType1;

// Result:
// Error processing file: StatementInvalidType1.mo
// [flattening/modelica/scodeinst/StatementInvalidType1.mo:11:3-11:9:writable] Error: Type mismatch in assignment in x := s of Real := String
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
