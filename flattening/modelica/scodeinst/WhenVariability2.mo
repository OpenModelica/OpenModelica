// name: WhenVariablity2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenVariability2
  Real x;
algorithm
  when pre(x) > 1 then
  end when;
end WhenVariability2;

// Result:
// Error processing file: WhenVariability2.mo
// [flattening/modelica/scodeinst/WhenVariability2.mo:10:3-11:11:writable] Error: Argument 1 of pre must be a discrete expression, but x is continuous.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
