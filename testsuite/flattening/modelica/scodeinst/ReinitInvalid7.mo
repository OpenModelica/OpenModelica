// name: ReinitInvalid7
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ReinitInvalid7
  Real x;
algorithm
  when time > 0 then
    reinit(x, 2.0);
  end when;
end ReinitInvalid7;

// Result:
// Error processing file: ReinitInvalid7.mo
// [flattening/modelica/scodeinst/ReinitInvalid7.mo:11:5-11:19:writable] Error: Operator reinit may not be used in an algorithm section (use flag --allowNonStandardModelica=reinitInAlgorithms to ignore).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
