// name: ProtectedAccess
// keywords: protected, access
// status: incorrect
//
// Tests that it is an error to modify protected elements of another class
//

model TestModel
protected
  Integer x = 2;
end TestModel;

model ProtectedAccess
  TestModel tm(x = 3);
end ProtectedAccess;


// Result:
// Error processing file: ProtectedAccess.mo
// [flattening/modelica/others/ProtectedAccess.mo:14:16-14:21:writable] Notification: From here:
// [flattening/modelica/others/ProtectedAccess.mo:10:3-10:16:writable] Error: Protected element 'x' may not be modified, got 'x = 3'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
