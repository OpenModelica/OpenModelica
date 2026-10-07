// name:     ConstantRedeclareModifier
// keywords: redeclare, modification, constant
// status:   incorrect
//
// Checks that it's not allowed to redeclare a component declared as constant.
//

model m
  replaceable constant Real x;
end m;

model ConstantRedeclareModifier
  extends m(replaceable Real x = 2.0);
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ConstantRedeclareModifier;

// Result:
// Error processing file: ConstantRedeclareModifier.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/redeclare/ConstantRedeclareModifier.mo:13:3-13:38:writable] Notification: From here:
// [flattening/modelica/redeclare/ConstantRedeclareModifier.mo:9:3-9:30:writable] Error: Redeclaration of constant component x is not allowed.
// Error: Error occurred while flattening model ConstantRedeclareModifier
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
