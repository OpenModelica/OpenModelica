// name: When7
// keywords:
// status: incorrect
//
//

model When7
  Real x;
equation
  when time > 0 then
    x = 1;
  elsewhen time > 1 then
    reinit(x, 2);
  end when;
end When7;

// Result:
// Error processing file: When7.mo
// [flattening/modelica/scodeinst/When7.mo:10:3-14:11:writable] Error: The same variables must be solved in elsewhen clause as in the when clause.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
