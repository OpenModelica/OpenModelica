// name: WhenVariableMismatch1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenVariableMismatch1
  Real x, y;
equation
  when time > 0 then
    x = 0;
  elsewhen time > 1 then
    y = 0;
  end when;
end WhenVariableMismatch1;

// Result:
// Error processing file: WhenVariableMismatch1.mo
// [flattening/modelica/scodeinst/WhenVariableMismatch1.mo:10:3-14:11:writable] Error: The same variables must be solved in elsewhen clause as in the when clause.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
