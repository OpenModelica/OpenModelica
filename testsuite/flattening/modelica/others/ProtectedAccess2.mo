// name: ProtectedAccess2
// keywords: protected, access
// status: incorrect
//
// Tests access to protected elements of another class
// THIS TEST SHOULD FAIL!
//

model TestModel
protected
  Integer x = 2;
end TestModel;

model ProtectedAccess2
  TestModel tm;
equation
  tm.x = 3;
end ProtectedAccess2;

// Result:
// Error processing file: ProtectedAccess2.mo
// [flattening/modelica/others/ProtectedAccess2.mo:11:3-11:16:writable] Error: Illegal access of protected element x.
// [flattening/modelica/others/ProtectedAccess2.mo:17:3-17:11:writable] Error: Variable tm.x not found in scope ProtectedAccess2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
