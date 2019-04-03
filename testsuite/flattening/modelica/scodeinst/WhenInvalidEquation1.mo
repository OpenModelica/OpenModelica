// name: WhenInvalidEquation1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenInvalidEquation1
  Real x, y;
equation
  when time > 0 then
    x + y = 0;
    x - y = 0;
  end when;
end WhenInvalidEquation1;

// Result:
// Error processing file: WhenInvalidEquation1.mo
// [flattening/modelica/scodeinst/WhenInvalidEquation1.mo:11:5-11:14:writable] Error: Invalid left-hand side of when-equation: x + y.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
