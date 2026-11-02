// name: CyclicBindingConst
// keywords: cyclic
// status: incorrect
//
// Tests cyclic binding of constants
//

model CyclicBindingConst
  constant Real p = 2*q;
  constant Real q = 2*p;
end CyclicBindingConst;

// Result:
// Error processing file: CyclicBindingConst.mo
// [flattening/modelica/others/CyclicBindingConst.mo:10:3-10:24:writable] Notification: From here:
// [flattening/modelica/others/CyclicBindingConst.mo:9:3-9:24:writable] Notification: From here:
// [flattening/modelica/others/CyclicBindingConst.mo:10:3-10:24:writable] Error: Variable 'q' has a cyclic dependency and has variability constant.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
