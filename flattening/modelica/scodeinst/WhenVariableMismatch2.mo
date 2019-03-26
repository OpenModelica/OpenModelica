// name: WhenVariableMismatch2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model WhenVariableMismatch2
  Real x[2];
equation
  when time > 0 then
    x[1] = 0;
  elsewhen time > 1 then
    x[2] = 0;
  end when;
end WhenVariableMismatch2;

// Result:
// Error processing file: WhenVariableMismatch2.mo
// [flattening/modelica/scodeinst/WhenVariableMismatch2.mo:10:3-14:11:writable] Error: The same variables must be solved in elsewhen clause as in the when clause.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
