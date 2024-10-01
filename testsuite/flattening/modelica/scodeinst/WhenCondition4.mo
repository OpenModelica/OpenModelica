// name: WhenCondition4
// keywords:
// status: incorrect
//
//

model WhenCondition4
  Real x;
equation
  when noEvent(time > 0) then
    x = 1.0;
  end when;
end WhenCondition4;

// Result:
// Error processing file: WhenCondition4.mo
// [flattening/modelica/scodeinst/WhenCondition4.mo:10:3-12:11:writable] Error: When-condition 'noEvent(time > 0)' is not a discrete-time expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
