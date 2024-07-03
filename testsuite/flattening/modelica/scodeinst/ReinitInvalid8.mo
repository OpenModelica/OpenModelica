// name: ReinitInvalid8
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ReinitInvalid8
  Real x;
equation
  for i in 1.0:2.0 loop
    when time > 0 then
      reinit(i, 1.0);
    end when;
  end for;
end ReinitInvalid8;

// Result:
// Error processing file: ReinitInvalid8.mo
// [flattening/modelica/scodeinst/ReinitInvalid8.mo:12:7-12:21:writable] Error: Assignment to iterator 'i'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
