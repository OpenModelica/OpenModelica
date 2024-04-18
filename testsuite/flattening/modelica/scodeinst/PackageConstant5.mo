// name: PackageConstant5
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model PackageConstant5
  Real x;

  model A
    Real y = x;
  end A;

  A a;
end PackageConstant5;

// Result:
// Error processing file: PackageConstant5.mo
// [flattening/modelica/scodeinst/PackageConstant5.mo:8:3-8:9:writable] Notification: From here:
// [flattening/modelica/scodeinst/PackageConstant5.mo:11:5-11:15:writable] Error: Component 'x' was found in an enclosing scope but is not a constant.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
