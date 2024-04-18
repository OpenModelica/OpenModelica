// name: PackageBinding1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

package A
  constant Real x = 1.0;
end A;

model PackageBinding1
  A a1;
  A a2 = a1;
end PackageBinding1;

// Result:
// Error processing file: PackageBinding1.mo
// [flattening/modelica/scodeinst/PackageBinding1.mo:13:3-13:12:writable] Error: Component 'a2' may not have a binding equation due to class specialization 'package'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
