// name: InstanceRestriction2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

function InstanceRestriction2
  input Real x;
  output Real y;
end InstanceRestriction2;

// Result:
// Error processing file: InstanceRestriction2.mo
// [flattening/modelica/scodeinst/InstanceRestriction2.mo:7:1-10:25:writable] Error: Cannot instantiate InstanceRestriction2 due to class specialization pure function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
