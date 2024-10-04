// name: WhenCondition5
// keywords:
// status: incorrect
//
//

model WhenCondition5
  Real x;
algorithm
  when noEvent(time > 0) then
    x := 1.0;
  end when;
end WhenCondition5;

// Result:
// Error processing file: WhenCondition5.mo
// [flattening/modelica/scodeinst/WhenCondition5.mo:10:3-12:11:writable] Error: When-condition 'noEvent(time > 0)' is not a discrete-time expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
