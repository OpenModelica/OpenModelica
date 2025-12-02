// name: InstanceRestriction2
// keywords:
// status: incorrect
//

function InstanceRestriction2
  input Real x;
  output Real y;
end InstanceRestriction2;

// Result:
// Error processing file: InstanceRestriction2.mo
// [flattening/modelica/scodeinst/InstanceRestriction2.mo:6:1-9:25:writable] Error: Cannot instantiate InstanceRestriction2 due to class specialization function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
