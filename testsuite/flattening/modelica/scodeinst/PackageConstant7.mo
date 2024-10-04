// name: PackageConstant7
// keywords:
// status: incorrect
//

model PackageConstant7
  record R
    Real x;
  end R;

  Real x = R.x;
end PackageConstant7;

// Result:
// Error processing file: PackageConstant7.mo
// [flattening/modelica/scodeinst/PackageConstant7.mo:8:5-8:11:writable] Notification: From here:
// [flattening/modelica/scodeinst/PackageConstant7.mo:11:3-11:15:writable] Error: Class R does not satisfy the requirements for a package. Lookup is therefore restricted to encapsulated elements, but x is not encapsulated.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
