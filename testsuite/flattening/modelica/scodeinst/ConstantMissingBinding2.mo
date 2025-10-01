// name: ConstantMissingBinding2
// keywords:
// status: incorrect
//

package P
  constant Real x;
end P;

model ConstantMissingBinding2
  Real y(start = 1.0);
equation
  y = P.x*der(y);
end ConstantMissingBinding2;

// Result:
// Error processing file: ConstantMissingBinding2.mo
// [flattening/modelica/scodeinst/ConstantMissingBinding2.mo:7:3-7:18:writable] Notification: From here:
// [flattening/modelica/scodeinst/ConstantMissingBinding2.mo:13:3-13:17:writable] Error: Constant P.x is used without having been given a value.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
