// name: PackageConstant7
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model PackageConstant7
  record R
    Real x;
  end R;

  Real x = R.x;
end PackageConstant7;

// Result:
// Error processing file: PackageConstant7.mo
// [flattening/modelica/scodeinst/PackageConstant7.mo:9:5-9:11:writable] Notification: From here:
// [flattening/modelica/scodeinst/PackageConstant7.mo:12:3-12:15:writable] Error: Class R does not satisfy the requirements for a package. Lookup is therefore restricted to encapsulated elements, but x is not encapsulated.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
