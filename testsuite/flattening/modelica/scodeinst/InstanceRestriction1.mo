// name: InstanceRestriction1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

package InstanceRestriction1
  Real x;
end InstanceRestriction1;

// Result:
// Error processing file: InstanceRestriction1.mo
// [flattening/modelica/scodeinst/InstanceRestriction1.mo:7:1-9:25:writable] Error: Cannot instantiate InstanceRestriction1 due to class specialization package.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
